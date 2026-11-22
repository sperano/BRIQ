//
//  BundledArchiveTests.swift
//  BRIQKitTests
//

import BRIQKit
import Foundation
import Testing
import ZIPFoundation

/// A temporary directory holding an archive built from `json` (or an empty archive when it is
/// nil), removed on `deinit`.
private final class ArchiveFixture {
    let directory: URL
    let zipURL: URL

    init(json: String?) throws {
        let fileManager = FileManager.default
        directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        zipURL = directory.appendingPathComponent("init.zip")
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let archive = try Archive(url: zipURL, accessMode: .create)
        if let json {
            let data = Data(json.utf8)
            try archive
                .addEntry(with: "init.json", type: .file, uncompressedSize: Int64(data.count)) { position, size in
                    data.subdata(in: Int(position)..<Int(position) + size)
                }
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }
}

struct BundledArchiveTests {
    private static let json = """
    {
      "parts": [{"number": "3001", "name": "Brick 2 x 4", "part_category_id": 11, "material": "Plastic"}],
      "minifigs": [{"number": "fig-000001", "name": "Test Fig", "parts_count": 4, "img_url": "https://x/fig.png"}],
      "sets": [{
        "number": "100-1", "is_us_number": true, "same_as_number": "100-2", "name": "Test Set",
        "year": 1990, "theme_id": 7, "parts_count": 6, "img_url": null,
        "minifigs": [{"number": "fig-000001", "quantity": 2}],
        "parts": [{"number": "3001", "color_id": 5, "quantity": 4, "img_url": "https://x/3001.png"}],
        "is_pack": true, "is_unreleased": false, "is_accessories": true
      }]
    }
    """

    @Test func decodesPartsAndMinifigs() throws {
        let fixture = try ArchiveFixture(json: Self.json)
        let data = try BundledArchive.decode(contentsOf: fixture.zipURL)

        let part = try #require(data.parts.first)
        #expect(data.parts.count == 1)
        #expect(part.number == "3001")
        #expect(part.name == "Brick 2 x 4")
        #expect(part.partCategoryId == 11)
        #expect(part.material == "Plastic")

        let minifig = try #require(data.minifigs.first)
        #expect(data.minifigs.count == 1)
        #expect(minifig.number == "fig-000001")
        #expect(minifig.name == "Test Fig")
        #expect(minifig.partsCount == 4)
        #expect(minifig.imgUrl == "https://x/fig.png")
    }

    @Test func decodesSets() throws {
        let fixture = try ArchiveFixture(json: Self.json)
        let set = try #require(BundledArchive.decode(contentsOf: fixture.zipURL).sets.first)

        #expect(set.number == "100-1")
        #expect(set.isUsNumber)
        #expect(set.sameAsNumber == "100-2")
        #expect(set.name == "Test Set")
        #expect(set.year == 1990)
        #expect(set.themeId == 7)
        #expect(set.partsCount == 6)
        #expect(set.imgUrl == nil)
        #expect(set.isPack)
        #expect(!set.isUnreleased)
        #expect(set.isAccessories)
        #expect(set.minifigs.map(\.number) == ["fig-000001"])
        #expect(set.minifigs.map(\.quantity) == [2])
        let part = try #require(set.parts.first)
        #expect(set.parts.count == 1)
        #expect(part.number == "3001")
        #expect(part.colorId == 5)
        #expect(part.quantity == 4)
        #expect(part.imgUrl == "https://x/3001.png")
    }

    @Test func archiveWithoutJSONEntryThrowsFileNotFound() throws {
        let fixture = try ArchiveFixture(json: nil)
        #expect {
            try BundledArchive.decode(contentsOf: fixture.zipURL)
        } throws: { error in
            (error as? CocoaError)?.code == .fileReadNoSuchFile
        }
    }

    @Test func malformedJSONThrowsDecodingError() throws {
        let fixture = try ArchiveFixture(json: #"{"parts": []}"#)
        #expect(throws: DecodingError.self) {
            try BundledArchive.decode(contentsOf: fixture.zipURL)
        }
    }

    @Test func fileThatIsNotAnArchiveThrowsArchiveError() throws {
        let fixture = try ArchiveFixture(json: nil)
        let notZip = fixture.directory.appendingPathComponent("not.zip")
        try Data("not a zip".utf8).write(to: notZip)
        #expect(throws: Archive.ArchiveError.self) {
            try BundledArchive.decode(contentsOf: notZip)
        }
    }
}
