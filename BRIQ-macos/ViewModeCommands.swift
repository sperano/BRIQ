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
            ForEach(SetListViewMode.allCases, id: \.self) { mode in
                Button(mode.displayName + " View") {
                    viewMode = mode
                }
                .keyboardShortcut(keyboardShortcut(for: mode), modifiers: .command)
            }
        }
    }
    
    private func keyboardShortcut(for mode: SetListViewMode) -> KeyEquivalent {
        switch mode {
        case .icon: return "1"
        case .split: return "2"
        case .table: return "3"
        }
    }
}
