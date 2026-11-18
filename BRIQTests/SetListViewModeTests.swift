//
//  SetListViewModeTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@MainActor
struct SetListViewModeTests {
    /// The test target runs on macOS.
    @Test func currentPlatformIsMacOS() {
        #expect(SetListViewMode.availableCases == [.icon, .split, .table])
        #expect(SetListViewMode.list.availableOrDefault == .icon)
    }

    @Test func macOSOffersIconSplitAndTableInMenuOrder() {
        #expect(SetListViewMode.availableCases(macOS: true) == [.icon, .split, .table])
    }

    @Test func iOSOffersIconAndListInMenuOrder() {
        #expect(SetListViewMode.availableCases(macOS: false) == [.icon, .list])
    }

    @Test func storedRawValuesKeepTheirMeaning() {
        #expect(SetListViewMode(rawValue: 0) == .icon)
        #expect(SetListViewMode(rawValue: 1) == .split)
        #expect(SetListViewMode(rawValue: 2) == .table)
        #expect(SetListViewMode(rawValue: 3) == .list)
    }

    @Test func modesMacOSOffersAreKeptOnMacOS() {
        for mode in [SetListViewMode.icon, .split, .table] {
            #expect(mode.availableOrDefault(macOS: true) == mode)
        }
    }

    @Test func listFallsBackToIconOnMacOS() {
        #expect(SetListViewMode.list.availableOrDefault(macOS: true) == .icon)
    }

    @Test func modesIOSOffersAreKeptOnIOS() {
        for mode in [SetListViewMode.icon, .list] {
            #expect(mode.availableOrDefault(macOS: false) == mode)
        }
    }

    @Test func menuCommandsNameTheirMode() {
        #expect(SetListViewMode.icon.commandTitle == "Icon View")
        #expect(SetListViewMode.split.commandTitle == "Split View")
        #expect(SetListViewMode.table.commandTitle == "Table View")
        #expect(SetListViewMode.list.commandTitle == "List View")
    }

    /// iOS builds stored their old `list` mode as 1, which now reads back
    /// as `split`.
    @Test func oldIOSListValueFallsBackToIconOnIOS() {
        let stored = SetListViewMode(rawValue: 1)
        #expect(stored?.availableOrDefault(macOS: false) == .icon)
        #expect(SetListViewMode.table.availableOrDefault(macOS: false) == .icon)
    }
}
