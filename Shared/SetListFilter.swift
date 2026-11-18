//
//  SetListFilter.swift
//  BRIQ
//

import Foundation

/// The set list's filter state, reduced to the single place that knows how to
/// turn it into a fetch-request predicate.
struct SetListFilter {
    var searchText = ""
    var ownership = OwnershipFilter.all
    var favorite = FavoriteFilter.all
    var filterFavoriteThemes = false
    var favoriteThemes: Swift.Set<Int> = []
    var selectedTheme: Theme?
    var excludePackages = false
    var excludeUnreleased = false
    var excludeAccessories = false
    var displayUSNumbers = false

    func predicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            predicates.append(NSPredicate(
                format: "number CONTAINS[cd] %@ OR name CONTAINS[cd] %@", searchText, searchText
            ))
        }

        if let ownershipPredicate = ownership.predicate {
            predicates.append(ownershipPredicate)
        }
        if let favoritePredicate = favorite.predicate {
            predicates.append(favoritePredicate)
        }

        if let selectedTheme {
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

        if excludePackages {
            predicates.append(NSPredicate(format: "isPack == NO"))
        }
        if excludeUnreleased {
            predicates.append(NSPredicate(format: "isUnreleased == NO"))
        }
        if excludeAccessories {
            predicates.append(NSPredicate(format: "isAccessory == NO"))
        }
        if !displayUSNumbers {
            predicates.append(NSPredicate(format: "isUSNumber == NO"))
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
