//
//  SetListSplitView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import SwiftUI
import SwiftData

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
                ToolbarItemGroup(placement: .primaryAction) {
                    ThemeDropdown(selectedTheme: $selectedTheme)
                    
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

                    #if os(iOS)
                    Button(action: {
                        showFilter.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    #endif
                }
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
