//
//  GeneratedDataTests.swift
//  BRIQTests
//
//  Production code silently depends on positional lookup into the
//  auto-generated tables (e.g. Set.themeName indexes AllThemes by themeID);
//  these tests make that invariant explicit.
//

import Testing
@testable import BRIQ

@Suite struct GeneratedDataTests {
    @Test func allThemesIDsMatchTheirIndices() {
        #expect(!AllThemes.isEmpty)
        let mismatches = AllThemes.enumerated().filter { $0.element.id != $0.offset }
        #expect(mismatches.isEmpty, "Theme ids diverge from positions at: \(mismatches.map(\.offset).prefix(5))")
    }

    @Test func allPartColorsAreWellFormed() {
        #expect(!AllPartColors.isEmpty)
        let badRGB = AllPartColors.filter { color in
            color.rgb.count != 6 || color.rgb.contains { !$0.isHexDigit }
        }
        #expect(badRGB.isEmpty, "Malformed rgb values: \(badRGB.map(\.name).prefix(5))")
    }
}
