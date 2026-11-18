//
//  IconGridViewTests.swift
//  BRIQTests
//

import SwiftUI
import Testing
@testable import BRIQ

@Suite @MainActor struct IconGridViewTests {
    @Test func itemDescriptionReadsTheNameNumberAndQuantity() {
        let label = IconGridView<SetPart, EmptyView>.itemDescription(quantity: 4, number: "3001", name: "Brick 2 x 4")

        #expect(label == "Brick 2 x 4, 3001, quantity 4")
    }
}
