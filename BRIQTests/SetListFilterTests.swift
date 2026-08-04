//
//  SetListFilterTests.swift
//  BRIQTests
//

import Testing
import CoreData
@testable import BRIQ

@Suite @MainActor struct SetListFilterTests {
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
        #expect(try numbers(matching: SetListFilter()) == ["100-1", "200-1", "400-1"])

        // ...and with US numbers displayed, no predicate remains at all.
        var filter = SetListFilter()
        filter.displayUSNumbers = true
        #expect(filter.predicate() == nil)
    }

    @Test func ownedOnly() throws {
        var filter = SetListFilter()
        filter.ownedState = 1
        #expect(try numbers(matching: filter) == ["100-1"])
    }

    @Test func notOwnedIncludesSetsWithoutUserData() throws {
        var filter = SetListFilter()
        filter.ownedState = 2
        filter.displayUSNumbers = true
        #expect(try numbers(matching: filter) == ["200-1", "300-1", "400-1"])
    }

    @Test func favoritesOnly() throws {
        var filter = SetListFilter()
        filter.favoriteState = 1
        #expect(try numbers(matching: filter) == ["100-1"])
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
        #expect(try numbers(matching: filter) == ["100-1", "200-1"])

        filter.displayUSNumbers = true
        #expect(try numbers(matching: filter) == ["100-1", "200-1", "300-1"])
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
