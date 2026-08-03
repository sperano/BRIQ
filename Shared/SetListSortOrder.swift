//
//  SetListSortOrder.swift
//  BRIQ
//
//  Created by Éric Spérano on 14/09/25.
//

import Foundation

enum SetListSortOrder: String, CaseIterable {
    case year = "year"
    case number = "number"
    case name = "name"
    case partsCount = "partsCount"

    var displayName: String {
        switch self {
        case .year:
            return "Year"
        case .number:
            return "Number"
        case .name:
            return "Name"
        case .partsCount:
            return "Parts Count"
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        // sortKey is the precomputed numeric form of the set number; "number"
        // remains as a final tiebreaker for non-numeric prefixes that all map
        // to sortKey 0.
        switch self {
        case .year:
            return [
                NSSortDescriptor(key: "year", ascending: true),
                NSSortDescriptor(key: "sortKey", ascending: true),
                NSSortDescriptor(key: "number", ascending: true)
            ]
        case .number:
            return [
                NSSortDescriptor(key: "sortKey", ascending: true),
                NSSortDescriptor(key: "number", ascending: true)
            ]
        case .name:
            return [
                NSSortDescriptor(key: "name", ascending: true),
                NSSortDescriptor(key: "sortKey", ascending: true)
            ]
        case .partsCount:
            return [
                NSSortDescriptor(key: "partsCount", ascending: false), // Descending for parts count (most parts first)
                NSSortDescriptor(key: "sortKey", ascending: true)
            ]
        }
    }
}
