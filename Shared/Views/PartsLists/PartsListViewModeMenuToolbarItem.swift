//
//  PartsListViewModeMenuToolbarItem.swift
//  BRIQ
//

import SwiftUI

struct PartsListViewModeMenuToolbarItem: ToolbarContent {
    @Binding var viewMode: PartsListViewMode

    var body: some ToolbarContent {
        ToolbarItem {
            Menu {
                ForEach(PartsListViewMode.allCases, id: \.self) { mode in
                    Button {
                        viewMode = mode
                    } label: {
                        Label(mode.displayName, systemImage: mode.systemImage)
                    }
                }
            } label: {
                Label("View Mode", systemImage: viewMode.systemImage)
            }
            .accessibilityValue(viewMode.displayName)
        }
    }
}
