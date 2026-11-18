//
//  SetListFilterSettings.swift
//  BRIQ
//
//  The set list filter forms shown by the iOS settings popover and the macOS
//  Settings window. They read and write `@AppStorage` directly, with the keys
//  and defaults `SetList` filters with.
//

import SwiftUI

struct OwnershipFiltersSettings: View {
    @AppStorage(SetListFilterKey.favoriteThemesOnly)
    private var favoriteThemesOnly = SetListFilterDefault.favoriteThemesOnly
    @AppStorage(SetListFilterKey.ownership) private var ownership = SetListFilterDefault.ownership
    @AppStorage(SetListFilterKey.favorite) private var favorite = SetListFilterDefault.favorite

    var body: some View {
        Form {
            Section("Themes") {
                Toggle("Show sets from favorite themes only", isOn: $favoriteThemesOnly)
            }

            Section("Ownership") {
                Picker("Ownership Filter", selection: $ownership) {
                    ForEach(OwnershipFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .filterPickerStyle()
            }

            Section("Favorites") {
                Picker("Favorite Filter", selection: $favorite) {
                    ForEach(FavoriteFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .filterPickerStyle()
            }

            Section {
                ResetFiltersButton(title: "Reset Ownership Filters") {
                    favoriteThemesOnly = SetListFilterDefault.favoriteThemesOnly
                    ownership = SetListFilterDefault.ownership
                    favorite = SetListFilterDefault.favorite
                }
            }
        }
    }
}

struct ExclusionFiltersSettings: View {
    @AppStorage(SetListFilterKey.excludePackages)
    private var excludePackages = SetListFilterDefault.excludePackages
    @AppStorage(SetListFilterKey.excludeUnreleased)
    private var excludeUnreleased = SetListFilterDefault.excludeUnreleased
    @AppStorage(SetListFilterKey.excludeAccessories)
    private var excludeAccessories = SetListFilterDefault.excludeAccessories

    var body: some View {
        Form {
            Section("Exclusions") {
                Toggle("Hide Packages", isOn: $excludePackages)
                Toggle("Hide Unreleased", isOn: $excludeUnreleased)
                Toggle("Hide Accessories", isOn: $excludeAccessories)
            }

            Section {
                ResetFiltersButton(title: "Reset Exclusion Filters") {
                    excludePackages = SetListFilterDefault.excludePackages
                    excludeUnreleased = SetListFilterDefault.excludeUnreleased
                    excludeAccessories = SetListFilterDefault.excludeAccessories
                }
            }
        }
    }
}

struct DisplaySettings: View {
    @AppStorage(SetListFilterKey.displayUSNumbers)
    private var displayUSNumbers = SetListFilterDefault.displayUSNumbers

    var body: some View {
        Form {
            Section("US Numbers") {
                Toggle("Show Sets with US Numbers", isOn: $displayUSNumbers)
            }

            Section {
                ResetFiltersButton(title: "Reset Display Settings") {
                    displayUSNumbers = SetListFilterDefault.displayUSNumbers
                }
            }
        }
    }
}

private struct ResetFiltersButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(title, role: .destructive, action: action)
            .foregroundStyle(.red)
    }
}

private extension View {
    /// Segmented on iOS, radio buttons on macOS.
    func filterPickerStyle() -> some View {
        #if os(macOS)
        pickerStyle(.radioGroup)
        #else
        pickerStyle(.segmented)
        #endif
    }
}
