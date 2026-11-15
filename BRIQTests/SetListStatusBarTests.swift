//
//  SetListStatusBarTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@Suite @MainActor struct SetListStatusBarTests {
    @Test func showsOnlyTheSetCountUntilTheTotalsAreKnown() {
        #expect(SetListStatusBar.summary(setCount: 12, totals: nil) == "12 sets")
    }

    @Test func listsTheTotalsOnceKnown() {
        let totals = SetContentTotals(minifigs: 4, parts: 250)

        #expect(SetListStatusBar.summary(setCount: 12, totals: totals) == "12 sets, 4 minifigs and 250 parts")
    }

    @Test func usesTheSingularForOne() {
        let totals = SetContentTotals(minifigs: 1, parts: 1)

        #expect(SetListStatusBar.summary(setCount: 1, totals: totals) == "1 set, 1 minifig and 1 part")
    }

    @Test func usesThePluralForZero() {
        #expect(SetListStatusBar.summary(setCount: 0, totals: .zero) == "0 sets, 0 minifigs and 0 parts")
    }
}
