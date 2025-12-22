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
    @AppStorage("sortOrder") private var sortOrder: SetListSortOrder = .year
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
        .searchable(text: $searchText, placement: .toolbar)
        .environment(\.refreshSetList, loadSets)
        .onAppear(perform: loadSets)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataImported"))) { _ in
            loadSets()
        }
        .onChange(of: searchText) { _, _ in loadSets() }
        .onChange(of: filterOwnedState) { _, _ in loadSets() }
        .onChange(of: filterFavoriteState) { _, _ in loadSets() }
        .onChange(of: filterFavoriteThemes) { _, _ in loadSets() }
        .onChange(of: favoriteThemesString) { _, _ in loadSets() }
        .onChange(of: excludePackages) { _, _ in loadSets() }
        .onChange(of: excludeUnreleased) { _, _ in loadSets() }
        .onChange(of: excludeAccessories) { _, _ in loadSets() }
        .onChange(of: displayUSNumbers) { _, _ in loadSets() }
        .onChange(of: selectedTheme) { _, _ in loadSets() }
        .onChange(of: sortOrder) { _, _ in loadSets() }
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

    private func loadSets() {
        do {
            let request = createFetchRequest()
            var fetchedSets = try context.fetch(request)

            // Apply custom sorting for number-based sorts
            if sortOrder == .number || sortOrder == .year {
                fetchedSets.sort { lhs, rhs in
                    // If sorting by year, compare years first
                    if sortOrder == .year && lhs.year != rhs.year {
                        return lhs.year < rhs.year
                    }

                    // Parse and compare set numbers numerically
                    let lhsComponents = lhs.number.components(separatedBy: "-")
                    let rhsComponents = rhs.number.components(separatedBy: "-")

                    let lhsFirst = Int(lhsComponents[0]) ?? 0
                    let rhsFirst = Int(rhsComponents[0]) ?? 0

                    if lhsFirst != rhsFirst {
                        return lhsFirst < rhsFirst
                    }

                    // If first parts are equal, compare second parts
                    if lhsComponents.count > 1 && rhsComponents.count > 1 {
                        let lhsSecond = Int(lhsComponents[1]) ?? 0
                        let rhsSecond = Int(rhsComponents[1]) ?? 0
                        return lhsSecond < rhsSecond
                    }

                    // If one has a suffix and the other doesn't, the one without comes first
                    return lhsComponents.count < rhsComponents.count
                }
            }

            self.sets = fetchedSets
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

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Sort descriptors based on selected sort order
        request.sortDescriptors = sortOrder.sortDescriptors

        return request
    }
}
