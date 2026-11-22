//
//  SampleData+Extensions.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

#if DEBUG
import BRIQKit
import CoreData
import Foundation

// MARK: - Sample Data Context Helper

@MainActor
class SampleDataHelper {
    static let shared = SampleDataHelper()

    private let provider = SampleDataProvider()

    var context: NSManagedObjectContext {
        provider.viewContext
    }
}

// MARK: - Set Sample Data

@MainActor
extension Set {
    static var sampleData: [Set] {
        let context = SampleDataHelper.shared.context
        let request = Set.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample sets: \(error)")
            return []
        }
    }

    static var sampleSet: Set {
        sampleData.first ?? createFallbackSet()
    }

    private static func createFallbackSet() -> Set {
        let context = SampleDataHelper.shared.context
        return Set.create(
            in: context,
            number: "75301",
            isUSNumber: false,
            name: "Luke Skywalker's X-wing Fighter",
            year: 2021,
            imageURL: "https://images.brickset.com/sets/images/75301-1.jpg",
            partsCount: 474,
            themeID: 158
        )
    }
}

// MARK: - Part Sample Data

@MainActor
extension Part {
    static var sampleData: [Part] {
        let context = SampleDataHelper.shared.context
        let request = Part.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample parts: \(error)")
            return []
        }
    }

    static var samplePart: Part {
        sampleData.first ?? createFallbackPart()
    }

    private static func createFallbackPart() -> Part {
        let context = SampleDataHelper.shared.context
        return Part.create(
            in: context,
            number: "3001",
            name: "Brick 2 x 4",
            material: "ABS",
            category: 11
        )
    }
}

// MARK: - Minifig Sample Data

@MainActor
extension Minifig {
    static var sampleData: [Minifig] {
        let context = SampleDataHelper.shared.context
        let request = Minifig.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample minifigs: \(error)")
            return []
        }
    }

    static var sampleMinifig: Minifig {
        sampleData.first ?? createFallbackMinifig()
    }

    private static func createFallbackMinifig() -> Minifig {
        let context = SampleDataHelper.shared.context
        return Minifig.create(
            in: context,
            number: "sw0527",
            name: "Luke Skywalker (Pilot)",
            partsCount: 8,
            imageURL: "https://img.bricklink.com/ItemImage/MN/0/sw0527.png"
        )
    }
}

// MARK: - SetPart Sample Data

@MainActor
extension SetPart {
    static var sampleData: [SetPart] {
        let context = SampleDataHelper.shared.context
        let request = SetPart.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample setParts: \(error)")
            return []
        }
    }

    static var sampleSetPart: SetPart {
        sampleData.first ?? createFallbackSetPart()
    }

    private static func createFallbackSetPart() -> SetPart {
        let context = SampleDataHelper.shared.context
        let part = Part.samplePart
        let setPart = SetPart.create(
            in: context,
            part: part,
            colorID: 5, // Blue
            quantity: 4,
            imageURL: "https://img.bricklink.com/ItemImage/PN/5/3001.png"
        )
        setPart.set = Set.sampleSet
        return setPart
    }
}

// MARK: - SetMinifig Sample Data

@MainActor
extension SetMinifig {
    static var sampleData: [SetMinifig] {
        let context = SampleDataHelper.shared.context
        let request = SetMinifig.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample setMinifigs: \(error)")
            return []
        }
    }

    static var sampleSetMinifig: SetMinifig {
        sampleData.first ?? createFallbackSetMinifig()
    }

    private static func createFallbackSetMinifig() -> SetMinifig {
        let context = SampleDataHelper.shared.context
        let minifig = Minifig.sampleMinifig
        let setMinifig = SetMinifig.create(
            in: context,
            minifig: minifig,
            quantity: 1
        )
        setMinifig.set = Set.sampleSet
        return setMinifig
    }
}

// MARK: - SetUserData Sample Data

@MainActor
extension SetUserData {
    static var sampleData: [SetUserData] {
        let context = SampleDataHelper.shared.context
        let request = SetUserData.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch sample userData: \(error)")
            return []
        }
    }

    static var sampleUserData: SetUserData {
        sampleData.first ?? createFallbackUserData()
    }

    private static func createFallbackUserData() -> SetUserData {
        let context = SampleDataHelper.shared.context
        let userData = SetUserData.create(
            in: context,
            number: "75301",
            owned: true,
            favorite: true,
            ownsInstructions: true,
            instructionsQuality: 4
        )
        userData.set = Set.sampleSet
        return userData
    }
}

// MARK: - Preview Context Helper

@MainActor
extension NSManagedObjectContext {
    static var preview: NSManagedObjectContext {
        SampleDataHelper.shared.context
    }
}

// MARK: - Theme Sample Data

extension Theme {
    /// Real entries from the auto-generated AllThemes array, so previews
    /// resolve the same theme names as production (indexed by position).
    static var sampleTheme: Theme {
        AllThemes[5] // Star Wars
    }

    static var sampleThemes: [Theme] {
        [AllThemes[5], AllThemes[14]] // Star Wars, City
    }
}
#endif
