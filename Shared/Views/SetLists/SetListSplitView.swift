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
    @Binding var selectedTheme: Theme?
    #if os(iOS)
    @Binding var showSettings: Bool
    #endif
    @State private var selectedSet: Set?
    @Environment(\.refreshSetList) private var refreshSetList
    @State private var pendingRefresh = false

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
                SettingsButtonToolbarItem(showSettings: $showSettings)
                #endif
            }
        } detail: {
            if let selectedSet = selectedSet {
                SetDetail(
                    set: selectedSet,
                    selectedSet: $selectedSet,
                    onDisappear: {
                        pendingRefresh = true
                    }
                )
            } else {
                Text("Select a set to view details")
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: selectedSet) { newSet in
            // When selection changes, refresh if there were pending changes
            if pendingRefresh {
                refreshSetList()
                pendingRefresh = false
            }
        }
        .onDisappear {
            // When the split view itself disappears, refresh if needed
            if pendingRefresh {
                refreshSetList()
                pendingRefresh = false
            }
        }
    }
}
