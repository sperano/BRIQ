//
//  CoreDataStack.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import Foundation
import CoreData
import Combine
import OSLog

/// Not actor-isolated: the contexts it vends enforce their own queues
/// (view context on main, background contexts on private queues). The app
/// creates one instance and injects it via the environment; `shared` exists
/// for previews only.
final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    /// Non-nil when the store failed to load and automatic recovery
    /// (destroying and recreating it) also failed.
    let loadError: Error?

    /// Most recent user-visible save failure; ContentView presents it as an alert.
    @MainActor @Published var lastSaveError: String?

    /// `inMemory` writes the store to /dev/null for tests and previews.
    init(inMemory: Bool = false) {
        let container = Self.makeContainer()
        var failure: Error?
        do {
            if inMemory {
                container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
                if let error = Self.attemptLoad(container) {
                    throw error
                }
            } else {
                try Self.loadStoreRecoveringFromCorruption(into: container)
            }
        } catch {
            failure = error
        }
        persistentContainer = container
        loadError = failure

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    @MainActor
    func saveContext() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            Logger.database.error("Core Data save error: \(error)")
            throw CoreDataError.saveFailed(error)
        }
    }

    /// Saves the view context; on failure rolls back the pending changes and
    /// publishes the error so the UI can present it.
    @MainActor
    @discardableResult
    func saveViewContext() -> Bool {
        do {
            try saveContext()
            return true
        } catch {
            viewContext.rollback()
            lastSaveError = error.localizedDescription
            return false
        }
    }

    /// Destroys the persistent store (including WAL/SHM sidecars) and re-adds
    /// it using the original store descriptions, preserving migration and
    /// history-tracking options.
    @MainActor
    func resetStore() throws {
        try Self.destroyStore(of: persistentContainer)
        if let error = Self.attemptLoad(persistentContainer) {
            throw error
        }
        viewContext.reset()
    }

    private static func makeContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "BRIQ")

        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        return container
    }

    private static func loadStoreRecoveringFromCorruption(into container: NSPersistentContainer) throws {
        guard let error = attemptLoad(container) else { return }

        Logger.database.error("Core Data store failed to load: \(error); destroying and recreating it")
        try destroyStore(of: container)
        // The recreated store is empty; force the bundled data to re-import.
        UserDefaults.standard.removeObject(forKey: DatabaseInitializer.hasInitializedKey)

        if let retryError = attemptLoad(container) {
            throw retryError
        }
    }

    /// `loadPersistentStores` calls its handler synchronously for local stores,
    /// so the captured error is complete when this returns.
    private static func attemptLoad(_ container: NSPersistentContainer) -> Error? {
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        return loadError
    }

    private static func destroyStore(of container: NSPersistentContainer) throws {
        guard let description = container.persistentStoreDescriptions.first,
              let storeURL = description.url else {
            throw CoreDataError.storeNotFound
        }

        let coordinator = container.persistentStoreCoordinator
        if let store = coordinator.persistentStore(for: storeURL) {
            try coordinator.remove(store)
        }
        try coordinator.destroyPersistentStore(at: storeURL, type: .sqlite, options: description.options)
    }
}

// MARK: - Errors
enum CoreDataError: LocalizedError {
    case storeNotFound
    case saveFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .storeNotFound:
            return "Core Data store not found"
        case .saveFailed(let error):
            return "Core Data save failed: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Core Data fetch failed: \(error.localizedDescription)"
        }
    }
}
