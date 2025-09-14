//
//  SetList.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import SwiftUI
import CoreData

struct SetList: View {
    @Environment(\.managedObjectContext) private var context

    @State private var sets: [Set] = []
    @State private var searchText = ""
    @State public var selectedTheme: Theme?
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
    public var favoriteThemes: Swift.Set<Int> {
        Swift.Set(favoriteThemesString.split(separator: ",").compactMap { Int($0) })
    }

    var body: some View {
        VStack {
            Group {
                #if os(macOS)
                switch viewMode {
                case .icon:
                    SetListIconView(sets: sets, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .split:
                    SetListSplitView(sets: sets, viewMode: $viewMode, selectedTheme: $selectedTheme)
                case .table:
                    SetListTableView(sets: sets, viewMode: $viewMode, selectedTheme: $selectedTheme)
                }
                #elseif os(iOS)
                switch viewMode {
                case .icon:
                    SetListIconView(sets: sets, viewMode: $viewMode, selectedTheme: $selectedTheme, showSettings: $showSettings)
                case .list:
                    SetListIconView(sets: sets, viewMode: $viewMode, selectedTheme: $selectedTheme, showSettings: $showSettings)
                }
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
        #if os(iOS)
        .popover(isPresented: $showSettings) {
            SettingsPopover()
        }
        #endif
    }

    private func loadSets() {
        do {
            let request = createFetchRequest()
            self.sets = try context.fetch(request)
        } catch {
            print("Failed to fetch sets:", error)
        }
    }

    private func createFetchRequest() -> NSFetchRequest<Set> {
        let request = Set.fetchRequest()

        var predicates: [NSPredicate] = []

        // Search text filter
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "number CONTAINS[cd] %@ OR name CONTAINS[cd] %@", searchText, searchText)
            predicates.append(searchPredicate)
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
            let themeIDs = selectedTheme.getAllThemeIDs()
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

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Sort descriptors
        request.sortDescriptors = [
            NSSortDescriptor(key: "year", ascending: true),
            NSSortDescriptor(key: "number", ascending: true)
        ]

        return request
    }
}
