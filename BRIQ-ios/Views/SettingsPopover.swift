//
//  SettingsPopover.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import SwiftUI

struct SettingsPopover: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    settingsPage(OwnershipFiltersSettings(), title: "Ownership")
                } label: {
                    Label("Ownership", systemImage: "person.circle")
                }

                NavigationLink {
                    settingsPage(ExclusionFiltersSettings(), title: "Exclusions")
                } label: {
                    Label("Exclusions", systemImage: "eye.slash")
                }

                NavigationLink {
                    settingsPage(DisplaySettings(), title: "US Numbers")
                } label: {
                    Label("US Numbers", systemImage: "eye")
                }

                NavigationLink {
                    settingsPage(FavoriteThemes(), title: "Themes")
                } label: {
                    Label("Themes", systemImage: "paintpalette")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func settingsPage(_ page: some View, title: String) -> some View {
        page
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsPopover()
}
