//
//  BundledData.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import CoreData
import OSLog
import ZIPFoundation

struct JSONPart: Decodable {
    let number: String
    let name: String
    let partCategoryId: Int
    let material: String
}

struct JSONMinifig: Decodable {
    let number: String
    let name: String
    let partsCount: Int
    let imgUrl: String?
}

struct JSONSetMinifig: Decodable {
    let number: String
    let quantity: Int
}

struct JSONSetPart: Decodable {
    let number: String
    let colorId: Int
    let quantity: Int
    let imgUrl: String?
}

struct JSONSet: Decodable {
    let number: String
    let isUsNumber: Bool
    let sameAsNumber: String?
    let name: String
    let year: Int
    let themeId: Int64
    let partsCount: Int
    let imgUrl: String?
    let minifigs: [JSONSetMinifig]
    let parts: [JSONSetPart]
    let isPack: Bool
    let isUnreleased: Bool
    let isAccessories: Bool
}

struct JSONData: Decodable {
    let parts: [JSONPart]
    let minifigs: [JSONMinifig]
    let sets: [JSONSet]
}

enum BundledDataError: LocalizedError {
    case archiveMissing

    var errorDescription: String? {
        switch self {
        case .archiveMissing:
            return "The bundled LEGO database (init.zip) is missing from the app bundle."
        }
    }
}

struct BundledData {
    static let setImportBatchSize = 500

    static func bundledArchiveURL() throws -> URL {
        guard let zipURL = Bundle.main.url(forResource: "init", withExtension: "zip") else {
            throw BundledDataError.archiveMissing
        }
        return zipURL
    }

    /// Imports the archive at `zipURL` into `context`. Throws on any failure
    /// and cooperates with task cancellation between batches, so callers
    /// decide whether the import counts as complete.
    static func loadAll(
        from zipURL: URL,
        into context: NSManagedObjectContext,
        progress: @escaping @MainActor (Int, Double) -> Void
    ) async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let start = DispatchTime.now()

        try fileManager.unzipItem(at: zipURL, to: tempDir)
        let jsonData = try Data(contentsOf: tempDir.appendingPathComponent("init.json"))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(JSONData.self, from: jsonData)

        try Task.checkCancellation()
        let minifigIDs = try await importMinifigs(decoded.minifigs, into: context)

        try Task.checkCancellation()
        let partIDs = try await importParts(decoded.parts, into: context)

        try await importSets(
            decoded.sets,
            into: context,
            minifigIDs: minifigIDs,
            partIDs: partIDs,
            progress: progress
        )

        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
        Logger.dataTransfer.info("loadAll execution time: \(elapsed) seconds")
    }

    /// Returns permanent object IDs rather than objects so the context can be
    /// reset after each save instead of pinning the whole import in memory.
    private static func importMinifigs(
        _ minifigs: [JSONMinifig],
        into context: NSManagedObjectContext
    ) async throws -> [String: NSManagedObjectID] {
        try await context.perform {
            var created = [String: Minifig]()
            for minifig in minifigs {
                created[minifig.number] = Minifig.create(
                    in: context,
                    number: minifig.number,
                    name: minifig.name,
                    partsCount: Int32(minifig.partsCount),
                    imageURL: minifig.imgUrl
                )
            }
            try context.save()
            let ids = created.mapValues(\.objectID)
            context.reset()
            return ids
        }
    }

    private static func importParts(
        _ parts: [JSONPart],
        into context: NSManagedObjectContext
    ) async throws -> [String: NSManagedObjectID] {
        try await context.perform {
            var created = [String: Part]()
            for part in parts {
                created[part.number] = Part.create(
                    in: context,
                    number: part.number,
                    name: part.name,
                    material: part.material,
                    category: Int32(part.partCategoryId)
                )
            }
            try context.save()
            let ids = created.mapValues(\.objectID)
            context.reset()
            return ids
        }
    }

    private static func importSets(
        _ sets: [JSONSet],
        into context: NSManagedObjectContext,
        minifigIDs: [String: NSManagedObjectID],
        partIDs: [String: NSManagedObjectID],
        progress: @escaping @MainActor (Int, Double) -> Void
    ) async throws {
        let total = sets.count
        var imported = 0

        while imported < total {
            try Task.checkCancellation()

            let batch = Array(sets[imported..<min(imported + setImportBatchSize, total)])
            try await context.perform {
                for jsonSet in batch {
                    let newSet = Set.create(
                        in: context,
                        number: jsonSet.number,
                        isUSNumber: jsonSet.isUsNumber,
                        name: jsonSet.name,
                        year: Int32(jsonSet.year),
                        imageURL: jsonSet.imgUrl,
                        partsCount: Int32(jsonSet.partsCount),
                        themeID: Int32(jsonSet.themeId),
                        sameAsNumber: jsonSet.sameAsNumber,
                        isPack: jsonSet.isPack,
                        isUnreleased: jsonSet.isUnreleased,
                        isAccessory: jsonSet.isAccessories
                    )

                    for minifigData in jsonSet.minifigs {
                        guard let objectID = minifigIDs[minifigData.number],
                              let minifig = context.object(with: objectID) as? Minifig else { continue }
                        let setMinifig = SetMinifig.create(
                            in: context,
                            minifig: minifig,
                            quantity: Int32(minifigData.quantity)
                        )
                        setMinifig.set = newSet
                    }

                    for partData in jsonSet.parts {
                        guard let objectID = partIDs[partData.number],
                              let part = context.object(with: objectID) as? Part else { continue }
                        let setPart = SetPart.create(
                            in: context,
                            part: part,
                            colorID: Int32(partData.colorId),
                            quantity: Int32(partData.quantity),
                            imageURL: partData.imgUrl
                        )
                        setPart.set = newSet
                    }
                }
                try context.save()
                context.reset()
            }

            imported += batch.count
            await progress(imported, Double(imported) / Double(total))
        }
    }
}
