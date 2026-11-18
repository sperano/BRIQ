//
//  SampleDataProvider.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

#if DEBUG
import CoreData
import Foundation

class SampleDataProvider {
    static let shared = SampleDataProvider()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BRIQ")

        // Use in-memory store for previews
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Sample data container failed to load: \(error)")
            }
        }

        // Pre-populate with sample data
        populateSampleData(in: container.viewContext)

        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private func populateSampleData(in context: NSManagedObjectContext) {
        // Create sample parts
        let parts = createSampleParts(in: context)

        // Create sample minifigs
        let minifigs = createSampleMinifigs(in: context)

        // Create sample sets
        let sets = createSampleSets(in: context)

        // Create relationships
        createSampleRelationships(sets: sets, parts: parts, minifigs: minifigs, in: context)

        // Save all sample data
        do {
            try context.save()
        } catch {
            fatalError("Failed to save sample data: \(error)")
        }
    }

    private func createSampleParts(in context: NSManagedObjectContext) -> [Part] {
        func part(_ number: String, _ name: String, _ material: String, _ category: Int32) -> Part {
            Part.create(in: context, number: number, name: name, material: material, category: category)
        }

        return [
            part("3001", "Brick 2 x 4", "ABS", 11), // bricks
            part("3024", "Plate 1 x 1", "ABS", 14), // plates
            part("3003", "Brick 2 x 2", "ABS", 11), // bricks
            part("3068b", "Tile 2 x 2", "ABS", 19), // tiles
            part("3023", "Plate 1 x 2", "ABS", 14), // plates
            part("3004", "Brick 1 x 2", "ABS", 11), // bricks
            part("3070b", "Tile 1 x 1", "ABS", 19), // tiles
            part("4073", "Plate Round 1 x 1", "ABS", 21), // plates round
            part("3005", "Brick 1 x 1", "ABS", 11), // bricks
            part("3069b", "Tile 1 x 2", "ABS", 19), // tiles
            part("50950", "Slope Brick Curved 3 x 1", "ABS", 3), // slopes
            part("3665", "Slope Brick 45° 2 x 1 Inverted", "ABS", 3), // slopes
            part("3022", "Plate 2 x 2", "ABS", 14), // plates
            part("87087", "Brick Modified 1 x 1 with Stud on 1 Side", "ABS", 5), // bricks special
            part("6141", "Plate Round 1 x 1 Straight Side", "ABS", 21), // plates round
            part("30374", "Bar 4L (Lightsaber Blade / Wand)", "ABS", 27), // minifig accessories
            part("3626cpb0274", "Minifigure Head Dual Sided", "ABS", 13), // minifigs
            part("973pb0927c01", "Minifigure Torso", "ABS", 13), // minifigs
            part("970c00", "Minifigure Hips and Legs", "ABS", 13), // minifigs
            part("4624", "Wheel 8mm D. x 6mm", "Rubber", 29), // wheels
        ]
    }

    private func createSampleMinifigs(in context: NSManagedObjectContext) -> [Minifig] {
        func minifig(_ number: String, _ name: String, _ partsCount: Int32) -> Minifig {
            Minifig.create(
                in: context,
                number: number,
                name: name,
                partsCount: partsCount,
                imageURL: "https://img.bricklink.com/ItemImage/MN/0/\(number).png"
            )
        }

        return [
            minifig("sw0527", "Luke Skywalker (Pilot)", 8),
            minifig("sw0187", "Princess Leia (White Dress)", 7),
            minifig("cty0013", "Firefighter - Red Fire Helmet", 6),
            minifig("cty0008", "Police Officer - City", 5),
            minifig("con001", "Construction Worker", 6),
            minifig("sw0621", "Imperial Officer", 4),
            minifig("cty0025", "Coast Guard", 5),
            minifig("sw0698", "BB-8", 3),
        ]
    }

    private func createSampleSets(in context: NSManagedObjectContext) -> [Set] {
        // Theme IDs are positions in the auto-generated AllThemes array,
        // matching how production indexes themes (see Set.themeName).
        let starWars: Int32 = 5
        let creator: Int32 = 9
        let city: Int32 = 14
        let architecture: Int32 = 116

        func sampleSet(
            _ number: String,
            _ name: String,
            year: Int32,
            partsCount: Int32,
            themeID: Int32,
            isPack: Bool = false
        ) -> Set {
            let set = Set.create(
                in: context,
                number: number,
                isUSNumber: false,
                name: name,
                year: year,
                imageURL: "https://images.brickset.com/sets/images/\(number)-1.jpg",
                partsCount: partsCount,
                themeID: themeID,
                isPack: isPack
            )
            addRandomUserData(to: set, in: context)
            return set
        }

        return [
            sampleSet("75301", "Luke Skywalker's X-wing Fighter", year: 2021, partsCount: 474, themeID: starWars),
            sampleSet("10267", "Gingerbread House", year: 2019, partsCount: 1477, themeID: creator),
            sampleSet("60320", "Fire Station", year: 2022, partsCount: 540, themeID: city),
            sampleSet("21034", "London", year: 2017, partsCount: 468, themeID: architecture),
            sampleSet("75300", "Imperial TIE Fighter", year: 2021, partsCount: 432, themeID: starWars),
            sampleSet("60319", "Fire Rescue Helicopter", year: 2022, partsCount: 212, themeID: city),
            sampleSet("31120", "Medieval Castle", year: 2021, partsCount: 1426, themeID: creator),
            sampleSet("75299", "Trouble on Tatooine", year: 2020, partsCount: 277, themeID: starWars),
            sampleSet("21058", "Great Pyramid of Giza", year: 2022, partsCount: 1476, themeID: architecture),
            sampleSet("60321", "Fire Rescue Team", year: 2022, partsCount: 177, themeID: city),
            sampleSet("75302", "Imperial Shuttle", year: 2021, partsCount: 660, themeID: starWars),
            sampleSet(
                "30624",
                "Obi-Wan Kenobi Minifigure",
                year: 2022,
                partsCount: 31,
                themeID: starWars,
                isPack: true
            ),
        ]
    }

    /// Gives some sets sample user data.
    private func addRandomUserData(to set: Set, in context: NSManagedObjectContext) {
        guard Bool.random() else { return }
        let userData = SetUserData.create(
            in: context,
            number: set.number,
            owned: Bool.random(),
            favorite: Bool.random(),
            ownsInstructions: Bool.random(),
            instructionsQuality: Int32.random(in: 1...5)
        )
        set.userData = userData
        userData.set = set
    }

    private func createSampleRelationships(
        sets: [Set],
        parts: [Part],
        minifigs: [Minifig],
        in context: NSManagedObjectContext
    ) {
        // Create sample SetPart relationships
        for set in sets {
            let numParts = Int.random(in: 3...8)
            let selectedParts = parts.shuffled().prefix(numParts)

            for part in selectedParts {
                let setPart = SetPart.create(
                    in: context,
                    part: part,
                    colorID: Int32.random(in: 0...100), // Random color ID
                    quantity: Int32.random(in: 1...10),
                    imageURL: "https://img.bricklink.com/ItemImage/PN/\(Int.random(in: 0...100))/\(part.number).png"
                )
                setPart.set = set

                // Add to set's parts relationship
                let currentParts = set.parts?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
                currentParts.add(setPart)
                set.parts = currentParts
            }
        }

        // Create sample SetMinifig relationships; not all sets have minifigs
        for set in sets where Bool.random() {
            let numMinifigs = Int.random(in: 1...3)
            let selectedMinifigs = minifigs.shuffled().prefix(numMinifigs)

            for minifig in selectedMinifigs {
                let setMinifig = SetMinifig.create(
                    in: context,
                    minifig: minifig,
                    quantity: Int32.random(in: 1...2)
                )
                setMinifig.set = set

                // Add to set's minifigs relationship
                let currentMinifigs = set.minifigs?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
                currentMinifigs.add(setMinifig)
                set.minifigs = currentMinifigs
            }
        }
    }
}
#endif
