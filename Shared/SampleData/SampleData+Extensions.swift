//
//  SampleData+Extensions.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

#if DEBUG
import Foundation
import CoreData

// MARK: - Sample Data Context Helper
@MainActor
class SampleDataHelper {
    static let shared = SampleDataHelper()

    private let provider = SampleDataProvider()

    var context: NSManagedObjectContext {
        return provider.viewContext
    }
}

// MARK: - Set Sample Data
extension Set {
    @MainActor
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

    @MainActor
    static var sampleSet: Set {
        return sampleData.first ?? createFallbackSet()
    }

    @MainActor
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
extension Part {
    @MainActor
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

    @MainActor
    static var samplePart: Part {
        return sampleData.first ?? createFallbackPart()
    }

    @MainActor
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
extension Minifig {
    @MainActor
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

    @MainActor
    static var sampleMinifig: Minifig {
        return sampleData.first ?? createFallbackMinifig()
    }

    @MainActor
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
extension SetPart {
    @MainActor
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

    @MainActor
    static var sampleSetPart: SetPart {
        return sampleData.first ?? createFallbackSetPart()
    }

    @MainActor
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
extension SetMinifig {
    @MainActor
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

    @MainActor
    static var sampleSetMinifig: SetMinifig {
        return sampleData.first ?? createFallbackSetMinifig()
    }

    @MainActor
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
extension SetUserData {
    @MainActor
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

    @MainActor
    static var sampleUserData: SetUserData {
        return sampleData.first ?? createFallbackUserData()
    }

    @MainActor
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
extension NSManagedObjectContext {
    @MainActor
    static var preview: NSManagedObjectContext {
        return SampleDataHelper.shared.context
    }
}

// MARK: - Theme Sample Data
extension Theme {
    static var sampleTheme: Theme {
        return PreviewAllThemes.first ?? Theme(id: 158, name: "Star Wars")
    }

    static var sampleThemes: [Theme] {
        return PreviewAllThemes.isEmpty ? [Theme(id: 158, name: "Star Wars"), Theme(id: 52, name: "City")] : PreviewAllThemes
    }
}
#endif