//
//  DatabaseInitializer.swift
//  BRIQ
//

import BRIQKit
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
            await finishEarlierLoad()
            return
        case .idle, .failed:
            break
        }

        if defaults.bool(forKey: Self.hasInitializedKey) {
            await finishEarlierLoad()
            state = .ready
            return
        }

        await load()
    }

    private var didFinishEarlierLoad = false

    /// Runs once per launch on a store loaded by an earlier launch: it may
    /// predate newer derived attributes, and a restore that failed, or that a
    /// quit interrupted before it saved, is retried.
    private func finishEarlierLoad() async {
        guard !didFinishEarlierLoad else { return }
        didFinishEarlierLoad = true
        await backfillSortKeysIfNeeded()
        restorePendingUserData()
    }

    /// Stores imported before `Set.sortKey` existed hold 0 for every set after
    /// the lightweight migration; compute the keys once. Failure is logged and
    /// tolerated — sorting degrades but the app works.
    private func backfillSortKeysIfNeeded() async {
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
                    set.sortKey = SetNumber.sortKey(for: set.number)
                }
                try context.save()
                context.reset()
            }
        } catch {
            Logger.database.error("sortKey backfill failed: \(error)")
        }
    }

    /// Wipes the store and re-imports the bundled database, optionally
    /// preserving user data across the reset via export/import. When an
    /// earlier restore is still pending and fails again, or the user data
    /// cannot be exported in a form the import accepts, nothing is wiped and
    /// the reason is published through `lastSaveError`.
    func reinitialize(preserveUserData: Bool) async {
        guard state == .ready else { return }

        if preserveUserData {
            guard restoreEarlierPendingUserData(), let exported = exportRestorableUserData() else { return }
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
            coreDataStack.lastSaveError = String(
                localized: "The database was not re-initialized: your user data could not be exported."
            )
            return nil
        }
        do {
            _ = try decodeUserDataExport(exported)
            return exported
        } catch {
            Logger.database.error("Exported user data would not import again: \(error)")
            coreDataStack.lastSaveError = String(
                localized: "The database was not re-initialized: your user data could not be restored afterwards. \(error.localizedDescription)",
                comment: "Followed by the reason"
            )
            return nil
        }
    }

    /// A pending payload holds user data the store lacks, so exporting the
    /// store over it would lose that data: restore it first, and keep it
    /// when that fails. Re-initializing without user data discards it.
    private func restoreEarlierPendingUserData() -> Bool {
        do {
            try importPendingUserData()
            return true
        } catch {
            Logger.database.error("Earlier user data restore failed again: \(error)")
            coreDataStack.lastSaveError = String(
                localized: "The database was not re-initialized: the user data kept by the last re-initialization could not be restored. \(error.localizedDescription)",
                comment: "Followed by the reason"
            )
            return false
        }
    }

    /// The payload is removed only once its import saved, so a failed restore
    /// keeps it for the next launch.
    private func importPendingUserData() throws {
        guard let pending = defaults.string(forKey: Self.pendingUserDataKey) else { return }
        try importUserData(context: coreDataStack.viewContext, jsonString: pending)
        defaults.removeObject(forKey: Self.pendingUserDataKey)
        Logger.database.info("User data restored after reinitialization")
    }

    private func restorePendingUserData() {
        do {
            try importPendingUserData()
        } catch {
            // The reloaded database itself is fine, so stay `.ready`.
            Logger.database.error("Database reinitialized but restoring user data failed: \(error)")
            let reason = error.localizedDescription
            coreDataStack.lastSaveError = String(localized: "Your user data could not be restored: \(reason)")
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
            // This store is current; only its restore below is left to do.
            didFinishEarlierLoad = true
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
