//
//  SetListViewMode.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

enum SetListViewMode: Int, CaseIterable {
    case icon = 0
    case list = 1
    
    var displayName: String {
        switch self {
        case .icon: return "Icon"
        case .list: return "List"
        }
    }
    
    var systemImage: String {
        switch self {
        case .icon: return "grid.circle"
        case .list: return "tablecells" // TODO icon
        }
    }
    
}
