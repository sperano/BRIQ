//
//  StoreDeduplicator.swift
//  BRIQ
//

import CoreData
import Foundation
import OSLog

/// Lightweight migration to a model with uniqueness constraints fails when
/// the store already holds duplicates, and a failed load destroys the store
/// (user data included). Before such a migration, this opens the store with
/// the model it was written with and resolves the duplicates there.
nonisolated enum StoreDeduplicator {
    /// First suffix given to a renamed duplicate parts list: "Name (2)".
    static let firstRenameSuffix = 2

    private static let userDataFlagKeys = ["owned", "favorite", "ownsInstructions"]
    private static let instructionsQualityKey = "instructionsQuality"

    /// Resolves duplicates in the SQLite store at `storeURL` when it is not
    /// yet compatible with `currentModel` and one of `sourceModels` matches
    /// it. Returns the number of objects merged, deleted or renamed.
    @discardableResult
    static func prepareForMigration(
        storeAt storeURL: URL,
        options: [String: Any]?,
        to currentModel: NSManagedObjectModel,
        sourceModels: @autoclosure () -> [NSManagedObjectModel]
    ) throws -> Int {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return 0 }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            type: .sqlite, at: storeURL, options: options
        )
        guard !currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
            return 0
        }
        guard let source = sourceModels().first(where: {
            $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }) else {
            Logger.database.notice("No bundled model matches the store; skipping duplicate check")
            return 0
        }
        return try resolveDuplicates(storeAt: storeURL, options: options, model: genericCopy(of: source))
    }

    /// Every compiled version inside the bundle's `<name>.momd`, with
    /// generic entity classes (see `makeGeneric`).
    static func bundledModelVersions(named name: String, in bundle: Bundle) -> [NSManagedObjectModel] {
        let urls = bundle.urls(forResourcesWithExtension: "mom", subdirectory: "\(name).momd") ?? []
        return urls.compactMap(NSManagedObjectModel.init(contentsOf:)).map { model in
            makeGeneric(model)
            return model
        }
    }

    /// Rows are handled as plain NSManagedObjects so a second model does not
    /// compete with the app's for the generated subclasses.
    private static func makeGeneric(_ model: NSManagedObjectModel) {
        for entity in model.entities {
            entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
    }

    private static func genericCopy(of model: NSManagedObjectModel) -> NSManagedObjectModel {
        guard let copy = model.copy() as? NSManagedObjectModel else { return model }
        makeGeneric(copy)
        return copy
    }

    private static func resolveDuplicates(
        storeAt storeURL: URL,
        options: [String: Any]?,
        model: NSManagedObjectModel
    ) throws -> Int {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(type: .sqlite, at: storeURL, options: options)
        defer { try? coordinator.remove(store) }

        let context = NSManagedObjectContext(.privateQueue)
        context.persistentStoreCoordinator = coordinator
        return try context.performAndWait {
            let resolved = try removeDuplicates(in: context)
            if context.hasChanges {
                try context.save()
                Logger.database.notice("Resolved \(resolved) duplicate rows before migration")
            }
            return resolved
        }
    }

    /// Order matters: user data is merged before its sets are deleted, and
    /// duplicate sets (with their part lines) go before duplicate parts.
    static func removeDuplicates(in context: NSManagedObjectContext) throws -> Int {
        var resolved = 0
        resolved += try forEachDuplicateGroup(of: "SetUserData", by: "number", in: context, mergeUserData)
        resolved += try forEachDuplicateGroup(of: "Set", by: "number", in: context, keepSetWithUserData)
        resolved += try forEachDuplicateGroup(of: "Part", by: "number", in: context) { group, context in
            mergeReferencedObjects(group, relationships: ["setParts", "partsListParts"], in: context)
        }
        resolved += try forEachDuplicateGroup(of: "Minifig", by: "number", in: context) { group, context in
            mergeReferencedObjects(group, relationships: ["setMinifigs"], in: context)
        }
        resolved += try renameDuplicatePartsLists(in: context)
        return resolved
    }

    /// Calls `resolve` on each group of objects sharing `key` and returns how
    /// many objects were not the group's first.
    private static func forEachDuplicateGroup(
        of entityName: String,
        by key: String,
        in context: NSManagedObjectContext,
        _ resolve: ([NSManagedObject], NSManagedObjectContext) -> Void
    ) throws -> Int {
        let groups = try duplicateGroups(of: entityName, by: key, in: context)
        for group in groups {
            resolve(group, context)
        }
        context.processPendingChanges()
        return groups.reduce(0) { $0 + $1.count - 1 }
    }

    private static func duplicateGroups(
        of entityName: String,
        by key: String,
        in context: NSManagedObjectContext
    ) throws -> [[NSManagedObject]] {
        let model = context.persistentStoreCoordinator?.managedObjectModel
        guard model?.entitiesByName[entityName]?.attributesByName[key] != nil else { return [] }

        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(key: key, ascending: true)]
        let objects = try context.fetch(request)
        var groups: [[NSManagedObject]] = []
        for object in objects {
            let value = object.value(forKey: key) as? String
            if let last = groups.last?.last, last.value(forKey: key) as? String == value {
                groups[groups.count - 1].append(object)
            } else {
                groups.append([object])
            }
        }
        return groups.filter { $0.count > 1 }
    }

    /// Keeps the row linked to a set and folds the others into it: a flag set
    /// in any copy stays set, the highest rating wins.
    private static func mergeUserData(_ group: [NSManagedObject], in context: NSManagedObjectContext) {
        let survivor = group.first { $0.value(forKey: "set") != nil } ?? group[0]
        for duplicate in group where duplicate != survivor {
            for key in userDataFlagKeys where duplicate.value(forKey: key) as? Bool == true {
                survivor.setValue(true, forKey: key)
            }
            let quality = duplicate.value(forKey: instructionsQualityKey) as? Int32 ?? 0
            if quality > survivor.value(forKey: instructionsQualityKey) as? Int32 ?? 0 {
                survivor.setValue(quality, forKey: instructionsQualityKey)
            }
            context.delete(duplicate)
        }
    }

    /// Duplicate sets come from a repeated bundled import and carry the same
    /// part and minifig lines; keep the one holding user data.
    private static func keepSetWithUserData(_ group: [NSManagedObject], in context: NSManagedObjectContext) {
        let survivor = group.first { $0.value(forKey: "userData") != nil } ?? group[0]
        for duplicate in group where duplicate != survivor {
            context.delete(duplicate)
        }
    }

    /// Moves every line pointing at a duplicate onto the first object, then
    /// deletes the duplicates (their cascade rules would delete the lines).
    private static func mergeReferencedObjects(
        _ group: [NSManagedObject],
        relationships: [String],
        in context: NSManagedObjectContext
    ) {
        let survivor = group[0]
        for duplicate in group.dropFirst() {
            for relationship in relationships {
                let lines = duplicate.mutableSetValue(forKey: relationship).allObjects
                survivor.mutableSetValue(forKey: relationship).addObjects(from: lines)
            }
            context.delete(duplicate)
        }
    }

    /// Parts lists are user content: rename duplicates instead of merging.
    private static func renameDuplicatePartsLists(in context: NSManagedObjectContext) throws -> Int {
        let groups = try duplicateGroups(of: "PartsList", by: "name", in: context)
        guard !groups.isEmpty else { return 0 }

        let request = NSFetchRequest<NSManagedObject>(entityName: "PartsList")
        var takenNames = Swift.Set(try context.fetch(request).compactMap { $0.value(forKey: "name") as? String })
        var renamed = 0
        for group in groups {
            for list in group.dropFirst() {
                let name = list.value(forKey: "name") as? String ?? ""
                var suffix = firstRenameSuffix
                while takenNames.contains("\(name) (\(suffix))") {
                    suffix += 1
                }
                let newName = "\(name) (\(suffix))"
                list.setValue(newName, forKey: "name")
                takenNames.insert(newName)
                renamed += 1
            }
        }
        return renamed
    }
}
