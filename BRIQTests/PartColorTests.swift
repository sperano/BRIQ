//
//  PartColorTests.swift
//  BRIQTests
//

import BRIQKit
import Testing
@testable import BRIQ

@MainActor
struct PartColorTests {
    @Test func lookupReturnsTheColorAtThatIndex() {
        #expect(PartColor.lookup(id: 0) === AllPartColors[0])
        #expect(PartColor.lookup(id: 5) === AllPartColors[5])
        #expect(PartColor.lookup(id: Int32(AllPartColors.count - 1)) === AllPartColors[AllPartColors.count - 1])
    }

    @Test func lookupPastTheLastColorReturnsUnknown() {
        #expect(PartColor.lookup(id: Int32(AllPartColors.count)) === PartColor.unknown)
    }

    @Test func lookupOfANegativeIDReturnsUnknown() {
        #expect(PartColor.lookup(id: -1) === PartColor.unknown)
    }

    @Test func unknownIsNamedUnknown() {
        #expect(PartColor.unknown.name == "Unknown")
        #expect(PartColor.unknown.rgb == "000000")
    }
}
