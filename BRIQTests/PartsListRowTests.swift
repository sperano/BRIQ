//
//  PartsListRowTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@Suite @MainActor struct PartsListRowTests {
    @Test func partsCountDescriptionUsesTheSingularForOne() {
        #expect(PartsListRow.partsCountDescription(1) == "1 part")
    }

    @Test func partsCountDescriptionUsesThePluralForMore() {
        #expect(PartsListRow.partsCountDescription(0) == "0 parts")
        #expect(PartsListRow.partsCountDescription(7) == "7 parts")
    }
}
