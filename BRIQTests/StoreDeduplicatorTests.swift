//
//  StoreDeduplicatorTests.swift
//  BRIQTests
//

import CoreData
import Foundation
import Testing
@testable import BRIQ

/// Builds an on-disk store with the pre-constraint model (version 1), runs
/// the deduplicator, then migrates it to the current model.
@MainActor final class StoreDeduplicatorTests {
    private let directory: URL
    private let storeURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storeURL = directory.appendingPathComponent("BRIQ.sqlite")
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    private var bundledVersions: [NSManagedObjectModel] {
        StoreDeduplicator.bundledModelVersions(named: CoreDataStack.modelName, in: Bundle(for: CoreDataStack.self))
    }

    /// The version-1 model; bundled versions come with plain NSManagedObject
    /// rows, so it does not claim the app's entity classes.
    private func versionOneModel() throws -> NSManagedObjectModel {
        try #require(bundledVersions.first { model in
            model.entities.allSatisfy(\.uniquenessConstraints.isEmpty)
        })
    }

    private func writeStore(model: NSManagedObjectModel, _ populate: (NSManagedObjectContext) -> Void) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)
        let context = NSManagedObjectContext(.mainQueue)
        context.persistentStoreCoordinator = coordinator
        populate(context)
        try context.save()
        try coordinator.remove(store)
    }

    @discardableResult
    private func insert(_ entity: String, _ values: [String: Any],
                        in context: NSManagedObjectContext) -> NSManagedObject
    {
        let object = NSEntityDescription.insertNewObject(forEntityName: entity, into: context)
        object.setValuesForKeys(values)
        return object
    }

    @discardableResult
    private func set(_ number: String, in context: NSManagedObjectContext) -> NSManagedObject {
        insert("Set", ["number": number, "name": "Set \(number)"], in: context)
    }

    /// Opens the store with the current (constrained) model, migrating it.
    private func migratedContainer() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: CoreDataStack.modelName,
            managedObjectModel: CoreDataStack.managedObjectModel
        )
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }

    private func prepare() throws -> Int {
        try StoreDeduplicator.prepareForMigration(
            storeAt: storeURL, options: nil, to: CoreDataStack.managedObjectModel, sourceModels: bundledVersions
        )
    }

    private func populateDuplicates(in context: NSManagedObjectContext) {
        let first = set("1-1", in: context)
        let second = set("1-1", in: context)
        let unique = set("2-1", in: context)
        let firstData = insert("SetUserData", ["number": "1-1", "owned": true], in: context)
        firstData.setValue(first, forKey: "set")
        let secondData = insert(
            "SetUserData", ["number": "1-1", "favorite": true, "ownsInstructions": true, "instructionsQuality": 3],
            in: context
        )
        secondData.setValue(second, forKey: "set")

        let part = insert("Part", ["number": "p1", "name": "Brick", "material": "Plastic"], in: context)
        let partCopy = insert("Part", ["number": "p1", "name": "Brick", "material": "Plastic"], in: context)
        insert("SetPart", ["quantity": 2], in: context).setValuesForKeys(["set": unique, "part": partCopy])
        insert("SetPart", ["quantity": 1], in: context).setValuesForKeys(["set": unique, "part": part])

        insert("Minifig", ["number": "m1", "name": "Pilot"], in: context)
        let minifigCopy = insert("Minifig", ["number": "m1", "name": "Pilot"], in: context)
        insert("SetMinifig", ["quantity": 1], in: context).setValuesForKeys(["set": unique, "minifig": minifigCopy])

        insert("PartsList", ["name": "Wall"], in: context)
        let listCopy = insert("PartsList", ["name": "Wall"], in: context)
        insert("PartsList", ["name": "Wall (2)"], in: context)
        insert("PartsListPart", ["quantity": 5], in: context).setValuesForKeys([
            "partsList": listCopy,
            "part": partCopy,
        ])
    }

    @Test func duplicatesAreResolvedSoMigrationSucceeds() throws {
        try writeStore(model: versionOneModel(), populateDuplicates)

        // One extra row each of SetUserData, Set, Part, Minifig, PartsList.
        #expect(try prepare() == 5)

        let context = try migratedContainer().viewContext
        let sets = try context.fetch(Set.fetchRequest()).sorted { $0.number < $1.number }
        #expect(sets.map(\.number) == ["1-1", "2-1"])

        let userData = try #require(sets.first?.userData)
        #expect(try context.count(for: SetUserData.fetchRequest()) == 1)
        #expect(userData.owned)
        #expect(userData.favorite)
        #expect(userData.ownsInstructions)
        #expect(userData.instructionsQuality == 3)

        let parts = try context.fetch(Part.fetchRequest())
        #expect(parts.count == 1)
        let setParts = sets.last?.parts as? Swift.Set<SetPart> ?? []
        #expect(setParts.map(\.quantity).sorted() == [1, 2])
        #expect(setParts.allSatisfy { $0.part == parts.first })

        let minifigs = try context.fetch(Minifig.fetchRequest())
        #expect(minifigs.count == 1)
        let setMinifigs = sets.last?.minifigs as? Swift.Set<SetMinifig> ?? []
        #expect(setMinifigs.map(\.minifig) == [minifigs.first])

        let lists = try context.fetch(PartsList.fetchRequest())
        #expect(lists.map(\.name).sorted() == ["Wall", "Wall (2)", "Wall (3)"])
        let listWithPart = lists.first { !$0.partsArray.isEmpty }
        #expect(listWithPart?.partsArray.map(\.quantity) == [5])
        #expect(listWithPart?.partsArray.first?.part == parts.first)
    }

    @Test func setWithUserDataSurvivesWhenItIsNotFirst() throws {
        try writeStore(model: versionOneModel()) { context in
            set("1-1", in: context)
            let owned = set("1-1", in: context)
            owned.setValue("Owned copy", forKey: "name")
            insert("SetUserData", ["number": "1-1", "owned": true], in: context).setValue(owned, forKey: "set")
        }

        #expect(try prepare() == 1)

        let context = try migratedContainer().viewContext
        let sets = try context.fetch(Set.fetchRequest())
        #expect(sets.map(\.name) == ["Owned copy"])
        #expect(sets.first?.userData?.owned == true)
    }

    /// An unlinked copy (as builds before `ensureUserData` adopted unlinked
    /// rows left behind) is inserted first, so keeping the group's first row
    /// would orphan the set.
    @Test func linkedUserDataSurvivesAndKeepsTheHigherRating() throws {
        try writeStore(model: versionOneModel()) { context in
            insert("SetUserData", ["number": "1-1", "owned": true, "instructionsQuality": 2], in: context)
            let linked = insert(
                "SetUserData",
                ["number": "1-1", "favorite": true, "instructionsQuality": 4],
                in: context
            )
            linked.setValue(set("1-1", in: context), forKey: "set")
        }

        #expect(try prepare() == 1)

        let context = try migratedContainer().viewContext
        let survivingSet = try #require(try context.fetch(Set.fetchRequest()).first)
        let userData = try #require(survivingSet.userData)
        #expect(try context.count(for: SetUserData.fetchRequest()) == 1)
        #expect(userData.owned)
        #expect(userData.favorite)
        #expect(userData.instructionsQuality == 4)
    }

    @Test func threeCopiesFoldIntoOneRow() throws {
        try writeStore(model: versionOneModel()) { context in
            let owner = set("1-1", in: context)
            for quantity in 1...3 {
                let part = insert("Part", ["number": "p2", "name": "Plate", "material": "Plastic"], in: context)
                insert("SetPart", ["quantity": quantity], in: context).setValuesForKeys(["set": owner, "part": part])
            }
        }

        #expect(try prepare() == 2)

        let context = try migratedContainer().viewContext
        let parts = try context.fetch(Part.fetchRequest())
        #expect(parts.count == 1)
        let owner = try #require(try context.fetch(Set.fetchRequest()).first)
        let setParts = owner.parts as? Swift.Set<SetPart> ?? []
        #expect(setParts.map(\.quantity).sorted() == [1, 2, 3])
        #expect(setParts.allSatisfy { $0.part == parts.first })
    }

    @Test func storeWithoutDuplicatesIsLeftAsIs() throws {
        try writeStore(model: versionOneModel()) { context in
            set("1-1", in: context)
            insert("PartsList", ["name": "Wall"], in: context)
        }

        #expect(try prepare() == 0)
        #expect(try migratedContainer().viewContext.count(for: Set.fetchRequest()) == 1)
    }

    @Test func compatibleStoreSkipsTheDuplicateCheck() throws {
        try writeStore(model: CoreDataStack.managedObjectModel) { context in
            set("1-1", in: context)
        }
        var sourceModelsRequested = false

        let resolved = try StoreDeduplicator.prepareForMigration(
            storeAt: storeURL, options: nil, to: CoreDataStack.managedObjectModel,
            sourceModels: { sourceModelsRequested = true
                return bundledVersions
            }()
        )

        #expect(resolved == 0)
        #expect(!sourceModelsRequested)
    }

    @Test func missingStoreIsANoOp() throws {
        #expect(try prepare() == 0)
        #expect(!FileManager.default.fileExists(atPath: storeURL.path))
    }

    @Test func storeMatchingNoBundledModelIsSkipped() throws {
        try writeStore(model: versionOneModel()) { context in
            set("1-1", in: context)
            set("1-1", in: context)
        }

        let resolved = try StoreDeduplicator.prepareForMigration(
            storeAt: storeURL, options: nil, to: CoreDataStack.managedObjectModel, sourceModels: []
        )

        #expect(resolved == 0)
    }
}
