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
    @AppStorage(SetListFilterKey.favoriteThemesOnly)
    private var filterFavoriteThemes = SetListFilterDefault.favoriteThemesOnly
    @AppStorage(SetListFilterKey.ownership) private var ownershipFilter = SetListFilterDefault.ownership
    @AppStorage(SetListFilterKey.favorite) private var favoriteFilter = SetListFilterDefault.favorite
    @AppStorage(SetListFilterKey.excludePackages) private var excludePackages = SetListFilterDefault.excludePackages
    @AppStorage(SetListFilterKey.excludeUnreleased)
    private var excludeUnreleased = SetListFilterDefault.excludeUnreleased
    @AppStorage(SetListFilterKey.excludeAccessories)
    private var excludeAccessories = SetListFilterDefault.excludeAccessories
    @AppStorage(SetListFilterKey.displayUSNumbers)
    private var displayUSNumbers = SetListFilterDefault.displayUSNumbers
    @AppStorage("favoriteThemes") private var favoriteThemesString: String = ""
    @AppStorage("sortOrder") private var sortOrder: SetListSortOrder = .year
    private var favoriteThemes: Swift.Set<Int> {
        Swift.Set(favoriteThemesString.split(separator: ",").compactMap { Int($0) })
    }

    /// The stored mode, or `.icon` when this platform does not offer it.
    private var availableViewMode: Binding<SetListViewMode> {
        Binding(get: { viewMode.availableOrDefault }, set: { viewMode = $0 })
    }

    var body: some View {
        Group {
            #if os(macOS)
            SetListContent(
                predicate: predicate,
                sortDescriptors: sortOrder.sortDescriptors,
                viewMode: availableViewMode,
                selectedTheme: $selectedTheme
            )
            #elseif os(iOS)
            SetListContent(
                predicate: predicate,
                sortDescriptors: sortOrder.sortDescriptors,
                viewMode: availableViewMode,
                selectedTheme: $selectedTheme,
                showSettings: $showSettings
            )
            #endif
        }
        .searchable(text: $searchText, placement: .toolbar)
        #if os(iOS)
        .popover(isPresented: $showSettings) {
            SettingsPopover()
        }
        #endif
    }

    private var predicate: NSPredicate? {
        SetListFilter(
            searchText: searchText,
            ownership: ownershipFilter,
            favorite: favoriteFilter,
            filterFavoriteThemes: filterFavoriteThemes,
            favoriteThemes: favoriteThemes,
            selectedTheme: selectedTheme,
            excludePackages: excludePackages,
            excludeUnreleased: excludeUnreleased,
            excludeAccessories: excludeAccessories,
            displayUSNumbers: displayUSNumbers
        ).predicate()
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
                // .list is not offered on macOS; SetList already maps it to .icon.
                case .icon, .list:
                    SetListIconView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .split:
                    SetListSplitView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .table:
                    SetListTableView(sets: setsArray, viewMode: $viewMode, selectedTheme: $selectedTheme)
                }
                #elseif os(iOS)
                // .list has no view of its own yet and shows the icon grid.
                SetListIconView(
                    sets: setsArray,
                    viewMode: $viewMode,
                    selectedTheme: $selectedTheme,
                    showSettings: $showSettings
                )
                #endif
            }
            .navigationTitle("Sets")
            SetListStatusBar(sets: setsArray)
            .padding()
        }
    }
}
