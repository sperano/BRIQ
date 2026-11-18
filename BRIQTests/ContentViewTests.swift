//
//  ContentViewTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@MainActor struct ContentViewTests {
    @Test func importProgressUsesTheSingularForOneSet() {
        #expect(ContentView.importProgress(setsImported: 1) == "1 set imported.")
    }

    @Test func importProgressUsesThePluralForMoreSets() {
        #expect(ContentView.importProgress(setsImported: 500) == "500 sets imported.")
    }
}
