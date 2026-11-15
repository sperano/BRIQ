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
            OwnershipFiltersSettings()
                .tabItem {
                    Label("Ownership", systemImage: "person.circle")
                }

            ExclusionFiltersSettings()
                .tabItem {
                    Label("Exclusions", systemImage: "eye.slash")
                }

            DisplaySettings()
                .tabItem {
                    Label("US Numbers", systemImage: "eye")
                }

            FavoriteThemes()
                .tabItem {
                    Label("Themes", systemImage: "paintpalette")
                }
        }
        .frame(width: 500, height: 300) // consistent size
        .padding(20)
    }
}
