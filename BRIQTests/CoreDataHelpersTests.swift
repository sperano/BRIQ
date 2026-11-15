//
//  CoreDataHelpersTests.swift
//  BRIQTests
//

import CoreData
import Testing
@testable import BRIQ

/// Objects are inserted by entity name: the host app loads its own copy of
/// the model, and `init(context:)` cannot tell the two apart.
@MainActor
struct CoreDataHelpersTests {
    private let stack = CoreDataStack(inMemory: true)
    private var context: NSManagedObjectContext { stack.viewContext }

    private func insert<Object: NSManagedObject>(_ entityName: String, as _: Object.Type) throws -> Object {
        try #require(NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? Object)
    }

    private func insertSet(number: String) throws {
        try insert("Set", as: BRIQ.Set.self).number = number
    }

    @Test func storeLoads() {
        #expect(stack.loadError == nil)
    }

    @Test func fetchByNumberReturnsTheMatchingSet() throws {
        try insertSet(number: "10001-1")
        try insertSet(number: "10002-1")

        let set = try #require(BRIQ.Set.fetch(byNumber: "10002-1", in: context))
        #expect(set.number == "10002-1")
    }

    @Test func fetchByNumberReturnsNilWhenNoSetMatches() throws {
        try insertSet(number: "10001-1")

        #expect(BRIQ.Set.fetch(byNumber: "10001", in: context) == nil)
    }

    @Test func fetchByNameReturnsTheMatchingPartsList() throws {
        try insert("PartsList", as: PartsList.self).name = "Castle"
        try insert("PartsList", as: PartsList.self).name = "Space"

        let partsList = try #require(PartsList.fetch(byName: "Space", in: context))
        #expect(partsList.name == "Space")
        #expect(PartsList.fetch(byName: "space", in: context) == nil)
    }

    @Test func createCopyingASetPartCopiesItsPartColorQuantityAndImage() throws {
        let part = try insert("Part", as: Part.self)
        part.number = "3001"
        let setPart = try insert("SetPart", as: SetPart.self)
        setPart.part = part
        setPart.colorID = 4
        setPart.quantity = 12
        setPart.imageURL = "https://example.com/3001.png"
        let partsList = try insert("PartsList", as: PartsList.self)

        let copy = try #require(PartsListPart.create(in: context, partsList: partsList, copying: setPart))

        #expect(copy.partsList === partsList)
        #expect(copy.part === part)
        #expect(copy.colorID == 4)
        #expect(copy.quantity == 12)
        #expect(copy.imageURL == "https://example.com/3001.png")
    }

    @Test func createCopyingASetPartWithoutPartInsertsNothing() throws {
        let setPart = try insert("SetPart", as: SetPart.self)
        let partsList = try insert("PartsList", as: PartsList.self)

        #expect(PartsListPart.create(in: context, partsList: partsList, copying: setPart) == nil)
        let request = PartsListPart.fetchRequest()
        #expect(try context.count(for: request) == 0)
    }
}
