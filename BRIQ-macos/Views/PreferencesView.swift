//
//  PreferencesView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/23/25.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            OwnershipFiltersPreferences()
                .tabItem {
                    Label("Ownership", systemImage: "person.circle")
                }
            
            ExclusionFiltersPreferences()
                .tabItem {
                    Label("Exclusions", systemImage: "eye.slash")
                }
            
            DisplayPreferences()
                .tabItem {
                    Label("US Numbers", systemImage: "eye")
                }
            
            ThemesPreferences()
                .tabItem {
                    Label("Themes", systemImage: "paintpalette")
                }
        }
        .frame(width: 500, height: 300) // consistent size
        .padding(20)
    }
}

struct ThemesPreferences: View {
    var body: some View {
        FavoriteThemes()
    }
}

struct OwnershipFiltersPreferences: View {
    @AppStorage("filterFavoriteThemes") private var filterFavoriteThemes = false
    @AppStorage("filterOwnedState") private var filterOwnedState = 0 // 0=all, 1=owned, 2=not owned
    @AppStorage("filterFavoriteState") private var filterFavoriteState = 0 // 0=all, 1=favorite, 2=not favorite
    
    var body: some View {
        Form {
            Section("Themes") {
                Toggle("Show sets from favorite themes only", isOn: $filterFavoriteThemes)
            }
            
            Section("Ownership") {
                Picker("Ownership Filter", selection: $filterOwnedState) {
                    Text("All Sets").tag(0)
                    Text("Owned Only").tag(1)
                    Text("Not Owned Only").tag(2)
                }
                .pickerStyle(.radioGroup)
            }
            
            Section("Favorites") {
                Picker("Favorite Filter", selection: $filterFavoriteState) {
                    Text("All Sets").tag(0)
                    Text("Favorites Only").tag(1)
                    Text("Not Favorites Only").tag(2)
                }
                .pickerStyle(.radioGroup)
            }
            
            Section {
                Button("Reset Ownership Filters") {
                    filterFavoriteThemes = false
                    filterOwnedState = 0
                    filterFavoriteState = 0
                }
                .foregroundColor(.red)
            }
        }
    }
}

struct ExclusionFiltersPreferences: View {
    @AppStorage("excludePackages") private var excludePackages = true
    @AppStorage("excludeUnreleased") private var excludeUnreleased = true
    @AppStorage("excludeAccessories") private var excludeAccessories = true
    
    var body: some View {
        Form {
            Section("Exclusions") {
                Toggle("Hide Packages", isOn: $excludePackages)
                Toggle("Hide Unreleased", isOn: $excludeUnreleased)
                Toggle("Hide Accessories", isOn: $excludeAccessories)
            }
            
            Section {
                Button("Reset Exclusion Filters") {
                    excludePackages = true
                    excludeUnreleased = true
                    excludeAccessories = true
                }
                .foregroundColor(.red)
            }
        }
    }
}

struct DisplayPreferences: View {
    @AppStorage("displayUSNumbers") private var displayUSNumbers = false
    
    var body: some View {
        Form {
            Section("US Numbers") {
                Toggle("Show Sets with US Numbers", isOn: $displayUSNumbers)
            }
            
            Section {
                Button("Reset Display Settings") {
                    displayUSNumbers = false
                }
                .foregroundColor(.red)
            }
        }
    }
}
