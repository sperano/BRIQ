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
                    Button(action: {
                        viewMode = mode
                    }) {
                        Label(mode.displayName, systemImage: mode.systemImage)
                    }
                }
            } label: {
                Image(systemName: viewMode.systemImage)
            }
        }
    }
}
