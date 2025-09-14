//
//  CoreDataTests.swift
//  BRIQTests
//
//  Created by Claude on 13/09/25.
//

import XCTest
import CoreData
@testable import BRIQ_ios

final class CoreDataTests: XCTestCase {

    var testStack: CoreDataStack!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        // Create an in-memory store for testing
        testStack = CoreDataStack()

        // Override the persistent container to use in-memory store
        let container = NSPersistentContainer(name: "BRIQ")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        testStack.persistentContainer = container
        testContext = testStack.viewContext
    }

    override func tearDownWithError() throws {
        testStack = nil
        testContext = nil
    }

    // MARK: - Part Tests

    func testPartCreation() throws {
        let part = Part.create(
            in: testContext,
            number: "3001",
            name: "Brick 2 x 4",
            material: "Plastic",
            category: 11
        )

        XCTAssertEqual(part.number, "3001")
        XCTAssertEqual(part.name, "Brick 2 x 4")
        XCTAssertEqual(part.material, "Plastic")
        XCTAssertEqual(part.categoryRawValue, 11)
        XCTAssertEqual(part.id, "3001")
    }

    func testPartCategoryEnum() throws {
        let part = Part.create(
            in: testContext,
            number: "3001",
            name: "Brick 2 x 4",
            material: "Plastic",
            category: 11
        )

        part.category = .bricks
        XCTAssertEqual(part.categoryRawValue, 11)
        XCTAssertEqual(part.category, .bricks)
    }

    func testPartFetch() throws {
        // Create a part
        _ = Part.create(
            in: testContext,
            number: "3001",
            name: "Brick 2 x 4",
            material: "Plastic",
            category: 11
        )

        try testContext.save()

        // Fetch the part
        let fetchedPart = Part.fetch(byNumber: "3001", in: testContext)
        XCTAssertNotNil(fetchedPart)
        XCTAssertEqual(fetchedPart?.name, "Brick 2 x 4")
    }

    // MARK: - Minifig Tests

    func testMinifigCreation() throws {
        let minifig = Minifig.create(
            in: testContext,
            number: "fig-000020",
            name: "Classic Spaceman",
            partsCount: 5,
            imageURL: "https://example.com/fig.jpg"
        )

        XCTAssertEqual(minifig.number, "fig-000020")
        XCTAssertEqual(minifig.name, "Classic Spaceman")
        XCTAssertEqual(minifig.partsCount, 5)
        XCTAssertEqual(minifig.imageURL, "https://example.com/fig.jpg")
        XCTAssertEqual(minifig.id, "fig-000020")
    }

    func testMinifigFetch() throws {
        _ = Minifig.create(
            in: testContext,
            number: "fig-000020",
            name: "Classic Spaceman",
            partsCount: 5
        )

        try testContext.save()

        let fetchedMinifig = Minifig.fetch(byNumber: "fig-000020", in: testContext)
        XCTAssertNotNil(fetchedMinifig)
        XCTAssertEqual(fetchedMinifig?.name, "Classic Spaceman")
    }

    // MARK: - Set Tests

    func testSetCreation() throws {
        let set = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: "https://example.com/set.jpg",
            partsCount: 443,
            themeID: 50,
            isPack: false,
            isUnreleased: false,
            isAccessory: false
        )

        XCTAssertEqual(set.number, "6980-1")
        XCTAssertEqual(set.name, "Galaxy Commander")
        XCTAssertEqual(set.year, 1983)
        XCTAssertEqual(set.partsCount, 443)
        XCTAssertEqual(set.themeID, 50)
        XCTAssertFalse(set.isPack)
        XCTAssertEqual(set.id, "6980-1")
    }

    func testSetBaseNumber() throws {
        let set = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        XCTAssertEqual(set.baseNumber, "6980")
    }

    func testSetComparison() throws {
        let set1 = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        let set2 = Set.create(
            in: testContext,
            number: "6954-1",
            isUSNumber: false,
            name: "Renegade",
            year: 1987,
            imageURL: nil,
            partsCount: 200,
            themeID: 50
        )

        XCTAssertTrue(set1 < set2) // Earlier year
    }

    func testSetFetch() throws {
        _ = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        try testContext.save()

        let fetchedSet = Set.fetch(byNumber: "6980-1", in: testContext)
        XCTAssertNotNil(fetchedSet)
        XCTAssertEqual(fetchedSet?.name, "Galaxy Commander")
    }

    // MARK: - SetUserData Tests

    func testSetUserDataCreation() throws {
        let userData = SetUserData.create(
            in: testContext,
            number: "6980-1",
            owned: true,
            favorite: true,
            ownsInstructions: true,
            instructionsQuality: 4
        )

        XCTAssertEqual(userData.number, "6980-1")
        XCTAssertTrue(userData.owned)
        XCTAssertTrue(userData.favorite)
        XCTAssertTrue(userData.ownsInstructions)
        XCTAssertEqual(userData.instructionsQuality, 4)
        XCTAssertEqual(userData.id, "6980-1")
    }

    func testSetUserDataComparison() throws {
        let userData1 = SetUserData.create(in: testContext, number: "6980-1")
        let userData2 = SetUserData.create(in: testContext, number: "6954-1")

        XCTAssertTrue(userData2 < userData1) // 6954 < 6980
    }

    // MARK: - Relationship Tests

    func testSetPartRelationship() throws {
        let part = Part.create(
            in: testContext,
            number: "3001",
            name: "Brick 2 x 4",
            material: "Plastic",
            category: 11
        )

        let set = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        let setPart = SetPart.create(
            in: testContext,
            part: part,
            colorID: 5,
            quantity: 3,
            imageURL: "https://example.com/part.jpg"
        )
        setPart.set = set

        XCTAssertEqual(setPart.part, part)
        XCTAssertEqual(setPart.set, set)
        XCTAssertEqual(setPart.colorID, 5)
        XCTAssertEqual(setPart.quantity, 3)
        XCTAssertEqual(set.actualPartsCount, 3)
    }

    func testSetMinifigRelationship() throws {
        let minifig = Minifig.create(
            in: testContext,
            number: "fig-000020",
            name: "Classic Spaceman",
            partsCount: 5
        )

        let set = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        let setMinifig = SetMinifig.create(
            in: testContext,
            minifig: minifig,
            quantity: 2
        )
        setMinifig.set = set

        XCTAssertEqual(setMinifig.minifig, minifig)
        XCTAssertEqual(setMinifig.set, set)
        XCTAssertEqual(setMinifig.quantity, 2)
        XCTAssertEqual(set.minifigsCount, 2)
    }

    func testSetUserDataRelationship() throws {
        let set = Set.create(
            in: testContext,
            number: "6980-1",
            isUSNumber: false,
            name: "Galaxy Commander",
            year: 1983,
            imageURL: nil,
            partsCount: 443,
            themeID: 50
        )

        let userData = SetUserData.create(
            in: testContext,
            number: "6980-1",
            owned: true,
            favorite: true
        )

        set.userData = userData

        XCTAssertEqual(set.userData, userData)
        XCTAssertEqual(userData.set, set)
    }

    // MARK: - Core Data Stack Tests

    func testCoreDataStackSaving() throws {
        let part = Part.create(
            in: testContext,
            number: "3001",
            name: "Brick 2 x 4",
            material: "Plastic",
            category: 11
        )

        XCTAssertTrue(testContext.hasChanges)
        testStack.saveContext()
        XCTAssertFalse(testContext.hasChanges)

        // Verify the part was saved
        let request = Part.fetchRequest()
        let results = try testContext.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.number, "3001")
    }

    func testBackgroundContextSaving() throws {
        let backgroundContext = testStack.newBackgroundContext()

        backgroundContext.performAndWait {
            let part = Part.create(
                in: backgroundContext,
                number: "3002",
                name: "Brick 2 x 3",
                material: "Plastic",
                category: 11
            )

            XCTAssertTrue(backgroundContext.hasChanges)
        }

        try testStack.saveBackgroundContext(backgroundContext)

        // Verify the part is available in the view context
        let request = Part.fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", "3002")
        let results = try testContext.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Brick 2 x 3")
    }

    // MARK: - Performance Tests

    func testBatchInsertion() throws {
        let expectation = XCTestExpectation(description: "Batch insertion")

        Task {
            let objects = (1...1000).map { i in
                [
                    "number": "part\(i)",
                    "name": "Test Part \(i)",
                    "material": "Plastic",
                    "categoryRawValue": 11
                ]
            }

            try await testStack.performBatchInsert(entityName: "Part", objects: objects)

            let request = Part.fetchRequest()
            let count = try testContext.count(for: request)
            XCTAssertEqual(count, 1000)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testBatchDeletion() throws {
        // First, create some parts
        for i in 1...100 {
            _ = Part.create(
                in: testContext,
                number: "part\(i)",
                name: "Test Part \(i)",
                material: "Plastic",
                category: 11
            )
        }
        try testContext.save()

        let expectation = XCTestExpectation(description: "Batch deletion")

        Task {
            let predicate = NSPredicate(format: "number BEGINSWITH %@", "part")
            try await testStack.performBatchDelete(entityName: "Part", predicate: predicate)

            let request = Part.fetchRequest()
            let count = try testContext.count(for: request)
            XCTAssertEqual(count, 0)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}