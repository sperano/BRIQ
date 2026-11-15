//
//  UniquenessConstraintTests.swift
//  BRIQTests
//

import Testing
import CoreData
@testable import BRIQ

/// The identity attributes back `Identifiable.id`; the store must never hold
/// two rows with the same value.
@Suite @MainActor struct UniquenessConstraintTests {
    enum Entity: String, CaseIterable {
        case set = "Set"
        case setUserData = "SetUserData"
        case part = "Part"
        case minifig = "Minifig"
        case partsList = "PartsList"

        @MainActor func insert(key: String, name: String, in context: NSManagedObjectContext) {
            switch self {
            case .set:
                Set.create(
                    in: context, number: key, isUSNumber: false, name: name,
                    year: 2000, imageURL: nil, partsCount: 0, themeID: 0
                )
            case .setUserData:
                SetUserData.create(in: context, number: key)
            case .part:
                Part.create(in: context, number: key, name: name, material: "Plastic", category: 0)
            case .minifig:
                Minifig.create(in: context, number: key, name: name, partsCount: 0, imageURL: nil)
            case .partsList:
                PartsList.create(in: context, name: key)
            }
        }
    }

    @Test(arguments: Entity.allCases)
    func duplicateInsertsCollapseToOneRow(entity: Entity) throws {
        let stack = CoreDataStack(inMemory: true)
        let context = stack.viewContext
        entity.insert(key: "1-1", name: "First", in: context)
        entity.insert(key: "1-1", name: "Second", in: context)
        entity.insert(key: "2-1", name: "Other", in: context)

        try context.save()

        let request = NSFetchRequest<NSManagedObject>(entityName: entity.rawValue)
        #expect(try context.count(for: request) == 2)
    }

    @Test(arguments: Entity.allCases)
    func insertMatchingASavedRowDoesNotAddOne(entity: Entity) throws {
        let stack = CoreDataStack(inMemory: true)
        let context = stack.viewContext
        entity.insert(key: "1-1", name: "First", in: context)
        try context.save()

        entity.insert(key: "1-1", name: "Second", in: context)
        try context.save()

        let request = NSFetchRequest<NSManagedObject>(entityName: entity.rawValue)
        #expect(try context.count(for: request) == 1)
    }
}
