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
        switch self {
        case .year:
            return [
                NSSortDescriptor(key: "year", ascending: true),
                NSSortDescriptor(key: "number", ascending: true)
            ]
        case .number:
            return [
                NSSortDescriptor(key: "number", ascending: true)
            ]
        case .name:
            return [
                NSSortDescriptor(key: "name", ascending: true),
                NSSortDescriptor(key: "number", ascending: true)
            ]
        case .partsCount:
            return [
                NSSortDescriptor(key: "partsCount", ascending: false), // Descending for parts count (most parts first)
                NSSortDescriptor(key: "number", ascending: true)
            ]
        }
    }
}
