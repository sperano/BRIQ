//
//  BundledData.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import SwiftData
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

func loadMinifigs(_ backgroundContext: ModelContext, data: JSONData) -> [String: Minifig] {
    var minifigs = [String: Minifig]()
    for minifig in data.minifigs {
        let minif = Minifig(number: minifig.number, name: minifig.name, partsCount: minifig.parts_count, imageURL: minifig.img_url)
        backgroundContext.insert(minif)
        minifigs[minif.number] = minif
    }
    return minifigs
}

func loadParts(_ backgroundContext: ModelContext, data: JSONData) -> [String: Part] {
    var parts = [String: Part]()
    for part in data.parts {
        let p = Part(number: part.number, name: part.name, material: part.material, category: part.part_category_id)
        backgroundContext.insert(p)
        parts[p.number] = p
    }
    return parts
}

struct BundledData {
    static func loadAll(modelContainer: ModelContainer, progress: @escaping (Int, Double) async -> Void) async {
        // Create background context for heavy data operations
        let backgroundContext = ModelContext(modelContainer)
        let batch_size = 500  // Increased batch size
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
                try? backgroundContext.save()

                let parts = loadParts(backgroundContext, data: decoded)
                try? backgroundContext.save()

                let total = Double(decoded.sets.count)
                var i = 1
                var j = 0
                
                // Pre-allocate arrays for batch processing
                var setsBatch = [Set]()
                setsBatch.reserveCapacity(batch_size)
                
                for set in decoded.sets {
                    // Pre-allocate collections
                    var setMinifigs = [SetMinifig]()
                    setMinifigs.reserveCapacity(set.minifigs.count)
                    for minifigData in set.minifigs {
                        if let minifig = minifigs[minifigData.number] {
                            setMinifigs.append(SetMinifig(minifig: minifig, quantity: minifigData.quantity))
                        }
                    }
                    
                    var setParts = [SetPart]()
                    setParts.reserveCapacity(set.parts.count)
                    for partData in set.parts {
                        if let part = parts[partData.number] {
                            setParts.append(SetPart(part: part, colorID: partData.color_id, quantity: partData.quantity, imageURL: partData.img_url))
                        }
                    }
                    
                    let newSet = Set(
                        number: set.number,
                        isUSNumber: set.is_us_number,
                        name: set.name,
                        year: set.year,
                        imageURL: set.img_url,
                        partsCount: set.parts_count,
                        themeID: Int(set.theme_id),
                        minifigs: setMinifigs,
                        parts: setParts,
                        sameAsNumber: set.same_as_number,
                        isPack: set.is_pack,
                        isUnreleased: set.is_unreleased,
                        isAccessory: set.is_accessories
                    )
                    
                    // Update progress less frequently
                    if i % progress_interval == 0 {
                        let ix = i
                        await progress(ix, Double(ix)/total)
                    }
                    
                    backgroundContext.insert(newSet)
                    j += 1
                    
                    if j == batch_size {
                        try? backgroundContext.save()
                        j = 0
                    }
                    i += 1
                }
                
                // Save any remaining items
                if j > 0 {
                    try? backgroundContext.save()
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
