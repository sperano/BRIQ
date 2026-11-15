//
//  SetListFiltersTests.swift
//  BRIQTests
//

import Foundation
import Testing
@testable import BRIQ

/// Evaluates the filter predicates against key-value stand-ins for a set:
/// `userData` missing models a set the user never marked.
@MainActor
struct SetListFiltersTests {
    private let owned: [String: Any] = ["userData": ["owned": true, "favorite": false]]
    private let notOwned: [String: Any] = ["userData": ["owned": false, "favorite": true]]
    private let noUserData: [String: Any] = [:]

    private func matches(_ predicate: NSPredicate?, _ set: [String: Any]) -> Bool {
        predicate?.evaluate(with: set) ?? true
    }

    @Test func allFiltersHaveNoPredicate() {
        #expect(OwnershipFilter.all.predicate == nil)
        #expect(FavoriteFilter.all.predicate == nil)
    }

    @Test func ownedKeepsOnlyOwnedSets() {
        let predicate = OwnershipFilter.owned.predicate
        #expect(matches(predicate, owned))
        #expect(!matches(predicate, notOwned))
        #expect(!matches(predicate, noUserData))
    }

    @Test func notOwnedKeepsUnownedSetsAndSetsWithoutUserData() {
        let predicate = OwnershipFilter.notOwned.predicate
        #expect(!matches(predicate, owned))
        #expect(matches(predicate, notOwned))
        #expect(matches(predicate, noUserData))
    }

    @Test func favoritesKeepsOnlyFavoriteSets() {
        let predicate = FavoriteFilter.favorites.predicate
        #expect(matches(predicate, notOwned))
        #expect(!matches(predicate, owned))
        #expect(!matches(predicate, noUserData))
    }

    @Test func notFavoritesKeepsOtherSetsAndSetsWithoutUserData() {
        let predicate = FavoriteFilter.notFavorites.predicate
        #expect(!matches(predicate, notOwned))
        #expect(matches(predicate, owned))
        #expect(matches(predicate, noUserData))
    }

    /// The raw values are what earlier builds stored under these keys.
    @Test func storedRawValuesKeepTheirMeaning() {
        #expect(OwnershipFilter(rawValue: 0) == .all)
        #expect(OwnershipFilter(rawValue: 1) == .owned)
        #expect(OwnershipFilter(rawValue: 2) == .notOwned)
        #expect(FavoriteFilter(rawValue: 0) == .all)
        #expect(FavoriteFilter(rawValue: 1) == .favorites)
        #expect(FavoriteFilter(rawValue: 2) == .notFavorites)
    }

    @Test func keysAreTheOnesEarlierBuildsStored() {
        #expect(SetListFilterKey.favoriteThemesOnly == "filterFavoriteThemes")
        #expect(SetListFilterKey.ownership == "filterOwnedState")
        #expect(SetListFilterKey.favorite == "filterFavoriteState")
        #expect(SetListFilterKey.excludePackages == "excludePackages")
        #expect(SetListFilterKey.excludeUnreleased == "excludeUnreleased")
        #expect(SetListFilterKey.excludeAccessories == "excludeAccessories")
        #expect(SetListFilterKey.displayUSNumbers == "displayUSNumbers")
    }
}
