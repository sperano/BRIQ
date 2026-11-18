//
//  SettingsButtonToolbarItem.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/13/25.
//

import SwiftUI

struct SettingsButtonToolbarItem: ToolbarContent {
    @Binding var showSettings: Bool

    var body: some ToolbarContent {
        ToolbarItem {
            Button {
                showSettings.toggle()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
