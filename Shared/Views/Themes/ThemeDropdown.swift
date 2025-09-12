//
//  ThemeDropdown.swift
//  BRIQ
//
//  Created by Éric Spérano
//

import SwiftUI

struct ThemeDropdown: View {
    @Binding var selectedTheme: Theme?
    
    @AppStorage("onlyShowFavoriteThemes") private var onlyShowFavorites: Bool = false
    @AppStorage("favoriteThemes") private var favoriteThemesString: String = ""
    private var favoriteThemes: Swift.Set<Int> {
        Swift.Set(favoriteThemesString.split(separator: ",").compactMap { Int($0) })
    }
    
    private func buildThemeMenu() -> [ThemeMenuItem] {
        var items: [ThemeMenuItem] = []
        
        // Add "All Themes" option
        items.append(ThemeMenuItem(theme: nil, indentLevel: 0))
        
        // Add hierarchical themes
        let filteredThemes = onlyShowFavorites ? ThemesTree.filter { hasSelectedDescendant($0) } : ThemesTree
        for theme in filteredThemes {
            items.append(contentsOf: buildThemeMenuItems(theme: theme, indentLevel: 0))
        }
        
        return items
    }
    
    private func buildThemeMenuItems(theme: Theme, indentLevel: Int) -> [ThemeMenuItem] {
        var items: [ThemeMenuItem] = []
        
        // Add current theme if it should be shown
        if !onlyShowFavorites || hasSelectedDescendant(theme) {
            items.append(ThemeMenuItem(theme: theme, indentLevel: indentLevel))
            
            // Add children recursively
            for child in theme.sortedChildren {
                items.append(contentsOf: buildThemeMenuItems(theme: child, indentLevel: indentLevel + 1))
            }
        }
        
        return items
    }
    
    private func hasSelectedDescendant(_ theme: Theme) -> Bool {
        if favoriteThemes.contains(theme.id) { return true }
        return theme.children.contains(where: hasSelectedDescendant)
    }
    
    var body: some View {
        Menu {
            ForEach(buildThemeMenu(), id: \.id) { item in
                Button(action: {
                    selectedTheme = item.theme
                }) {
                    HStack {
                        Text(item.displayName)
                        Spacer()
                        if selectedTheme?.id == item.theme?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                Text(selectedTheme?.name ?? "All Themes")
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.primary)
        }
    }
}

struct ThemeMenuItem: Identifiable {
    let id = UUID()
    let theme: Theme?
    let indentLevel: Int
    
    var displayName: String {
        let prefix = String(repeating: "  ", count: indentLevel)
        return prefix + (theme?.name ?? "All Themes")
    }
}

#if DEBUG
#Preview {
    ThemeDropdown(selectedTheme: .constant(nil))
        .padding()
        .onAppear {
            initThemesTree()
        }
}
#endif
