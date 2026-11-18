//
//  SetContentTotalsTests.swift
//  BRIQTests
//

import CoreData
import Testing
@testable import BRIQ

@MainActor struct SetContentTotalsTests {
    private let stack = CoreDataStack(inMemory: true)

    /// Saves a set holding one part line and one minifig line per quantity.
    private func makeSet(_ number: String, partQuantities: [Int32], minifigQuantities: [Int32]) throws -> BRIQ.Set {
        let context = stack.viewContext
        let set = BRIQ.Set.create(
            in: context, number: number, isUSNumber: false, name: number,
            year: 2000, imageURL: nil, partsCount: 0, themeID: 0
        )
        for (index, quantity) in partQuantities.enumerated() {
            let part = Part.create(
                in: context,
                number: "\(number)-p\(index)",
                name: "Part",
                material: "Plastic",
                category: 0
            )
            SetPart.create(in: context, part: part, colorID: 0, quantity: quantity).set = set
        }
        for (index, quantity) in minifigQuantities.enumerated() {
            let minifig = Minifig.create(in: context, number: "\(number)-m\(index)", name: "Minifig", partsCount: 0)
            SetMinifig.create(in: context, minifig: minifig, quantity: quantity).set = set
        }
        try context.save()
        return set
    }

    private func totals(of sets: [BRIQ.Set]) async throws -> SetContentTotals {
        try await SetContentTotals.fetch(forSetIDs: sets.map(\.objectID), in: stack.newBackgroundContext())
    }

    @Test func sumsTheQuantitiesOfTheGivenSetsOnly() async throws {
        let first = try makeSet("1-1", partQuantities: [3, 4], minifigQuantities: [1, 2])
        let second = try makeSet("2-1", partQuantities: [10], minifigQuantities: [5])
        _ = try makeSet("3-1", partQuantities: [100], minifigQuantities: [50])

        #expect(try await totals(of: [first]) == SetContentTotals(minifigs: 3, parts: 7))
        #expect(try await totals(of: [first, second]) == SetContentTotals(minifigs: 8, parts: 17))
    }

    @Test func setsWithoutPartsOrMinifigsTotalZero() async throws {
        let empty = try makeSet("4-1", partQuantities: [], minifigQuantities: [])

        #expect(try await totals(of: [empty]) == .zero)
    }

    @Test func noSetsTotalZero() async throws {
        _ = try makeSet("5-1", partQuantities: [2], minifigQuantities: [1])

        #expect(try await totals(of: []) == .zero)
    }
}
