//
//  SettingsPopover.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import SwiftUI

struct SettingsPopover: View {
    @Environment(\.dismiss) private var dismiss

    // Pass bindings from parent
    @Binding var filterFavoriteThemes: Bool
    @Binding var filterOwnedState: Int
    @Binding var filterFavoriteState: Int
    @Binding var excludePackages: Bool
    @Binding var excludeUnreleased: Bool
    @Binding var excludeAccessories: Bool
    @Binding var displayUSNumbers: Bool

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    OwnershipFiltersSettings(
                        filterFavoriteThemes: $filterFavoriteThemes,
                        filterOwnedState: $filterOwnedState,
                        filterFavoriteState: $filterFavoriteState
                    )
                } label: {
                    Label("Ownership", systemImage: "person.circle")
                }

                NavigationLink {
                    ExclusionFiltersSettings(
                        excludePackages: $excludePackages,
                        excludeUnreleased: $excludeUnreleased,
                        excludeAccessories: $excludeAccessories
                    )
                } label: {
                    Label("Exclusions", systemImage: "eye.slash")
                }

                NavigationLink {
                    DisplaySettings(displayUSNumbers: $displayUSNumbers)
                } label: {
                    Label("US Numbers", systemImage: "eye")
                }

                NavigationLink {
                    ThemesSettings()
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
}

struct OwnershipFiltersSettings: View {
    @Binding var filterFavoriteThemes: Bool
    @Binding var filterOwnedState: Int
    @Binding var filterFavoriteState: Int

    var body: some View {
        List {
            Section("Themes") {
                Toggle("Show sets from favorite themes only", isOn: $filterFavoriteThemes)
            }

            Section("Ownership") {
                Picker("Ownership Filter", selection: $filterOwnedState) {
                    Text("All Sets").tag(0)
                    Text("Owned Only").tag(1)
                    Text("Not Owned Only").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section("Favorites") {
                Picker("Favorite Filter", selection: $filterFavoriteState) {
                    Text("All Sets").tag(0)
                    Text("Favorites Only").tag(1)
                    Text("Not Favorites Only").tag(2)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button("Reset Ownership Filters", role: .destructive) {
                    filterFavoriteThemes = false
                    filterOwnedState = 0
                    filterFavoriteState = 0
                }
            }
        }
        .navigationTitle("Ownership")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExclusionFiltersSettings: View {
    @Binding var excludePackages: Bool
    @Binding var excludeUnreleased: Bool
    @Binding var excludeAccessories: Bool

    var body: some View {
        List {
            Section("Exclusions") {
                Toggle("Hide Packages", isOn: $excludePackages)
                Toggle("Hide Unreleased", isOn: $excludeUnreleased)
                Toggle("Hide Accessories", isOn: $excludeAccessories)
            }

            Section {
                Button("Reset Exclusion Filters", role: .destructive) {
                    excludePackages = true
                    excludeUnreleased = true
                    excludeAccessories = true
                }
            }
        }
        .navigationTitle("Exclusions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DisplaySettings: View {
    @Binding var displayUSNumbers: Bool

    var body: some View {
        List {
            Section("US Numbers") {
                Toggle("Show Sets with US Numbers", isOn: $displayUSNumbers)
            }

            Section {
                Button("Reset Display Settings", role: .destructive) {
                    displayUSNumbers = false
                }
            }
        }
        .navigationTitle("US Numbers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemesSettings: View {
    var body: some View {
        FavoriteThemes()
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsPopover(
        filterFavoriteThemes: .constant(false),
        filterOwnedState: .constant(0),
        filterFavoriteState: .constant(0),
        excludePackages: .constant(true),
        excludeUnreleased: .constant(true),
        excludeAccessories: .constant(true),
        displayUSNumbers: .constant(false)
    )
}