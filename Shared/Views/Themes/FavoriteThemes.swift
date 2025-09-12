//
//  ThemeTreeView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/19/25.
//

import SwiftUI

extension Array {
    public var optional: [Element]? { isEmpty ? nil : self }
}

struct ThemeRow:  View {
    let theme: Theme
    @Binding var selected: Swift.Set<Int>
    
    var body: some View {
        HStack {
            Text(theme.name)
            Spacer()
            if selected.contains(theme.id) {
                Image(systemName: "star.fill").foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle()) // make row tappable
        .onTapGesture {
            if selected.contains(theme.id) {
                selected.remove(theme.id)
            } else {
                selected.insert(theme.id)
            }
        }
    }
}

struct FavoriteThemes: View {
    //@State private var selected: Swift.Set<Int> = []
    @State private var searchText = ""
    @AppStorage("onlyShowFavoriteThemes") private var onlyShowFavorites: Bool = false

    @AppStorage("favoriteThemes") private var favoriteThemesString: String = ""
    @State private var selectedSet: Swift.Set<Int> = []
    
    init() {
        _selectedSet = State(initialValue: Swift.Set(
            favoriteThemesString
                .split(separator: ",")
                .compactMap { Int($0) })
        )
    }
    
    private func saveSelected() {
        favoriteThemesString = selectedSet.map(String.init).joined(separator: ",")
    }
    
    var selectedBinding: Binding<Swift.Set<Int>> {
        Binding(
            get: { selectedSet },
            set: { newValue in
                selectedSet = newValue
                saveSelected()
            }
        )
    }

    var body: some View {
        VStack {
            List(selection: $selectedSet) {
                OutlineGroup(searchResults, children: \.children.optional) { theme in
                    ThemeRow(theme: theme, selected: selectedBinding)
                }
            }
            .searchable(text: $searchText, prompt: "Search for a theme")
            Toggle(isOn: $onlyShowFavorites) {
                Text("Only show favorites")
            }
            .padding()
        }
    }

    var searchResults: [Theme] {
        return ThemesTree.filter { theme in
            (!onlyShowFavorites || hasSelectedDescendant(theme)) &&
            (searchText.isEmpty || theme.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    func hasSelectedDescendant(_ theme: Theme) -> Bool {
        if selectedSet.contains(theme.id) { return true }
        return theme.children.contains(where: hasSelectedDescendant)
    }

}

#Preview {
    NavigationStack {
        FavoriteThemes()
    }
}
