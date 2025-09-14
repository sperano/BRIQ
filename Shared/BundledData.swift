//
//  BundledData.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import CoreData
import ZIPFoundation

struct JSONPart: Decodable {
    let number: String
    let name: String
    let part_category_id: Int
    let material: String
}

struct JSONMinifig: Decodable {
    let number: String
    let name: String
    let parts_count: Int
    let img_url: String?
}

struct JSONSetMinifig: Decodable {
    let number: String
    let quantity: Int
}

struct JSONSetPart: Decodable {
    let number: String
    let color_id: Int
    let quantity: Int
    let img_url: String?
}

struct JSONSet: Decodable {
    let number: String
    let is_us_number: Bool
    let same_as_number: String?
    let name: String
    let year: Int
    let theme_id: Int64
    let parts_count: Int
    let img_url: String?
    let minifigs: [JSONSetMinifig]
    let parts: [JSONSetPart]
    let is_pack: Bool
    let is_unreleased: Bool
    let is_accessories: Bool
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
            partsCount: Int32(minifig.parts_count),
            imageURL: minifig.img_url
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
            category: Int32(part.part_category_id)
        )
        parts[p.number] = p
    }
    return parts
}

struct BundledData {
    static func loadAll(coreDataStack: CoreDataStack, progress: @escaping (Int, Double) async -> Void) async {
        // Create background context for heavy data operations
        let backgroundContext = coreDataStack.newBackgroundContext()
        let batch_size = 1250  // Increased batch size
        let progress_interval = 100  // Update UI less frequently
        let fileManager = FileManager.default
        if let zipURL = Bundle.main.url(forResource: "init", withExtension: "zip") {
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            do {
                let start = DispatchTime.now()
                
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try fileManager.unzipItem(at: zipURL, to: tempDir)
                let jsonData = try Data(contentsOf: tempDir.appendingPathComponent("init.json"))
                let decoded = try JSONDecoder().decode(JSONData.self, from: jsonData)
                
                let minifigs = loadMinifigs(backgroundContext, data: decoded)
                try await coreDataStack.saveBackgroundContext(backgroundContext)

                let parts = loadParts(backgroundContext, data: decoded)
                try await coreDataStack.saveBackgroundContext(backgroundContext)

                let total = Double(decoded.sets.count)
                var i = 1
                var j = 0
                
                // Pre-allocate arrays for batch processing
                var setsBatch = [Set]()
                setsBatch.reserveCapacity(batch_size)
                
                for set in decoded.sets {
                    // Create the set entity
                    let newSet = Set.create(
                        in: backgroundContext,
                        number: set.number,
                        isUSNumber: set.is_us_number,
                        name: set.name,
                        year: Int32(set.year),
                        imageURL: set.img_url,
                        partsCount: Int32(set.parts_count),
                        themeID: Int32(set.theme_id),
                        sameAsNumber: set.same_as_number,
                        isPack: set.is_pack,
                        isUnreleased: set.is_unreleased,
                        isAccessory: set.is_accessories
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
                                colorID: Int32(partData.color_id),
                                quantity: Int32(partData.quantity),
                                imageURL: partData.img_url
                            )
                            setPart.set = newSet
                        }
                    }

                    // Update progress less frequently
                    if i % progress_interval == 0 {
                        let ix = i
                        await progress(ix, Double(ix)/total)
                    }

                    j += 1

                    if j == batch_size {
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
                print("loadAll execution time: \(timeInterval) seconds")
                
                // Clean up temp directory
                try? fileManager.removeItem(at: tempDir)
            } catch {
                print("Error: \(error)")
            }
        } else {
            print("Could not find init.zip in the bundle")
        }
    }
}
