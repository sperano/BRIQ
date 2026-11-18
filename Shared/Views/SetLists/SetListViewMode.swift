//
//  SetListViewMode.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation

/// How the set list is laid out. Raw values are persisted under the
/// `viewMode` key and keep the macOS values they had before the iOS and
/// macOS enums were merged; iOS used to store `list` as 1, which now reads
/// back as `split` and falls back to `icon` through `availableOrDefault`.
enum SetListViewMode: Int, CaseIterable {
    case icon = 0
    case split = 1
    case table = 2
    case list = 3

    #if os(macOS)
    private static let isMacOS = true
    #else
    private static let isMacOS = false
    #endif

    /// The modes this platform offers, in menu order.
    static var availableCases: [SetListViewMode] {
        availableCases(macOS: isMacOS)
    }

    /// `self` when this platform offers it, `.icon` otherwise.
    var availableOrDefault: SetListViewMode {
        availableOrDefault(macOS: Self.isMacOS)
    }

    /// The modes macOS (`macOS`) or iOS offers, in menu order.
    static func availableCases(macOS: Bool) -> [SetListViewMode] {
        macOS ? [.icon, .split, .table] : [.icon, .list]
    }

    /// `self` when macOS (`macOS`) or iOS offers it, `.icon` otherwise.
    func availableOrDefault(macOS: Bool) -> SetListViewMode {
        Self.availableCases(macOS: macOS).contains(self) ? self : .icon
    }

    var displayName: String {
        switch self {
        case .icon: String(localized: "Icon", comment: "View mode")
        case .split: String(localized: "Split", comment: "View mode")
        case .table: String(localized: "Table", comment: "View mode")
        case .list: String(localized: "List", comment: "View mode")
        }
    }

    /// The View menu command choosing this mode.
    var commandTitle: String {
        switch self {
        case .icon: String(localized: "Icon View", comment: "View menu command")
        case .split: String(localized: "Split View", comment: "View menu command")
        case .table: String(localized: "Table View", comment: "View menu command")
        case .list: String(localized: "List View", comment: "View menu command")
        }
    }

    var systemImage: String {
        switch self {
        case .icon: "grid.circle"
        case .split: "sidebar.left"
        case .table: "tablecells"
        case .list: "list.bullet"
        }
    }
}
