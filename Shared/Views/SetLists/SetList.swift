//
//  SetList.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import SwiftUI
import SwiftData

struct SetList: View {
    @Environment(\.modelContext) private var context
    
    @State private var sets: [Set] = []
    @State private var searchText = ""
    @State private var showFilter = false
    @State public var selectedTheme: Theme?

    #if os(macOS)
    @AppStorage("viewMode") private var viewMode: SetListViewMode = .icon
    #endif
    @AppStorage("filterFavoriteThemes") private var filterFavoriteThemes = true
    @AppStorage("filterOwnedState") private var filterOwnedState = 0 // 0=all, 1=owned, 2=not owned
    @AppStorage("filterFavoriteState") private var filterFavoriteState = 0 // 0=all, 1=favorite, 2=not favorite
    @AppStorage("excludePackages") private var excludePackages = true
    @AppStorage("excludeUnreleased") private var excludeUnreleased = true
    @AppStorage("excludeAccessories") private var excludeAccessories = true
    @AppStorage("displayUSNumbers") private var displayUSNumbers = false
    @AppStorage("favoriteThemes") private var favoriteThemesString: String = ""
    public var favoriteThemes: Swift.Set<Int> {
        Swift.Set(favoriteThemesString.split(separator: ",").compactMap { Int($0) })
    }

//    private var totalMinifigs: Int {
//        baseSetList.sets.reduce(0) { total, set in
//            total + set.minifigsCount
//        }
//    }
//
//    private var totalParts: Int {
//        baseSetList.sets.reduce(0) { total, set in
//            total + set.actualPartsCount
//        }
//    }

    var body: some View {
        VStack {
            Group {
                #if os(macOS)
                switch viewMode {
                case .icon:
                    SetListIconView(sets: sets, viewMode: $viewMode, showFilter: $showFilter, selectedTheme: $selectedTheme)
                case .split:
                    SetListSplitView(sets: sets, viewMode: $viewMode, showFilter: $showFilter, selectedTheme: $selectedTheme)
                case .table:
                    SetListTableView(sets: sets, viewMode: $viewMode, showFilter: $showFilter, selectedTheme: $selectedTheme)
                }
                #elseif os(iOS)
                #endif
            }
            .navigationTitle("Sets")
            SetListStatusBar(sets: $sets)
            .padding()
        }
        .searchable(text: $searchText)
        .onAppear(perform: loadSets)
        .onChange(of: searchText) { loadSets() }
        .onChange(of: filterOwnedState) { loadSets() }
        .onChange(of: filterFavoriteState) { loadSets() }
        .onChange(of: filterFavoriteThemes) { loadSets() }
        .onChange(of: excludePackages) { loadSets() }
        .onChange(of: excludeUnreleased) { loadSets() }
        .onChange(of: excludeAccessories) { loadSets() }
        .onChange(of: displayUSNumbers) { loadSets() }
        .onChange(of: selectedTheme) { loadSets() }
//        .popover(isPresented: $showFilter) {
//            SetListFilterSetting()
//        }
    }

    private func loadSets() {
        do {
            self.sets = try context.fetch(fetchDescriptor())
        } catch {
            print("Failed to fetch sets:", error)
        }
    }

    private func fetchDescriptor() -> FetchDescriptor<Set> {
        let selectedThemeIDs = selectedTheme?.getAllThemeIDs() ?? []
        let predicateText = #Predicate<Set> { set in
            (searchText.isEmpty || set.number.localizedStandardContains(searchText)
            || set.name.localizedStandardContains(searchText))
        }
        let predicateOwned = #Predicate<Set> { set in
            (filterOwnedState == 0 || (filterOwnedState == 1 && set.userData?.owned == true) || (filterOwnedState == 2 && (set.userData == nil || set.userData?.owned == false)))
        }
        let predicateFavorite = #Predicate<Set> { set in
            (filterFavoriteState == 0 || (filterFavoriteState == 1 && set.userData?.favorite == true) || (filterFavoriteState == 2 && (set.userData == nil || set.userData?.favorite == false)))
        }
        let predicateFromFavoriteThemes = #Predicate<Set> { set in
            (!filterFavoriteThemes || favoriteThemes.contains(set.themeID))
        }
        let predicateFlags = #Predicate<Set> { set in
            (!excludePackages || !set.isPack) &&
            (!excludeUnreleased || !set.isUnreleased) &&
            (!excludeAccessories || !set.isAccessory)
        }
        let predicateUSNumbers = #Predicate<Set> { set in
            (displayUSNumbers || !set.isUSNumber)
        }
        let predicateSelectedTheme = #Predicate<Set> { set in
            selectedThemeIDs.contains(set.themeID)
        }
        let themeFilterPredicate = selectedTheme == nil ? predicateFromFavoriteThemes : predicateSelectedTheme
        let complexPredicate = #Predicate<Set> { set in
            predicateText.evaluate(set) && predicateOwned.evaluate(set) && predicateFavorite.evaluate(set) && themeFilterPredicate.evaluate(set) && predicateFlags.evaluate(set) && predicateUSNumbers.evaluate(set)
        }
        return FetchDescriptor(
            predicate: complexPredicate,
            sortBy: [SortDescriptor(\Set.year), SortDescriptor(\Set.number)]
        )
    }
}
