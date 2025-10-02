//
//  ThemeDropdownToolbarItem.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/13/25.
//

import SwiftUI

struct ThemeDropdownToolbarItem: ToolbarContent {
    @Binding var selectedTheme: Theme?
    
    var body: some ToolbarContent {
        ToolbarItem {
            ThemeDropdown(selectedTheme: $selectedTheme)
        }
    }
}
