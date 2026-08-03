//
//  SetList.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import SwiftUI
import CoreData

/// Owns the filter/sort state and rebuilds the fetch request's predicate and
/// sort descriptors in one place; `SetListContent` re-fetches whenever they
/// change because its `@FetchRequest` is reconstructed with the new values.
struct SetList: View {
    @State private var searchText = ""
    @State private var selectedTheme: Theme?
    #if os(iOS)
    @State private var showSettings = false
    #endif
    @AppStorage("viewMode") private var viewMode: SetListViewMode = .icon
    @AppStorage("filterFavoriteThemes") private var filterFavoriteThemes = true
    @AppStorage("filterOwnedState") private var filterOwnedState = 0 // 0=all, 1=owned, 2=not owned
    @AppStorage("filterFavoriteState") private var filterFavoriteState = 0 // 0=all, 1=favorite, 2=not favorite
    @AppStorage("excludePackages") private var excludePackages = true
    @AppStorage("excludeUnreleased") private var excludeUnreleased = true
    @AppStorage("excludeAccessories") private var excludeAccessories = true
    @AppStorage("displayUSNumbers") private var displayUSNumbers = false
    @AppStorage("favoriteThemes") private var favoriteThemesString: String = ""
    @AppStorage("sortOrder") private var sortOrder: SetListSortOrder = .year
    private var favoriteThemes: Swift.Set<Int> {
        Swift.Set(favoriteThemesString.split(separator: ",").compactMap { Int($0) })
    }

    var body: some View {
        Group {
            #if os(macOS)
            SetListContent(
                predicate: predicate,
                sortDescriptors: sortOrder.sortDescriptors,
                viewMode: $viewMode,
                selectedTheme: $selectedTheme
            )
            #elseif os(iOS)
            SetListContent(
                predicate: predicate,
                sortDescriptors: sortOrder.sortDescriptors,
                viewMode: $viewMode,
                selectedTheme: $selectedTheme,
                showSettings: $showSettings
            )
            #endif
        }
        .searchable(text: $searchText, placement: .toolbar)
        #if os(iOS)
        .popover(isPresented: $showSettings) {
            SettingsPopover(
                filterFavoriteThemes: $filterFavoriteThemes,
                filterOwnedState: $filterOwnedState,
                filterFavoriteState: $filterFavoriteState,
                excludePackages: $excludePackages,
                excludeUnreleased: $excludeUnreleased,
                excludeAccessories: $excludeAccessories,
                displayUSNumbers: $displayUSNumbers
            )
        }
        #endif
    }

    private var predicate: NSPredicate? {
        var predicates: [NSPredicate] = []

        // Search text filter
        if !searchText.isEmpty {
            predicates.append(NSPredicate(
                format: "number CONTAINS[cd] %@ OR name CONTAINS[cd] %@", searchText, searchText
            ))
        }

        // Owned state filter
        switch filterOwnedState {
        case 1: // owned only
            predicates.append(NSPredicate(format: "userData.owned == YES"))
        case 2: // not owned only
            predicates.append(NSPredicate(format: "userData.owned == NO OR userData == nil"))
        default: break // all
        }

        // Favorite state filter
        switch filterFavoriteState {
        case 1: // favorites only
            predicates.append(NSPredicate(format: "userData.favorite == YES"))
        case 2: // not favorites only
            predicates.append(NSPredicate(format: "userData.favorite == NO OR userData == nil"))
        default: break // all
        }

        // Theme filter
        if let selectedTheme = selectedTheme {
            var themeIDs = selectedTheme.getAllThemeIDs()
            // If filtering by favorites, only include favorite themes from the hierarchy
            if filterFavoriteThemes {
                themeIDs = themeIDs.intersection(favoriteThemes)
            }
            let themeArray = Array(themeIDs).map { NSNumber(value: $0) }
            predicates.append(NSPredicate(format: "themeID IN %@", themeArray))
        } else if filterFavoriteThemes {
            let themeArray = Array(favoriteThemes).map { NSNumber(value: $0) }
            predicates.append(NSPredicate(format: "themeID IN %@", themeArray))
        }

        // Exclusion filters
        if excludePackages {
            predicates.append(NSPredicate(format: "isPack == NO"))
        }
        if excludeUnreleased {
            predicates.append(NSPredicate(format: "isUnreleased == NO"))
        }
        if excludeAccessories {
            predicates.append(NSPredicate(format: "isAccessory == NO"))
        }

        // US numbers filter
        if !displayUSNumbers {
            predicates.append(NSPredicate(format: "isUSNumber == NO"))
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

private struct SetListContent: View {
    @FetchRequest private var sets: FetchedResults<Set>
    @Binding var viewMode: SetListViewMode
    @Binding var selectedTheme: Theme?
    #if os(iOS)
    @Binding var showSettings: Bool
    #endif

    #if os(macOS)
    init(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        viewMode: Binding<SetListViewMode>,
        selectedTheme: Binding<Theme?>
    ) {
        _sets = FetchRequest(sortDescriptors: sortDescriptors, predicate: predicate, animation: .default)
        _viewMode = viewMode
        _selectedTheme = selectedTheme
    }
    #elseif os(iOS)
    init(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        viewMode: Binding<SetListViewMode>,
        selectedTheme: Binding<Theme?>,
        showSettings: Binding<Bool>
    ) {
        _sets = FetchRequest(sortDescriptors: sortDescriptors, predicate: predicate, animation: .default)
        _viewMode = viewMode
        _selectedTheme = selectedTheme
        _showSettings = showSettings
    }
    #endif

    var body: some View {
        let setsArray = Array(sets)
        VStack {
            Group {
                #if os(macOS)
                switch viewMode {
                case .icon:
                    SetListIconView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .split:
                    SetListSplitView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .table:
                    SetListTableView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                }
                #elseif os(iOS)
                switch viewMode {
                case .icon:
                    SetListIconView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme, showSettings: $showSettings)
                case .list:
                    SetListIconView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme, showSettings: $showSettings)
                }
                #endif
            }
            .navigationTitle("Sets")
            SetListStatusBar(sets: setsArray)
            .padding()
        }
    }
}
