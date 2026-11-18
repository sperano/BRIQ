//
//  PartsListViewMode.swift
//  BRIQ
//

import Foundation

enum PartsListViewMode: Int, CaseIterable {
    case icon = 0
    case table = 1

    var displayName: String {
        switch self {
        case .icon: String(localized: "Icon", comment: "View mode")
        case .table: String(localized: "Table", comment: "View mode")
        }
    }

    var systemImage: String {
        switch self {
        case .icon: "grid.circle"
        case .table: "tablecells"
        }
    }
}
