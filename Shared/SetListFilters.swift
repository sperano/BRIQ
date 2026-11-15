//
//  SetListFilters.swift
//  BRIQ
//

import Foundation

/// `@AppStorage` keys of the set list filters, read by `SetList` and the
/// filter settings on both platforms.
enum SetListFilterKey {
    static let favoriteThemesOnly = "filterFavoriteThemes"
    static let ownership = "filterOwnedState"
    static let favorite = "filterFavoriteState"
    static let excludePackages = "excludePackages"
    static let excludeUnreleased = "excludeUnreleased"
    static let excludeAccessories = "excludeAccessories"
    static let displayUSNumbers = "displayUSNumbers"
}

/// Default value of each filter in `SetListFilterKey`: what an unset key
/// reads as, and what the settings' reset buttons restore.
enum SetListFilterDefault {
    static let favoriteThemesOnly = false
    static let ownership = OwnershipFilter.all
    static let favorite = FavoriteFilter.all
    static let excludePackages = true
    static let excludeUnreleased = true
    static let excludeAccessories = true
    static let displayUSNumbers = false
}

/// Raw values are persisted under `SetListFilterKey.ownership`.
enum OwnershipFilter: Int, CaseIterable {
    case all = 0
    case owned = 1
    case notOwned = 2

    var title: String {
        switch self {
        case .all: return "All Sets"
        case .owned: return "Owned Only"
        case .notOwned: return "Not Owned Only"
        }
    }

    /// Nil for `.all`; a set without user data counts as not owned.
    var predicate: NSPredicate? {
        switch self {
        case .all: return nil
        case .owned: return NSPredicate(format: "userData.owned == YES")
        case .notOwned: return NSPredicate(format: "userData.owned == NO OR userData == nil")
        }
    }
}

/// Raw values are persisted under `SetListFilterKey.favorite`.
enum FavoriteFilter: Int, CaseIterable {
    case all = 0
    case favorites = 1
    case notFavorites = 2

    var title: String {
        switch self {
        case .all: return "All Sets"
        case .favorites: return "Favorites Only"
        case .notFavorites: return "Not Favorites Only"
        }
    }

    /// Nil for `.all`; a set without user data counts as not a favorite.
    var predicate: NSPredicate? {
        switch self {
        case .all: return nil
        case .favorites: return NSPredicate(format: "userData.favorite == YES")
        case .notFavorites: return NSPredicate(format: "userData.favorite == NO OR userData == nil")
        }
    }
}
