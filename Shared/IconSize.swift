//
//  IconSize.swift
//  BRIQ
//

import Foundation

/// The icon size set by the set list's toolbar slider, in points. Stored in
/// `UserDefaults` so the parts and minifig grids (`IconGridView`) follow it too.
nonisolated enum IconSize {
    static let storageKey = "iconSize"
    static let defaultSize: Double = 120
}
