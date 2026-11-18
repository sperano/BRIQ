//
//  CoreDataStack.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import Combine
import CoreData
import Foundation
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

    /// Most recent user-visible save or user-data error (export, restore,
    /// aborted re-initialization); ContentView presents it as an alert.
    @MainActor @Published var lastSaveError: String?

    /// `inMemory` writes the store to /dev/null for tests and previews.
    convenience init(inMemory: Bool = false) {
        self.init(storeURL: inMemory ? URL(fileURLWithPath: "/dev/null") : nil)
    }

    /// `storeURL` replaces the default location (tests, previews); such a
    /// store is loaded as is, without the duplicate check or the recovery.
    init(storeURL: URL?) {
        let container = Self.makeContainer()
        var failure: Error?
        do {
            if let storeURL {
                container.persistentStoreDescriptions.first?.url = storeURL
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
        persistentContainer.viewContext
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

    static let modelName = "BRIQ"

    /// Loaded once: instantiating the model repeatedly (e.g. one stack per
    /// test) makes multiple NSEntityDescriptions claim the same
    /// NSManagedObject subclasses.
    static let managedObjectModel: NSManagedObjectModel = {
        let url = Bundle(for: CoreDataStack.self).url(forResource: CoreDataStack.modelName, withExtension: "momd")
        guard let url, let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("BRIQ.momd is missing from the bundle")
        }
        return model
    }()

    private static func makeContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)

        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        return container
    }

    private static func loadStoreRecoveringFromCorruption(into container: NSPersistentContainer) throws {
        resolveDuplicatesBeforeMigration(in: container)
        guard let error = attemptLoad(container) else { return }

        Logger.database.error("Core Data store failed to load: \(error); destroying and recreating it")
        try destroyStore(of: container)
        // The recreated store is empty; force the bundled data to re-import.
        UserDefaults.standard.removeObject(forKey: DatabaseInitializer.hasInitializedKey)

        if let retryError = attemptLoad(container) {
            throw retryError
        }
    }

    /// Migrating a store that holds duplicates to the uniqueness-constrained
    /// model fails, and a failed load recreates the store, losing user data.
    /// A failure here is only logged: the load and its recovery run as before.
    private static func resolveDuplicatesBeforeMigration(in container: NSPersistentContainer) {
        guard let description = container.persistentStoreDescriptions.first,
              let storeURL = description.url else { return }
        do {
            try StoreDeduplicator.prepareForMigration(
                storeAt: storeURL,
                options: description.options,
                to: managedObjectModel,
                sourceModels: StoreDeduplicator.bundledModelVersions(
                    named: modelName, in: Bundle(for: CoreDataStack.self)
                )
            )
        } catch {
            Logger.database.error("Duplicate check before migration failed: \(error)")
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
              let storeURL = description.url
        else {
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
            String(localized: "Core Data store not found")
        case .saveFailed(let error):
            String(localized: "Core Data save failed: \(error.localizedDescription)")
        case .fetchFailed(let error):
            String(localized: "Core Data fetch failed: \(error.localizedDescription)")
        }
    }
}
