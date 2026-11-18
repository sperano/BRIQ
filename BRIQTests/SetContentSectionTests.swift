//
//  SetContentSectionTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@MainActor struct SetContentSectionTests {
    @Test func minifigsHeadingUsesTheSingularForOne() {
        #expect(SetContentSection.minifigsHeading(count: 1) == "1 mini-figurine:")
    }

    @Test func minifigsHeadingUsesThePluralForMore() {
        #expect(SetContentSection.minifigsHeading(count: 3) == "3 mini-figurines:")
    }

    @Test func partsHeadingUsesTheSingularForOne() {
        #expect(SetContentSection.partsHeading(count: 1) == "1 part:")
    }

    @Test func partsHeadingUsesThePluralForMore() {
        #expect(SetContentSection.partsHeading(count: 250) == "250 parts:")
    }
}
