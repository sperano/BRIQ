//
//  SetListSplitView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import SwiftUI
import CoreData

struct SetListSplitView: View {
    var sets: [Set]
    @Binding var viewMode: SetListViewMode
    @Binding var showFilter: Bool
    @Binding var selectedTheme: Theme?
    @State private var selectedSet: Set?
    
    var body: some View {
        NavigationSplitView {
            List(sets, selection: $selectedSet) { set in
                SetRow(set: set)
                    .tag(set)
            }
            .listStyle(.plain)
            .toolbar {
                ThemeDropdownToolbarItem(selectedTheme: $selectedTheme)
                ViewModeMenuToolbarItem(viewMode: $viewMode)
                #if os(iOS)
                SettingsButtonToolbarItem(showFilter: $showFilter)
                #endif
            }
        } detail: {
            if let selectedSet = selectedSet {
                SetDetail(set: selectedSet, selectedSet: $selectedSet)
            } else {
                Text("Select a set to view details")
                    .foregroundColor(.secondary)
            }
        }
    }
}
