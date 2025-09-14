//
//  ViewModeMenuToolbarItem.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/13/25.
//

import SwiftUI

struct ViewModeMenuToolbarItem: ToolbarContent {
    @Binding var viewMode: SetListViewMode
    
    var body: some ToolbarContent {
        ToolbarItem {
            Menu {
                ForEach(SetListViewMode.allCases, id: \.self) { mode in
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
