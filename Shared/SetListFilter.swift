//
//  SetListFilter.swift
//  BRIQ
//

import Foundation

/// The set list's filter state, reduced to the single place that knows how to
/// turn it into a fetch-request predicate.
struct SetListFilter {
    var searchText = ""
    var ownedState = 0 // 0=all, 1=owned, 2=not owned
    var favoriteState = 0 // 0=all, 1=favorite, 2=not favorite
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

        switch ownedState {
        case 1:
            predicates.append(NSPredicate(format: "userData.owned == YES"))
        case 2:
            predicates.append(NSPredicate(format: "userData.owned == NO OR userData == nil"))
        default:
            break
        }

        switch favoriteState {
        case 1:
            predicates.append(NSPredicate(format: "userData.favorite == YES"))
        case 2:
            predicates.append(NSPredicate(format: "userData.favorite == NO OR userData == nil"))
        default:
            break
        }

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
