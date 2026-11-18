//
//  SetListSortOrder.swift
//  BRIQ
//
//  Created by Éric Spérano on 14/09/25.
//

import Foundation

enum SetListSortOrder: String, CaseIterable {
    case year
    case number
    case name
    case partsCount

    var displayName: String {
        switch self {
        case .year:
            String(localized: "Year", comment: "Sort order")
        case .number:
            String(localized: "Number", comment: "Sort order")
        case .name:
            String(localized: "Name", comment: "Sort order")
        case .partsCount:
            String(localized: "Parts Count", comment: "Sort order")
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        // sortKey is the precomputed numeric form of the set number; "number"
        // remains as a final tiebreaker for non-numeric prefixes that all map
        // to sortKey 0.
        switch self {
        case .year:
            [
                NSSortDescriptor(key: "year", ascending: true),
                NSSortDescriptor(key: "sortKey", ascending: true),
                NSSortDescriptor(key: "number", ascending: true),
            ]
        case .number:
            [
                NSSortDescriptor(key: "sortKey", ascending: true),
                NSSortDescriptor(key: "number", ascending: true),
            ]
        case .name:
            [
                NSSortDescriptor(key: "name", ascending: true),
                NSSortDescriptor(key: "sortKey", ascending: true),
            ]
        case .partsCount:
            [
                NSSortDescriptor(key: "partsCount", ascending: false), // Descending for parts count (most parts first)
                NSSortDescriptor(key: "sortKey", ascending: true),
            ]
        }
    }
}
