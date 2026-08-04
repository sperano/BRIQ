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

    @Published private(set) var state: State

    private let coreDataStack: CoreDataStack
    private let defaults: UserDefaults

    nonisolated init(coreDataStack: CoreDataStack, defaults: UserDefaults = .standard) {
        self.coreDataStack = coreDataStack
        self.defaults = defaults
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
    /// preserving user data across the reset via export/import.
    func reinitialize(preserveUserData: Bool) async {
        guard state == .ready else { return }

        let exportedUserData = preserveUserData ? exportUserData(context: coreDataStack.viewContext) : nil

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

        if state == .ready, let exportedUserData {
            importUserData(context: coreDataStack.viewContext, jsonString: exportedUserData)
            Logger.database.info("Database reinitialization completed with user data restored")
        }
    }

    private func load() async {
        state = .loading(setsImported: 0, fraction: 0)

        do {
            try await resetLeftoverPartialImport()
            let context = coreDataStack.newBackgroundContext()
            try await BundledData.loadAll(into: context) { [weak self] setsImported, fraction in
                self?.state = .loading(setsImported: setsImported, fraction: fraction)
            }
            defaults.set(true, forKey: Self.hasInitializedKey)
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
