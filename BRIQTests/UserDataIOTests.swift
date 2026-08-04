//
//  UserDataIOTests.swift
//  BRIQTests
//

import Testing
import CoreData
@testable import BRIQ

@Suite @MainActor struct UserDataIOTests {
    let stack = CoreDataStack(inMemory: true)

    private func makeSet(_ number: String) -> Set {
        Set.create(
            in: stack.viewContext, number: number, isUSNumber: false, name: "Set \(number)",
            year: 2000, imageURL: nil, partsCount: 0, themeID: 0
        )
    }

    @Test func exportImportRoundTrip() throws {
        let context = stack.viewContext
        let set = makeSet("100-1")
        let userData = SetUserData.create(
            in: context, number: "100-1", owned: true, favorite: true,
            ownsInstructions: true, instructionsQuality: 4
        )
        userData.set = set
        set.userData = userData
        try context.save()

        let exported = try #require(exportUserData(context: context))

        // Wipe user data, keep the set
        context.delete(userData)
        try context.save()
        #expect(set.userData == nil)

        importUserData(context: context, jsonString: exported)

        let reimported = try #require(set.userData)
        #expect(reimported.owned)
        #expect(reimported.favorite)
        #expect(reimported.ownsInstructions)
        #expect(reimported.instructionsQuality == 4)
    }

    @Test func importReplacesExistingUserData() throws {
        let context = stack.viewContext
        let set = makeSet("200-1")
        let userData = SetUserData.create(in: context, number: "200-1", owned: false)
        userData.set = set
        set.userData = userData
        try context.save()

        let json = """
        {"version": "1.0", "userData": [{"number": "200-1", "owned": true}]}
        """
        importUserData(context: context, jsonString: json)

        let all = try context.fetch(SetUserData.fetchRequest())
        #expect(all.count == 1)
        #expect(set.userData?.owned == true)
    }

    @Test func malformedJSONLeavesExistingDataIntact() throws {
        let context = stack.viewContext
        let set = makeSet("300-1")
        let userData = SetUserData.create(in: context, number: "300-1", owned: true)
        userData.set = set
        set.userData = userData
        try context.save()

        importUserData(context: context, jsonString: "not json at all {")

        let all = try context.fetch(SetUserData.fetchRequest())
        #expect(all.count == 1)
        #expect(set.userData?.owned == true)
    }

    @Test func entriesWithoutNumberAreSkipped() throws {
        let context = stack.viewContext
        _ = makeSet("400-1")
        try context.save()

        let json = """
        {"version": "1.0", "userData": [{"owned": true}, {"number": "400-1", "owned": true}]}
        """
        importUserData(context: context, jsonString: json)

        let all = try context.fetch(SetUserData.fetchRequest())
        #expect(all.count == 1)
        #expect(all.first?.number == "400-1")
    }
}
