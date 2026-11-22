//
//  SetListFilterTests.swift
//  BRIQTests
//

import BRIQKit
import CoreData
import Testing
@testable import BRIQ

@MainActor struct SetListFilterTests {
    let stack = CoreDataStack(inMemory: true)

    init() throws {
        let context = stack.viewContext

        let owned = Set.create(
            in: context, number: "100-1", isUSNumber: false, name: "Castle",
            year: 1984, imageURL: nil, partsCount: 0, themeID: 1
        )
        let userData = SetUserData.create(in: context, number: "100-1", owned: true, favorite: true)
        userData.set = owned
        owned.userData = userData

        _ = Set.create(
            in: context, number: "200-1", isUSNumber: false, name: "Spaceship",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 2
        )
        _ = Set.create(
            in: context, number: "300-1", isUSNumber: true, name: "US Variant",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 2
        )
        _ = Set.create(
            in: context, number: "400-1", isUSNumber: false, name: "Pack",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 3, isPack: true
        )
        _ = Set.create(
            in: context, number: "500-1", isUSNumber: false, name: "Unreleased",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 3, isUnreleased: true
        )
        _ = Set.create(
            in: context, number: "600-1", isUSNumber: false, name: "Accessory",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 3, isAccessory: true
        )
        let notFavorite = Set.create(
            in: context, number: "700-1", isUSNumber: false, name: "Owned, not favorite",
            year: 1990, imageURL: nil, partsCount: 0, themeID: 3
        )
        let notFavoriteData = SetUserData.create(in: context, number: "700-1", owned: true)
        notFavoriteData.set = notFavorite
        notFavorite.userData = notFavoriteData

        try context.save()
    }

    private func numbers(matching filter: SetListFilter) throws -> [String] {
        let request = Set.fetchRequest()
        request.predicate = filter.predicate()
        request.sortDescriptors = [NSSortDescriptor(key: "sortKey", ascending: true)]
        return try stack.viewContext.fetch(request).map(\.number)
    }

    @Test func emptyFilterOnlyHidesUSNumbers() throws {
        // The default filter still hides US-number variants...
        #expect(try numbers(matching: SetListFilter()) == ["100-1", "200-1", "400-1", "500-1", "600-1", "700-1"])

        // ...and with US numbers displayed, no predicate remains at all.
        var filter = SetListFilter()
        filter.displayUSNumbers = true
        #expect(filter.predicate() == nil)
    }

    @Test func ownedOnly() throws {
        var filter = SetListFilter()
        filter.ownership = .owned
        #expect(try numbers(matching: filter) == ["100-1", "700-1"])
    }

    @Test func notOwnedIncludesSetsWithoutUserData() throws {
        var filter = SetListFilter()
        filter.ownership = .notOwned
        filter.displayUSNumbers = true
        #expect(try numbers(matching: filter) == ["200-1", "300-1", "400-1", "500-1", "600-1"])
    }

    @Test func favoritesOnly() throws {
        var filter = SetListFilter()
        filter.favorite = .favorites
        #expect(try numbers(matching: filter) == ["100-1"])
    }

    @Test func notFavoriteIncludesSetsWithoutUserData() throws {
        var filter = SetListFilter()
        filter.favorite = .notFavorites
        filter.displayUSNumbers = true
        #expect(try numbers(matching: filter) == ["200-1", "300-1", "400-1", "500-1", "600-1", "700-1"])
    }

    @Test func searchMatchesNumberOrNameCaseInsensitively() throws {
        var filter = SetListFilter()
        filter.displayUSNumbers = true
        filter.searchText = "space"
        #expect(try numbers(matching: filter) == ["200-1"])

        filter.searchText = "300"
        #expect(try numbers(matching: filter) == ["300-1"])
    }

    @Test func exclusionsAndUSNumbers() throws {
        var filter = SetListFilter()
        filter.excludePackages = true
        // displayUSNumbers defaults to false, which hides US variants
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "500-1", "600-1", "700-1"])

        filter.displayUSNumbers = true
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "300-1", "500-1", "600-1", "700-1"])
    }

    @Test func excludeUnreleased() throws {
        var filter = SetListFilter()
        filter.excludeUnreleased = true
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "400-1", "600-1", "700-1"])
    }

    @Test func excludeAccessories() throws {
        var filter = SetListFilter()
        filter.excludeAccessories = true
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "400-1", "500-1", "700-1"])
    }

    @Test func favoriteThemesFilter() throws {
        var filter = SetListFilter()
        filter.displayUSNumbers = true
        filter.filterFavoriteThemes = true
        filter.favoriteThemes = [2]
        #expect(try numbers(matching: filter) == ["200-1", "300-1"])
    }

    @Test func selectedThemeIncludesChildThemes() throws {
        let parent = Theme(id: 1, name: "Parent")
        let child = Theme(id: 2, name: "Child")
        child.parent = parent
        parent.children = [child]

        var filter = SetListFilter()
        filter.displayUSNumbers = true
        filter.selectedTheme = parent
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "300-1"])
    }

    @Test func selectedThemeIntersectsFavorites() throws {
        let parent = Theme(id: 1, name: "Parent")
        let child = Theme(id: 2, name: "Child")
        child.parent = parent
        parent.children = [child]

        var filter = SetListFilter()
        filter.displayUSNumbers = true
        filter.selectedTheme = parent
        filter.filterFavoriteThemes = true
        filter.favoriteThemes = [2]
        #expect(try numbers(matching: filter) == ["200-1", "300-1"])
    }
}
