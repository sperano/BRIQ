//
//  ThemeDropdownTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@MainActor struct ThemeDropdownTests {
    @Test func entryClearingTheFilterNamesAllThemes() {
        #expect(ThemeMenuItem.allThemesTitle(showingFavorites: false) == "All Themes")
    }

    @Test func entryClearingTheFilterNamesFavoriteThemesWhenOnlyFavoritesShow() {
        #expect(ThemeMenuItem.allThemesTitle(showingFavorites: true) == "Favorite Themes")
    }

    @Test func entryClearingTheFilterIsIndentedLikeTheThemes() {
        let item = ThemeMenuItem(theme: nil, indentLevel: 1, showingFavorites: false)

        #expect(item.displayName == "  All Themes")
    }
}
