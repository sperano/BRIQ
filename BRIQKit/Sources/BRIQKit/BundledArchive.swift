//
//  BundledArchive.swift
//  BRIQKit
//
//  The format of the bundled LEGO database, `init.zip`: one `init.json` entry, snake_case keys.
//

import Foundation
import ZIPFoundation

public struct JSONPart: Decodable, Sendable {
    public let number: String
    public let name: String
    public let partCategoryId: Int
    public let material: String
}

public struct JSONMinifig: Decodable, Sendable {
    public let number: String
    public let name: String
    public let partsCount: Int
    public let imgUrl: String?
}

public struct JSONSetMinifig: Decodable, Sendable {
    public let number: String
    public let quantity: Int
}

public struct JSONSetPart: Decodable, Sendable {
    public let number: String
    public let colorId: Int
    public let quantity: Int
    public let imgUrl: String?
}

public struct JSONSet: Decodable, Sendable {
    public let number: String
    public let isUsNumber: Bool
    public let sameAsNumber: String?
    public let name: String
    public let year: Int
    public let themeId: Int64
    public let partsCount: Int
    public let imgUrl: String?
    public let minifigs: [JSONSetMinifig]
    public let parts: [JSONSetPart]
    public let isPack: Bool
    public let isUnreleased: Bool
    public let isAccessories: Bool
}

public struct JSONData: Decodable, Sendable {
    public let parts: [JSONPart]
    public let minifigs: [JSONMinifig]
    public let sets: [JSONSet]
}

public enum BundledArchive {
    /// The archive entry holding the database.
    static let jsonEntryName = "init.json"

    /// Unzips the archive at `zipURL` into a temporary directory, removed afterwards, and decodes
    /// its `init.json`. Throws ZIPFoundation's error for an unreadable archive, the file error
    /// when the entry is missing and the `DecodingError` for malformed JSON.
    public static func decode(contentsOf zipURL: URL) throws -> JSONData {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        try fileManager.unzipItem(at: zipURL, to: tempDir)
        let jsonData = try Data(contentsOf: tempDir.appendingPathComponent(jsonEntryName))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(JSONData.self, from: jsonData)
    }
}
