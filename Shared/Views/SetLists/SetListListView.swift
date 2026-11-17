//
//  SetListListView.swift
//  BRIQ
//

import SwiftUI

/// iOS-only "List" view mode: a plain list of rows pushing into the
/// navigation stack, as opposed to the icon grid.
struct SetListListView: View {
    var sets: [Set]
    @Binding var viewMode: SetListViewMode
    @Binding var selectedTheme: Theme?
    @Binding var showSettings: Bool

    var body: some View {
        List(sets) { set in
            SetDetailNavigationLink(set: set) {
                SetRow(set: set)
            }
        }
        .listStyle(.plain)
        .toolbar {
            ThemeDropdownToolbarItem(selectedTheme: $selectedTheme)
            ViewModeMenuToolbarItem(viewMode: $viewMode)
            SettingsButtonToolbarItem(showSettings: $showSettings)
        }
    }
}
