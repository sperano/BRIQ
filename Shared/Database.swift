//
//  Database.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import CoreData
import OSLog

/// The on-disk format of exported user data.
nonisolated struct UserDataExport: Codable, Equatable {
    static let currentVersion = "1.0"
    static let supportedVersions: Swift.Set<String> = [currentVersion]

    struct Entry: Codable, Equatable {
        static let instructionsQualityRange: ClosedRange<Int32> = 0...Int32(StarRatingView.maxRating)

        var number: String
        var owned: Bool
        var favorite: Bool
        var ownsInstructions: Bool
        var instructionsQuality: Int32

        init(number: String, owned: Bool, favorite: Bool, ownsInstructions: Bool, instructionsQuality: Int32) {
            self.number = number
            self.owned = owned
            self.favorite = favorite
            self.ownsInstructions = ownsInstructions
            self.instructionsQuality = instructionsQuality
        }

        /// Only `number` is required; absent flags mean "not set", as in
        /// hand-written files. Surrounding whitespace is dropped from the
        /// number so it still matches its set.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            number = try container.decode(String.self, forKey: .number)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            owned = try container.decodeIfPresent(Bool.self, forKey: .owned) ?? false
            favorite = try container.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
            ownsInstructions = try container.decodeIfPresent(Bool.self, forKey: .ownsInstructions) ?? false
            instructionsQuality = try container.decodeIfPresent(Int32.self, forKey: .instructionsQuality) ?? 0
        }
    }

    var version: String
    var exportDate: Date?
    var userData: [Entry]

    /// Rejects what the model cannot store: unknown versions, empty or
    /// duplicate set numbers, and out-of-range instruction ratings.
    func validate() throws {
        guard Self.supportedVersions.contains(version) else {
            throw UserDataImportError.unsupportedVersion(version)
        }
        var seen = Swift.Set<String>()
        for entry in userData {
            guard !entry.number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw UserDataImportError.emptyNumber
            }
            guard seen.insert(entry.number).inserted else {
                throw UserDataImportError.duplicateNumber(entry.number)
            }
            guard Entry.instructionsQualityRange.contains(entry.instructionsQuality) else {
                throw UserDataImportError.invalidInstructionsQuality(number: entry.number, value: entry.instructionsQuality)
            }
        }
    }
}

nonisolated enum UserDataImportError: LocalizedError, Equatable {
    case notUTF8
    case malformed(String)
    case unsupportedVersion(String)
    case emptyNumber
    case duplicateNumber(String)
    case invalidInstructionsQuality(number: String, value: Int32)

    var errorDescription: String? {
        switch self {
        case .notUTF8:
            return String(localized: "The user data file is not UTF-8 text.")
        case .malformed(let detail):
            return String(localized: "The user data file is not valid: \(detail)")
        case .unsupportedVersion(let version):
            return String(localized: "User data version \(version) is not supported.")
        case .emptyNumber:
            return String(localized: "The user data file contains an entry without a set number.")
        case .duplicateNumber(let number):
            return String(localized: "The user data file lists set \(number) more than once.")
        case .invalidInstructionsQuality(let number, let value):
            let range = UserDataExport.Entry.instructionsQualityRange
            return String(
                localized: "Set \(number) has an instructions rating of \(value); expected \(range.lowerBound)–\(range.upperBound).",
                comment: "User data import error: an out-of-range instructions rating and the accepted range"
            )
        }
    }
}

func exportUserData(context: NSManagedObjectContext) -> String? {
    do {
        let request = SetUserData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let export = UserDataExport(
            version: UserDataExport.currentVersion,
            exportDate: Date(),
            userData: try context.fetch(request).map { userData in
                UserDataExport.Entry(
                    number: userData.number,
                    owned: userData.owned,
                    favorite: userData.favorite,
                    ownsInstructions: userData.ownsInstructions,
                    instructionsQuality: userData.instructionsQuality
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(data: try encoder.encode(export), encoding: .utf8)
    } catch {
        Logger.dataTransfer.error("Failed to export user data: \(error)")
        return nil
    }
}

/// The text of a user data file, which must be UTF-8.
func userDataString(from data: Data) throws -> String {
    guard let string = String(data: data, encoding: .utf8) else {
        throw UserDataImportError.notUTF8
    }
    return string
}

func decodeUserDataExport(_ jsonString: String) throws -> UserDataExport {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let export: UserDataExport
    do {
        export = try decoder.decode(UserDataExport.self, from: Data(jsonString.utf8))
    } catch let error as DecodingError {
        throw UserDataImportError.malformed(describe(error))
    }
    try export.validate()
    return export
}

private func describe(_ error: DecodingError) -> String {
    func path(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
        return path.isEmpty
            ? String(localized: "the top level", comment: "Where in the user data file a value is invalid")
            : String(path.drop { $0 == "." })
    }
    switch error {
    case .dataCorrupted(let context) where context.codingPath.isEmpty:
        return String(localized: "it is not JSON.", comment: "Ends \"The user data file is not valid: %@\"")
    case .dataCorrupted(let context):
        return String(localized: "the value at \(path(context)) is invalid.", comment: "Ends \"The user data file is not valid: %@\"")
    case .keyNotFound(let key, let context):
        return String(localized: "\"\(key.stringValue)\" is missing at \(path(context)).", comment: "Ends \"The user data file is not valid: %@\"")
    case .typeMismatch(_, let context), .valueNotFound(_, let context):
        return String(localized: "the value at \(path(context)) has the wrong type.", comment: "Ends \"The user data file is not valid: %@\"")
    @unknown default:
        return error.localizedDescription
    }
}

/// Replaces all user data with the contents of `jsonString`. The input is
/// decoded and validated before the context is touched (invalid input throws
/// `UserDataImportError`); if saving fails the context is rolled back and the
/// Core Data error rethrown, so existing user data survives any failure.
/// Returns the number of imported entries, including those matching no set.
@discardableResult
func importUserData(context: NSManagedObjectContext, jsonString: String) throws -> Int {
    let export = try decodeUserDataExport(jsonString)
    do {
        try replaceUserData(with: export.userData, in: context)
        try context.save()
    } catch {
        context.rollback()
        Logger.dataTransfer.error("Failed to import user data: \(error)")
        throw error
    }
    Logger.dataTransfer.info("Successfully imported \(export.userData.count) user data entries")
    return export.userData.count
}

/// Updates existing rows in place rather than deleting and re-inserting, so
/// the save never holds two objects with the same `number`.
private func replaceUserData(with entries: [UserDataExport.Entry], in context: NSManagedObjectContext) throws {
    let existing = Dictionary(
        try context.fetch(SetUserData.fetchRequest()).map { ($0.number, $0) },
        uniquingKeysWith: { first, _ in first }
    )
    let setsRequest = Set.fetchRequest()
    setsRequest.predicate = NSPredicate(format: "number IN %@", entries.map(\.number))
    let sets = Dictionary(
        try context.fetch(setsRequest).map { ($0.number, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    let importedNumbers = Swift.Set(entries.map(\.number))
    for (number, userData) in existing where !importedNumbers.contains(number) {
        context.delete(userData)
    }

    for entry in entries {
        let userData = existing[entry.number] ?? SetUserData.create(in: context, number: entry.number)
        userData.owned = entry.owned
        userData.favorite = entry.favorite
        userData.ownsInstructions = entry.ownsInstructions
        userData.instructionsQuality = entry.instructionsQuality
        if let set = sets[entry.number] {
            userData.set = set
            set.userData = userData
        }
    }
}
