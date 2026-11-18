//
//  UserDataIOTests.swift
//  BRIQTests
//

import CoreData
import Foundation
import Testing
@testable import BRIQ

@MainActor struct UserDataIOTests {
    let stack = CoreDataStack(inMemory: true)

    private func makeSet(_ number: String) -> Set {
        Set.create(
            in: stack.viewContext, number: number, isUSNumber: false, name: "Set \(number)",
            year: 2000, imageURL: nil, partsCount: 0, themeID: 0
        )
    }

    @discardableResult
    private func makeOwnedSet(_ number: String) throws -> Set {
        let set = makeSet(number)
        let userData = SetUserData.create(in: stack.viewContext, number: number, owned: true)
        userData.set = set
        set.userData = userData
        try stack.viewContext.save()
        return set
    }

    private func allUserData() throws -> [SetUserData] {
        let request = SetUserData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        return try stack.viewContext.fetch(request)
    }

    /// Asserts that a rejected import left the one owned "keep-1" row alone.
    private func expectUntouched(_ set: Set) throws {
        let all = try allUserData()
        #expect(all.map(\.number) == ["keep-1"])
        #expect(set.userData?.owned == true)
        #expect(!stack.viewContext.hasChanges)
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

        let imported = try importUserData(context: context, jsonString: exported)

        #expect(imported == 1)
        let reimported = try #require(set.userData)
        #expect(reimported.owned)
        #expect(reimported.favorite)
        #expect(reimported.ownsInstructions)
        #expect(reimported.instructionsQuality == 4)
    }

    /// Older builds read exports with untyped key lookups; the layout must not change.
    @Test func exportKeepsVersionOneLayout() throws {
        try makeOwnedSet("100-1")

        let exported = try #require(exportUserData(context: stack.viewContext))
        let object = try JSONSerialization.jsonObject(with: Data(exported.utf8)) as? [String: Any]
        let root = try #require(object)

        #expect(root["version"] as? String == "1.0")
        let exportDate = try #require(root["exportDate"] as? String)
        #expect(ISO8601DateFormatter().date(from: exportDate) != nil)
        let entries = try #require(root["userData"] as? [[String: Any]])
        #expect(entries.count == 1)
        #expect(entries.first?["number"] as? String == "100-1")
        #expect(entries.first?["owned"] as? Bool == true)
        #expect(entries.first?["favorite"] as? Bool == false)
        #expect(entries.first?["ownsInstructions"] as? Bool == false)
        #expect(entries.first?["instructionsQuality"] as? Int == 0)
    }

    @Test func importUpdatesListedRowsInPlaceAndDeletesUnlisted() throws {
        let kept = try makeOwnedSet("200-1")
        let dropped = try makeOwnedSet("201-1")
        let keptData = try #require(kept.userData)
        keptData.ownsInstructions = true
        keptData.instructionsQuality = 3
        try stack.viewContext.save()

        let json = """
        {"version": "1.0", "userData": [
            {"number": "200-1", "owned": false, "favorite": true, "ownsInstructions": false, "instructionsQuality": 1}
        ]}
        """
        let imported = try importUserData(context: stack.viewContext, jsonString: json)

        #expect(imported == 1)
        #expect(try allUserData().map(\.number) == ["200-1"])
        #expect(kept.userData?.objectID == keptData.objectID)
        #expect(kept.userData?.owned == false)
        #expect(kept.userData?.favorite == true)
        #expect(kept.userData?.ownsInstructions == false)
        #expect(kept.userData?.instructionsQuality == 1)
        #expect(dropped.userData == nil)
    }

    @Test func importingAnEmptyListDeletesAllUserData() throws {
        let set = try makeOwnedSet("keep-1")

        let imported = try importUserData(
            context: stack.viewContext,
            jsonString: #"{"version": "1.0", "userData": []}"#
        )

        #expect(imported == 0)
        #expect(try allUserData().isEmpty)
        #expect(set.userData == nil)
    }

    @Test func surroundingWhitespaceIsDroppedFromNumbers() throws {
        let set = makeSet("200-1")
        try stack.viewContext.save()

        let json = #"{"version": "1.0", "userData": [{"number": " 200-1\n", "owned": true}]}"#
        try importUserData(context: stack.viewContext, jsonString: json)

        #expect(try allUserData().map(\.number) == ["200-1"])
        #expect(set.userData?.owned == true)
    }

    @Test func importCreatesRowsForUnknownSetsWithoutLinkingThem() throws {
        let json = """
        {"version": "1.0", "userData": [{"number": "999-1", "owned": true}]}
        """
        try importUserData(context: stack.viewContext, jsonString: json)

        let row = try #require(try allUserData().first)
        #expect(row.number == "999-1")
        #expect(row.owned)
        #expect(row.set == nil)
    }

    @Test func absentFlagsDefaultToUnset() throws {
        let json = """
        {"version": "1.0", "userData": [{"number": "300-1"}]}
        """
        try importUserData(context: stack.viewContext, jsonString: json)

        let row = try #require(try allUserData().first)
        #expect(!row.owned)
        #expect(!row.favorite)
        #expect(!row.ownsInstructions)
        #expect(row.instructionsQuality == 0)
    }

