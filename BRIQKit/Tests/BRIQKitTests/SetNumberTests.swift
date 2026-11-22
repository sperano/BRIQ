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

    @Test func suffixBelowRangeIsExact() {
        #expect(SetNumber.sortKey(for: "100-999") == 100_999)
    }

    @Test func suffixAtAndAboveRangeClampToTheSameKey() {
        #expect(SetNumber.sortKey(for: "100-1000") == 100_999)
        #expect(SetNumber.sortKey(for: "100-1001") == 100_999)
    }

    @Test func emptyStringFallsBackToZero() {
        #expect(SetNumber.sortKey(for: "") == 0)
    }

    @Test func extraDashesIgnoreEverythingAfterTheFirstSuffix() {
        #expect(SetNumber.sortKey(for: "100-1-2") == 100_001)
    }

    @Test func nonNumericSuffixFallsBackToZero() {
        #expect(SetNumber.sortKey(for: "100-x") == 100_000)
    }

    @Test func sortingByKeyMatchesNumericThenVariantOrder() {
        let numbers = ["10030-1", "605-1", "605", "605-2", "100-999", "100-1000"]
        let expected = ["100-999", "100-1000", "605", "605-1", "605-2", "10030-1"]
        #expect(numbers.sorted { SetNumber.sortKey(for: $0) < SetNumber.sortKey(for: $1) } == expected)
    }
}
