//
//  CoreDataStack.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import Foundation
import CoreData
import CloudKit
import Combine

@MainActor
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BRIQ")

        // Get the default store description
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Configure CloudKit container for syncable entities (Foo)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Set CloudKit container identifier - replace with your actual container ID
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.sperano.BRIQ")

        // Configure for better performance and migration
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // In production, handle this error appropriately
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func saveContext() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
                // In production, handle this error appropriately
                fatalError("Unresolved Core Data save error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveBackgroundContext(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        try await context.perform {
            try context.save()
        }
    }

    func resetStore() throws {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.storeNotFound
        }

        let coordinator = persistentContainer.persistentStoreCoordinator

        // Remove the persistent store
        if let store = coordinator.persistentStores.first {
            try coordinator.remove(store)
        }

        // Delete the store file
        try FileManager.default.removeItem(at: storeURL)

        // Recreate the store
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true

        try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )
    }
}

// MARK - Errors
enum CoreDataError: Error {
    case storeNotFound
    case saveFailed(Error)
    case fetchFailed(Error)

    var localizedDescription: String {
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

// MARK: - Batch Operations
extension CoreDataStack {

    func performBatchInsert(
        entityName: String,
        objects: [[String: Any]],
        batchSize: Int = 1000
    ) async throws {
        let context = newBackgroundContext()

        try await context.perform {
            let batches = objects.chunked(into: batchSize)

            for batch in batches {
                let batchInsert = NSBatchInsertRequest(entityName: entityName, objects: batch)
                batchInsert.resultType = .statusOnly

                let result = try context.execute(batchInsert) as? NSBatchInsertResult

                if let success = result?.result as? Bool, !success {
                    throw CoreDataError.saveFailed(NSError(domain: "BatchInsert", code: 1, userInfo: [NSLocalizedDescriptionKey: "Batch insert failed"]))
                }
            }

            try context.save()
        }
    }

}

// MARK: - Helper Extensions
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
