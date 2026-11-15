//
//  SetListViewModeTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

/// The test target runs on macOS, so these cover the macOS side of the
/// shared enum.
@MainActor
struct SetListViewModeTests {
    @Test func macOSOffersIconSplitAndTableInMenuOrder() {
        #expect(SetListViewMode.availableCases == [.icon, .split, .table])
    }

    @Test func storedMacOSRawValuesKeepTheirMeaning() {
        #expect(SetListViewMode(rawValue: 0) == .icon)
        #expect(SetListViewMode(rawValue: 1) == .split)
        #expect(SetListViewMode(rawValue: 2) == .table)
    }

    @Test func offeredModesAreKept() {
        for mode in [SetListViewMode.icon, .split, .table] {
            #expect(mode.availableOrDefault == mode)
        }
    }

    @Test func listFallsBackToIconOnMacOS() {
        #expect(SetListViewMode.list.availableOrDefault == .icon)
    }
}
