//
//  PartsListViewMode.swift
//  BRIQ
//

enum PartsListViewMode: Int, CaseIterable {
    case icon = 0
    case table = 1

    var displayName: String {
        switch self {
        case .icon: return "Icon"
        case .table: return "Table"
        }
    }

    var systemImage: String {
        switch self {
        case .icon: return "grid.circle"
        case .table: return "tablecells"
        }
    }
}
