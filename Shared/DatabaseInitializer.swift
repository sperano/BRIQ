//
//  DatabaseInitializer.swift
//  BRIQ
//

import Combine
import CoreData
import Foundation
import OSLog

/// Owns the lifecycle of the bundled-database import: first-launch load,
/// failure recovery, and full reinitialization (macOS "Database > Re-Initialize").
@MainActor
final class DatabaseInitializer: ObservableObject {
    enum State: Equatable {
        case idle
        case loading(setsImported: Int, fraction: Double)
        case ready
        case failed(message: String)
    }

    static let hasInitializedKey = "hasInitialized"
    /// User data exported by `reinitialize`, kept until the reloaded store
    /// has it back, so a failed or cancelled reload does not lose it.
    static let pendingUserDataKey = "pendingUserDataRestore"

    @Published private(set) var state: State

    private let coreDataStack: CoreDataStack
    private let defaults: UserDefaults
    /// The archive to import; nil means the one bundled with the app.
    private let archiveURL: URL?

    nonisolated init(coreDataStack: CoreDataStack, defaults: UserDefaults = .standard, archiveURL: URL? = nil) {
        self.coreDataStack = coreDataStack
        self.defaults = defaults
        self.archiveURL = archiveURL
        _state = Published(initialValue: defaults.bool(forKey: Self.hasInitializedKey) ? .ready : .idle)
    }

    /// Runs the first-launch import unless the database is already loaded.
    /// Safe to call repeatedly; also used to retry after a failure.
    func initializeIfNeeded() async {
        if let loadError = coreDataStack.loadError {
            state = .failed(message: loadError.localizedDescription)
            return
        }

        switch state {
        case .loading:
            return
        case .ready:
            // Already initialized on a previous launch; the store may still
            // predate newer derived attributes.
            await backfillSortKeysIfNeeded()
            return
        case .idle, .failed:
            break
        }

        if defaults.bool(forKey: Self.hasInitializedKey) {
            await backfillSortKeysIfNeeded()
            state = .ready
            return
        }

        await load()
    }

    private var didCheckSortKeyBackfill = false

    /// Stores imported before `Set.sortKey` existed hold 0 for every set after
    /// the lightweight migration; compute the keys once. Failure is logged and
    /// tolerated — sorting degrades but the app works.
    private func backfillSortKeysIfNeeded() async {
        guard !didCheckSortKeyBackfill else { return }
        didCheckSortKeyBackfill = true
        let context = coreDataStack.newBackgroundContext()
        do {
            try await context.perform {
                let total = try context.count(for: Set.fetchRequest())
                let zeroRequest = Set.fetchRequest()
                zeroRequest.predicate = NSPredicate(format: "sortKey == 0")
                let zeroed = try context.count(for: zeroRequest)
                guard total > 0, zeroed == total else { return }

                Logger.database.info("Backfilling sortKey for \(total) sets")
                for set in try context.fetch(Set.fetchRequest()) {
                    set.sortKey = Set.sortKey(forNumber: set.number)
                }
                try context.save()
                context.reset()
            }
        } catch {
            Logger.database.error("sortKey backfill failed: \(error)")
        }
    }

    /// Wipes the store and re-imports the bundled database, optionally
    /// preserving user data across the reset via export/import. When the
    /// user data cannot be exported in a form the import accepts, nothing is
    /// wiped and the reason is published through `lastSaveError`.
    func reinitialize(preserveUserData: Bool) async {
        guard state == .ready else { return }

        if preserveUserData {
            guard let exported = exportRestorableUserData() else { return }
            defaults.set(exported, forKey: Self.pendingUserDataKey)
        } else {
            defaults.removeObject(forKey: Self.pendingUserDataKey)
        }

        defaults.removeObject(forKey: Self.hasInitializedKey)
        state = .loading(setsImported: 0, fraction: 0)

        do {
            try coreDataStack.resetStore()
        } catch {
            Logger.database.error("Failed to reset store for reinitialization: \(error)")
            state = .failed(message: error.localizedDescription)
            return
        }

        await load()
    }

    private func exportRestorableUserData() -> String? {
        guard let exported = exportUserData(context: coreDataStack.viewContext) else {
            coreDataStack.lastSaveError = "The database was not re-initialized: your user data could not be exported."
            return nil
        }
        do {
            _ = try decodeUserDataExport(exported)
            return exported
        } catch {
            Logger.database.error("Exported user data would not import again: \(error)")
            coreDataStack.lastSaveError = "The database was not re-initialized: your user data could not be "
                + "restored afterwards. \(error.localizedDescription)"
            return nil
        }
    }

    /// Runs after a successful load. A failed restore keeps the payload: only
    /// a later reset (followed by a load) uses it, and `reinitialize`
    /// replaces it first.
    private func restorePendingUserData() {
        guard let pending = defaults.string(forKey: Self.pendingUserDataKey) else { return }
        do {
            try importUserData(context: coreDataStack.viewContext, jsonString: pending)
            defaults.removeObject(forKey: Self.pendingUserDataKey)
            Logger.database.info("User data restored after reinitialization")
        } catch {
            // The reloaded database itself is fine, so stay `.ready`.
            Logger.database.error("Database reinitialized but restoring user data failed: \(error)")
            coreDataStack.lastSaveError = "Your user data could not be restored: \(error.localizedDescription)"
        }
    }

    private func load() async {
        state = .loading(setsImported: 0, fraction: 0)

        do {
            try await resetLeftoverPartialImport()
            let context = coreDataStack.newBackgroundContext()
            let url = try archiveURL ?? BundledData.bundledArchiveURL()
            try await BundledData.loadAll(from: url, into: context) { [weak self] setsImported, fraction in
                self?.state = .loading(setsImported: setsImported, fraction: fraction)
            }
            defaults.set(true, forKey: Self.hasInitializedKey)
            restorePendingUserData()
            state = .ready
        } catch is CancellationError {
            Logger.database.notice("Database initialization cancelled; will retry on next launch")
            state = .idle
        } catch {
            Logger.database.error("Database initialization failed: \(error)")
            state = .failed(message: error.localizedDescription)
        }
    }

    /// A crashed or failed import leaves saved batches behind with
    /// `hasInitialized` still false; importing on top of them would duplicate
    /// every entity. Reset the store to start from a clean slate.
    private func resetLeftoverPartialImport() async throws {
        let context = coreDataStack.newBackgroundContext()
        let leftoverSets = try await context.perform {
            try context.count(for: Set.fetchRequest())
        }
        guard leftoverSets > 0 else { return }

        Logger.database.warning("Found \(leftoverSets) sets from an incomplete import; resetting store")
        try coreDataStack.resetStore()
    }
}
