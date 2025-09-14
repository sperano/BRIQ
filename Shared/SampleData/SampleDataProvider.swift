//
//  SampleDataProvider.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

#if DEBUG
import Foundation
import CoreData

class SampleDataProvider {
    static let shared = SampleDataProvider()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BRIQ")

        // Use in-memory store for previews
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Sample data container failed to load: \(error)")
            }
        }

        // Pre-populate with sample data
        populateSampleData(in: container.viewContext)

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private func populateSampleData(in context: NSManagedObjectContext) {
        // Create sample themes first (needed for sets)
        initSampleThemes()

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

    private func initSampleThemes() {
        // Initialize sample themes for theme system
        if PreviewAllThemes.isEmpty {
            // Create basic sample themes
            let starWars = Theme(id: 158, name: "Star Wars")
            let city = Theme(id: 52, name: "City")
            let creator = Theme(id: 22, name: "Creator")
            let architecture = Theme(id: 252, name: "Architecture")

            PreviewAllThemes = [starWars, city, creator, architecture]
            PreviewThemesTree = [starWars, city, creator, architecture]
        }
    }

    private func createSampleParts(in context: NSManagedObjectContext) -> [Part] {
        let partsData: [(String, String, String, Int32)] = [
            ("3001", "Brick 2 x 4", "ABS", 11), // bricks
            ("3024", "Plate 1 x 1", "ABS", 14), // plates
            ("3003", "Brick 2 x 2", "ABS", 11), // bricks
            ("3068b", "Tile 2 x 2", "ABS", 19), // tiles
            ("3023", "Plate 1 x 2", "ABS", 14), // plates
            ("3004", "Brick 1 x 2", "ABS", 11), // bricks
            ("3070b", "Tile 1 x 1", "ABS", 19), // tiles
            ("4073", "Plate Round 1 x 1", "ABS", 21), // plates round
            ("3005", "Brick 1 x 1", "ABS", 11), // bricks
            ("3069b", "Tile 1 x 2", "ABS", 19), // tiles
            ("50950", "Slope Brick Curved 3 x 1", "ABS", 3), // slopes
            ("3665", "Slope Brick 45° 2 x 1 Inverted", "ABS", 3), // slopes
            ("3022", "Plate 2 x 2", "ABS", 14), // plates
            ("87087", "Brick Modified 1 x 1 with Stud on 1 Side", "ABS", 5), // bricks special
            ("6141", "Plate Round 1 x 1 Straight Side", "ABS", 21), // plates round
            ("30374", "Bar 4L (Lightsaber Blade / Wand)", "ABS", 27), // minifig accessories
            ("3626cpb0274", "Minifigure Head Dual Sided", "ABS", 13), // minifigs
            ("973pb0927c01", "Minifigure Torso", "ABS", 13), // minifigs
            ("970c00", "Minifigure Hips and Legs", "ABS", 13), // minifigs
            ("4624", "Wheel 8mm D. x 6mm", "Rubber", 29), // wheels
        ]

        return partsData.map { data in
            Part.create(
                in: context,
                number: data.0,
                name: data.1,
                material: data.2,
                category: data.3
            )
        }
    }

    private func createSampleMinifigs(in context: NSManagedObjectContext) -> [Minifig] {
        let minifigsData: [(String, String, Int32, String?)] = [
            ("sw0527", "Luke Skywalker (Pilot)", 8, "https://img.bricklink.com/ItemImage/MN/0/sw0527.png"),
            ("sw0187", "Princess Leia (White Dress)", 7, "https://img.bricklink.com/ItemImage/MN/0/sw0187.png"),
            ("cty0013", "Firefighter - Red Fire Helmet", 6, "https://img.bricklink.com/ItemImage/MN/0/cty0013.png"),
            ("cty0008", "Police Officer - City", 5, "https://img.bricklink.com/ItemImage/MN/0/cty0008.png"),
            ("con001", "Construction Worker", 6, "https://img.bricklink.com/ItemImage/MN/0/con001.png"),
            ("sw0621", "Imperial Officer", 4, "https://img.bricklink.com/ItemImage/MN/0/sw0621.png"),
            ("cty0025", "Coast Guard", 5, "https://img.bricklink.com/ItemImage/MN/0/cty0025.png"),
            ("sw0698", "BB-8", 3, "https://img.bricklink.com/ItemImage/MN/0/sw0698.png"),
        ]

        return minifigsData.map { data in
            Minifig.create(
                in: context,
                number: data.0,
                name: data.1,
                partsCount: data.2,
                imageURL: data.3
            )
        }
    }

    private func createSampleSets(in context: NSManagedObjectContext) -> [Set] {
        let setsData: [(String, Bool, String, Int32, String?, Int32, Int32, String?, Bool, Bool, Bool)] = [
            // (number, isUSNumber, name, year, imageURL, partsCount, themeID, sameAsNumber, isPack, isUnreleased, isAccessory)
            ("75301", false, "Luke Skywalker's X-wing Fighter", 2021, "https://images.brickset.com/sets/images/75301-1.jpg", 474, 158, nil, false, false, false),
            ("10267", false, "Gingerbread House", 2019, "https://images.brickset.com/sets/images/10267-1.jpg", 1477, 22, nil, false, false, false),
            ("60320", false, "Fire Station", 2022, "https://images.brickset.com/sets/images/60320-1.jpg", 540, 52, nil, false, false, false),
            ("21034", false, "London", 2017, "https://images.brickset.com/sets/images/21034-1.jpg", 468, 252, nil, false, false, false),
            ("75300", false, "Imperial TIE Fighter", 2021, "https://images.brickset.com/sets/images/75300-1.jpg", 432, 158, nil, false, false, false),
            ("60319", false, "Fire Rescue Helicopter", 2022, "https://images.brickset.com/sets/images/60319-1.jpg", 212, 52, nil, false, false, false),
            ("31120", false, "Medieval Castle", 2021, "https://images.brickset.com/sets/images/31120-1.jpg", 1426, 22, nil, false, false, false),
            ("75299", false, "Trouble on Tatooine", 2020, "https://images.brickset.com/sets/images/75299-1.jpg", 277, 158, nil, false, false, false),
            ("21058", false, "Great Pyramid of Giza", 2022, "https://images.brickset.com/sets/images/21058-1.jpg", 1476, 252, nil, false, false, false),
            ("60321", false, "Fire Rescue Team", 2022, "https://images.brickset.com/sets/images/60321-1.jpg", 177, 52, nil, false, false, false),
            ("75302", false, "Imperial Shuttle", 2021, "https://images.brickset.com/sets/images/75302-1.jpg", 660, 158, nil, false, false, false),
            ("30624", false, "Obi-Wan Kenobi Minifigure", 2022, "https://images.brickset.com/sets/images/30624-1.jpg", 31, 158, nil, true, false, false), // Package
        ]

        return setsData.map { data in
            let set = Set.create(
                in: context,
                number: data.0,
                isUSNumber: data.1,
                name: data.2,
                year: data.3,
                imageURL: data.4,
                partsCount: data.5,
                themeID: data.6,
                sameAsNumber: data.7,
                isPack: data.8,
                isUnreleased: data.9,
                isAccessory: data.10
            )

            // Add sample user data for some sets
            if Bool.random() {
                let userData = SetUserData.create(
                    in: context,
                    number: data.0,
                    owned: Bool.random(),
                    favorite: Bool.random(),
                    ownsInstructions: Bool.random(),
                    instructionsQuality: Int32.random(in: 1...5)
                )
                set.userData = userData
                userData.set = set
            }

            return set
        }
    }

    private func createSampleRelationships(sets: [Set], parts: [Part], minifigs: [Minifig], in context: NSManagedObjectContext) {
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

        // Create sample SetMinifig relationships
        for set in sets {
            if Bool.random() { // Not all sets have minifigs
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
}

// Global sample themes for preview use
var PreviewAllThemes: [Theme] = []
var PreviewThemesTree: [Theme] = []
#endif
