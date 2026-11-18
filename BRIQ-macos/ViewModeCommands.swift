//
//  ViewModeCommands.swift
//  MacBRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import SwiftUI

struct ViewModeCommands: View {
    @AppStorage("viewMode") private var viewMode: SetListViewMode = .icon

    var body: some View {
        Group {
            ForEach(Array(SetListViewMode.availableCases.enumerated()), id: \.element) { index, mode in
                Button(mode.commandTitle) {
                    viewMode = mode
                }
                .keyboardShortcut(Self.keyboardShortcut(forPosition: index), modifiers: .command)
            }
        }
    }

    /// ⌘1, ⌘2, ... in menu order.
    private static func keyboardShortcut(forPosition index: Int) -> KeyEquivalent {
        KeyEquivalent(Character(String(index + 1)))
    }
}
