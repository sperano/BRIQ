//
//  SortCommands.swift
//  BRIQ-macos
//
//  Created by Éric Spérano on 14/09/25.
//

import SwiftUI

struct SortCommands: View {
    @AppStorage("sortOrder") private var sortOrder: SetListSortOrder = .year

    var body: some View {
        ForEach(SetListSortOrder.allCases, id: \.self) { order in
            Button(order.displayName) {
                sortOrder = order
            }
            .keyboardShortcut(keyboardShortcut(for: order), modifiers: [.command, .option])
        }
    }

    private func keyboardShortcut(for order: SetListSortOrder) -> KeyEquivalent {
        switch order {
        case .year: "y"
        case .number: "n"
        case .name: "m"
        case .partsCount: "p"
        }
    }
}
