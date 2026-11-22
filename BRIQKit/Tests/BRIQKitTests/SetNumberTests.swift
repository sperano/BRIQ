//
//  SetNumberTests.swift
//  BRIQKitTests
//

import BRIQKit
import Testing

struct SetNumberTests {
    @Test func plainNumber() {
        #expect(SetNumber.sortKey(for: "6080") == 6_080_000)
    }

    @Test func variantSuffix() {
        #expect(SetNumber.sortKey(for: "6080-1") == 6_080_001)
        #expect(SetNumber.sortKey(for: "6080-2") == 6_080_002)
    }

    @Test func plainNumberSortsBeforeItsVariants() {
        #expect(SetNumber.sortKey(for: "6080") < SetNumber.sortKey(for: "6080-1"))
    }

    @Test func numericOrderBeatsStringOrder() {
        // String comparison would put "10030-1" before "605-1"
        #expect(SetNumber.sortKey(for: "605-1") < SetNumber.sortKey(for: "10030-1"))
    }

    @Test func nonNumericBaseFallsBackToZero() {
        #expect(SetNumber.sortKey(for: "K123-1") == 1)
        #expect(SetNumber.sortKey(for: "Build-a-Mini-2025") == 0)
    }

    @Test func oversizedSuffixIsClamped() {
        #expect(SetNumber.sortKey(for: "100-2000") == 100_999)
    }
}
