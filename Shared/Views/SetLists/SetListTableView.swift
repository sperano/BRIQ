//
//  SetListTableView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import SwiftUI
import CoreData

struct SetListTableView: View {
    var sets: [Set]
    @Binding var viewMode: SetListViewMode
    @Binding var selectedTheme: Theme?
    #if os(iOS)
    @Binding var showSettings: Bool
    #endif

    // TODO should be year and then number
    @State private var sortOrder = [KeyPathComparator<Set>(\.number)]
    
    private var sortedSets: [Set] {
        sets.sorted(using: sortOrder)
    }
    
    private var numberColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Number", value: \.number) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(set.number)
            }
            .buttonStyle(.plain)
        }
        .width(min: 80, ideal: 100, max: 120)
    }
    
    private var nameColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Name", value: \.name) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(set.name)
            }
            .buttonStyle(.plain)
        }
        .width(min: 200, ideal: 300, max: 500)
    }
    
    private var yearColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Year", value: \.year) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(String(set.year))
            }
            .buttonStyle(.plain)
        }
        .width(min: 60, ideal: 80, max: 100)
    }

    private var themeColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Theme", value: \.themeName) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(set.themeName)
            }
            .buttonStyle(.plain)
        }
        .width(min: 100, ideal: 150, max: 200)
    }

    private var ownedColumn: some TableColumnContent<Set, Never> {
        TableColumn("Owned") { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Image(systemName: (set.userData?.owned ?? false) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor((set.userData?.owned ?? false) ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .width(min: 60, ideal: 80, max: 100)
    }
    
    private var favoriteColumn: some TableColumnContent<Set, Never> {
        TableColumn("Favorite") { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Image(systemName: (set.userData?.favorite ?? false) ? "heart.fill" : "heart")
                    .foregroundColor((set.userData?.favorite ?? false) ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .width(min: 80, ideal: 100, max: 120)
    }
    
    private var minifigsColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Minifigs", value: \.minifigsCount) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(String(set.minifigsCount))
            }
            .buttonStyle(.plain)
        }
        .width(min: 80, ideal: 100, max: 120)
    }
    
    private var partsColumn: some TableColumnContent<Set, KeyPathComparator<Set>> {
        TableColumn("Parts", value: \.actualPartsCount) { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Text(String(set.actualPartsCount))
            }
            .buttonStyle(.plain)
        }
        .width(min: 80, ideal: 100, max: 120)
    }
    
    private var instructionsColumn: some TableColumnContent<Set, Never> {
        TableColumn("Has Instructions") { set in
            NavigationLink(destination: SetDetail(set: set)) {
                Image(systemName: (set.userData?.ownsInstructions ?? false) ? "doc.fill" : "doc")
                    .foregroundColor((set.userData?.ownsInstructions ?? false) ? .blue : .secondary)
            }
            .buttonStyle(.plain)
        }
        .width(min: 100, ideal: 120, max: 140)
    }
    
    private var instructionsQualityColumn: some TableColumnContent<Set, Never> {
        TableColumn("Instr. Quality") { set in
            NavigationLink(destination: SetDetail(set: set)) {
                StarRatingView(rating: .constant(Int(set.userData?.instructionsQuality ?? 0)), isInteractive: false)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .width(min: 100, ideal: 120, max: 140)
    }
    
    var body: some View {
        VStack {
            Table(sortedSets, sortOrder: $sortOrder) {
                numberColumn
                nameColumn
                yearColumn
                themeColumn
                ownedColumn
                favoriteColumn
                instructionsColumn
                instructionsQualityColumn
                minifigsColumn
                partsColumn
            }
        }
        .toolbar {
            ThemeDropdownToolbarItem(selectedTheme: $selectedTheme)
            ViewModeMenuToolbarItem(viewMode: $viewMode)
            #if os(iOS)
            SettingsButtonToolbarItem(showSettings: $showSettings)
            #endif
        }
    }
}

#if DEBUG
//#Preview {
//    NavigationStack {
//        SetListTableView(
//            sets: Set.sampleData,
//            viewMode: .constant(.table),
//            showFilter: .constant(false),
//            selectedTheme: .constant(nil),
//        )
//        .modelContainer(SampleData.shared.modelContainer)
//    }
//}
#endif
