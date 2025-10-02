//
//  SetListViewMode.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

enum SetListViewMode: Int, CaseIterable {
    case icon = 0
    case split = 1
    case table = 2
    
    var displayName: String {
        switch self {
        case .icon: return "Icon"
        case .split: return "Split"
        case .table: return "Table"
        }
    }
    
    var systemImage: String {
        switch self {
        case .icon: return "grid.circle"
        case .split: return "sidebar.left"
        case .table: return "tablecells"
        }
    }
    
}
