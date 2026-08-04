//
//  SetEntityTests.swift
//  BRIQTests
//

import Testing
import CoreData
@testable import BRIQ

@Suite struct SortKeyTests {
    @Test func plainNumber() {
        #expect(Set.sortKey(forNumber: "6080") == 6_080_000)
    }

    @Test func variantSuffix() {
        #expect(Set.sortKey(forNumber: "6080-1") == 6_080_001)
        #expect(Set.sortKey(forNumber: "6080-2") == 6_080_002)
    }

    @Test func plainNumberSortsBeforeItsVariants() {
        #expect(Set.sortKey(forNumber: "6080") < Set.sortKey(forNumber: "6080-1"))
    }

    @Test func numericOrderBeatsStringOrder() {
        // String comparison would put "10030-1" before "605-1"
        #expect(Set.sortKey(forNumber: "605-1") < Set.sortKey(forNumber: "10030-1"))
    }

    @Test func nonNumericBaseFallsBackToZero() {
        #expect(Set.sortKey(forNumber: "K123-1") == 1)
        #expect(Set.sortKey(forNumber: "Build-a-Mini-2025") == 0)
    }

    @Test func oversizedSuffixIsClamped() {
        #expect(Set.sortKey(forNumber: "100-2000") == 100_999)
    }
}

@Suite @MainActor struct SetComputedPropertyTests {
    let stack = CoreDataStack(inMemory: true)

    @Test func baseNumberStripsVariantSuffix() {
        let context = stack.viewContext
        let set = Set.create(
            in: context, number: "6080-1", isUSNumber: false, name: "King's Castle",
            year: 1984, imageURL: nil, partsCount: 664, themeID: 0
        )
        #expect(set.baseNumber == "6080")
        #expect(set.sortKey == 6_080_001)
    }

    @Test func countsSumQuantities() {
        let context = stack.viewContext
        let set = Set.create(
            in: context, number: "100-1", isUSNumber: false, name: "Test",
            year: 2000, imageURL: nil, partsCount: 6, themeID: 0
        )
        let part = Part.create(in: context, number: "3001", name: "Brick", material: "Plastic", category: 1)
        let minifig = Minifig.create(in: context, number: "fig-1", name: "Fig", partsCount: 3, imageURL: nil)

        let setPart = SetPart.create(in: context, part: part, colorID: 1, quantity: 4, imageURL: nil)
        setPart.set = set
        let setMinifig = SetMinifig.create(in: context, minifig: minifig, quantity: 2)
        setMinifig.set = set

        #expect(set.actualPartsCount == 4)
        #expect(set.minifigsCount == 2)
    }

    @Test func comparatorOrdersByYearThenNumber() {
        let context = stack.viewContext
        let older = Set.create(
            in: context, number: "900-1", isUSNumber: false, name: "Older",
            year: 1980, imageURL: nil, partsCount: 0, themeID: 0
        )
        let newer = Set.create(
            in: context, number: "100-1", isUSNumber: false, name: "Newer",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 0
        )
        #expect(older < newer)
    }
}