    @Test func acceptsTheHighestRating() throws {
        let json = """
        {"version": "1.0", "userData": [{"number": "300-1", "instructionsQuality": \(StarRatingView.maxRating)}]}
        """
        try importUserData(context: stack.viewContext, jsonString: json)

        #expect(try allUserData().first?.instructionsQuality == Int32(StarRatingView.maxRating))
    }

    @Test(arguments: [
        ("not json at all {", "it is not JSON."),
        (#"{"userData": [{"number": "1-1"}]}"#, #""version" is missing at the top level."#),
        (#"{"version": "1.0"}"#, #""userData" is missing at the top level."#),
        (#"{"version": "1.0", "userData": [{"owned": true}]}"#, #""number" is missing at userData[0]."#),
        (
            #"{"version": "1.0", "userData": [{"number": "1-1", "owned": "yes"}]}"#,
            "the value at userData[0].owned has the wrong type."
        ),
    ])
    func malformedInputIsRejected(json: String, detail: String) throws {
        let set = try makeOwnedSet("keep-1")

        let error = try #require(throws: UserDataImportError.self) {
            try importUserData(context: stack.viewContext, jsonString: json)
        }

        #expect(error == .malformed(detail))
        #expect(error.errorDescription == "The user data file is not valid: \(detail)")
        try expectUntouched(set)
    }

    @Test func malformedInputMessageNamesTheEntry() throws {
        let json = #"{"version": "1.0", "userData": [{"number": "1-1"}, {"owned": true}]}"#

        let error = try #require(throws: UserDataImportError.self) {
            try importUserData(context: stack.viewContext, jsonString: json)
        }

        #expect(error.errorDescription == #"The user data file is not valid: "number" is missing at userData[1]."#)
    }

    @Test(arguments: [
        (#"{"version": "2.0", "userData": []}"#, UserDataImportError.unsupportedVersion("2.0")),
        (#"{"version": "1.0", "userData": [{"number": " "}]}"#, .emptyNumber),
        (
            #"{"version": "1.0", "userData": [{"number": "1-1"}, {"number": "1-1", "owned": true}]}"#,
            .duplicateNumber("1-1")
        ),
        (#"{"version": "1.0", "userData": [{"number": "1-1"}, {"number": "1-1 "}]}"#, .duplicateNumber("1-1")),
        (
            #"{"version": "1.0", "userData": [{"number": "1-1", "instructionsQuality": 6}]}"#,
            .invalidInstructionsQuality(number: "1-1", value: 6)
        ),
        (
            #"{"version": "1.0", "userData": [{"number": "1-1", "instructionsQuality": -1}]}"#,
            .invalidInstructionsQuality(number: "1-1", value: -1)
        ),
    ])
    func invalidContentIsRejectedBeforeAnyChange(json: String, expected: UserDataImportError) throws {
        let set = try makeOwnedSet("keep-1")

        #expect(throws: expected) {
            try importUserData(context: stack.viewContext, jsonString: json)
        }
        try expectUntouched(set)
    }

    @Test(arguments: [
        (UserDataImportError.notUTF8, "The user data file is not UTF-8 text."),
        (.unsupportedVersion("2.0"), "User data version 2.0 is not supported."),
        (.emptyNumber, "The user data file contains an entry without a set number."),
        (.duplicateNumber("1-1"), "The user data file lists set 1-1 more than once."),
        (
            .invalidInstructionsQuality(number: "1-1", value: 6),
            "Set 1-1 has an instructions rating of 6; expected 0–5."
        ),
    ])
    func errorDescriptions(error: UserDataImportError, expected: String) {
        #expect(error.errorDescription == expected)
    }

    @Test func importedMessageUsesTheSingularForOneEntry() {
        #expect(userDataImportedMessage(count: 1) == "Imported 1 user data entry.")
    }

    @Test func importedMessageUsesThePluralForMoreEntries() {
        #expect(userDataImportedMessage(count: 0) == "Imported 0 user data entries.")
        #expect(userDataImportedMessage(count: 12) == "Imported 12 user data entries.")
    }

    @Test func failedMessageGivesTheReasonAndSaysNothingChanged() {
        #expect(userDataImportFailedMessage(UserDataImportError.emptyNumber)
            == "The user data file contains an entry without a set number. Your existing user data was not changed.")
    }

    @Test func fileTextMustBeUTF8() throws {
        #expect(try userDataString(from: Data(#"{"version": "1.0"}"#.utf8)) == #"{"version": "1.0"}"#)
        // 0xC3 starts a two-byte sequence that 0x28 does not continue.
        #expect(throws: UserDataImportError.notUTF8) {
            try userDataString(from: Data([0xC3, 0x28]))
        }
    }

    @Test func failedSaveRollsBackTheImport() throws {
        let set = try makeOwnedSet("keep-1")
        // A pending set without its mandatory name makes the save fail.
        let invalid = Set(context: stack.viewContext)
        invalid.number = "invalid-1"

        let json = """
        {"version": "1.0", "userData": [{"number": "new-1", "owned": true}]}
        """
        let error = try #require(throws: (any Error).self) {
            try importUserData(context: stack.viewContext, jsonString: json)
        }

        let nsError = error as NSError
        #expect(nsError.domain == NSCocoaErrorDomain)
        #expect((NSValidationErrorMinimum...NSValidationErrorMaximum).contains(nsError.code))
        try expectUntouched(set)
    }
}
