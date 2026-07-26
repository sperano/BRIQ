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

func loadMinifigs(_ context: NSManagedObjectContext, data: JSONData) -> [String: Minifig] {
    var minifigs = [String: Minifig]()
    for minifig in data.minifigs {
        let minif = Minifig.create(
            in: context,
            number: minifig.number,
            name: minifig.name,
            partsCount: Int32(minifig.partsCount),
            imageURL: minifig.imgUrl
        )
        minifigs[minif.number] = minif
    }
    return minifigs
}

func loadParts(_ context: NSManagedObjectContext, data: JSONData) -> [String: Part] {
    var parts = [String: Part]()
    for part in data.parts {
        let p = Part.create(
            in: context,
            number: part.number,
            name: part.name,
            material: part.material,
            category: Int32(part.partCategoryId)
        )
        parts[p.number] = p
    }
    return parts
}

struct BundledData {
    static func loadAll(coreDataStack: CoreDataStack, progress: @escaping (Int, Double) async -> Void) async {
        // Create background context for heavy data operations
        let backgroundContext = coreDataStack.newBackgroundContext()
        let batchSize = 1250
        let progressInterval = 100  // Update UI less frequently
        let fileManager = FileManager.default
        if let zipURL = Bundle.main.url(forResource: "init", withExtension: "zip") {
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            do {
                let start = DispatchTime.now()

                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try fileManager.unzipItem(at: zipURL, to: tempDir)
                let jsonData = try Data(contentsOf: tempDir.appendingPathComponent("init.json"))
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decoded = try decoder.decode(JSONData.self, from: jsonData)

                let minifigs = loadMinifigs(backgroundContext, data: decoded)
                try await coreDataStack.saveBackgroundContext(backgroundContext)

                let parts = loadParts(backgroundContext, data: decoded)
                try await coreDataStack.saveBackgroundContext(backgroundContext)

                let total = Double(decoded.sets.count)
                var i = 1
                var j = 0

                for set in decoded.sets {
                    // Create the set entity
                    let newSet = Set.create(
                        in: backgroundContext,
                        number: set.number,
                        isUSNumber: set.isUsNumber,
                        name: set.name,
                        year: Int32(set.year),
                        imageURL: set.imgUrl,
                        partsCount: Int32(set.partsCount),
                        themeID: Int32(set.themeId),
                        sameAsNumber: set.sameAsNumber,
                        isPack: set.isPack,
                        isUnreleased: set.isUnreleased,
                        isAccessory: set.isAccessories
                    )

                    // Add minifigs to set
                    for minifigData in set.minifigs {
                        if let minifig = minifigs[minifigData.number] {
                            let setMinifig = SetMinifig.create(
                                in: backgroundContext,
                                minifig: minifig,
                                quantity: Int32(minifigData.quantity)
                            )
                            setMinifig.set = newSet
                        }
                    }

                    // Add parts to set
                    for partData in set.parts {
                        if let part = parts[partData.number] {
                            let setPart = SetPart.create(
                                in: backgroundContext,
                                part: part,
                                colorID: Int32(partData.colorId),
                                quantity: Int32(partData.quantity),
                                imageURL: partData.imgUrl
                            )
                            setPart.set = newSet
                        }
                    }

                    // Update progress less frequently
                    if i % progressInterval == 0 {
                        let ix = i
                        await progress(ix, Double(ix)/total)
                    }

                    j += 1

                    if j == batchSize {
                        try await coreDataStack.saveBackgroundContext(backgroundContext)
                        j = 0
                    }
                    i += 1
                }

                // Save any remaining items
                if j > 0 {
                    try await coreDataStack.saveBackgroundContext(backgroundContext)
                }

                await progress(decoded.sets.count, 1.0)
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000  // seconds
                Logger.dataTransfer.info("loadAll execution time: \(timeInterval) seconds")

                // Clean up temp directory
                try? fileManager.removeItem(at: tempDir)
            } catch {
                Logger.dataTransfer.error("Failed to load bundled data: \(error)")
            }
        } else {
            Logger.dataTransfer.error("Could not find init.zip in the bundle")
        }
    }
}
