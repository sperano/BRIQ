//
//  SetListViewMode.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

/// How the set list is laid out. Raw values are persisted under the
/// `viewMode` key and keep the macOS values they had before the iOS and
/// macOS enums were merged; iOS used to store `list` as 1, which now reads
/// back as `split` and falls back to `icon` through `availableOrDefault`.
enum SetListViewMode: Int, CaseIterable {
    case icon = 0
    case split = 1
    case table = 2
    case list = 3

    /// The modes this platform offers, in menu order.
    static var availableCases: [SetListViewMode] {
        #if os(macOS)
        return [.icon, .split, .table]
        #else
        return [.icon, .list]
        #endif
    }

    /// `self` when this platform offers it, `.icon` otherwise.
    var availableOrDefault: SetListViewMode {
        Self.availableCases.contains(self) ? self : .icon
    }

    var displayName: String {
        switch self {
        case .icon: return "Icon"
        case .split: return "Split"
        case .table: return "Table"
        case .list: return "List"
        }
    }

    var systemImage: String {
        switch self {
        case .icon: return "grid.circle"
        case .split: return "sidebar.left"
        case .table: return "tablecells"
        case .list: return "list.bullet"
        }
    }
}
