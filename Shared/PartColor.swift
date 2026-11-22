//
//  PartColor.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/12/25.
//

import BRIQKit
import SwiftUI

extension PartColor {
    /// Stands in for a color id outside `AllPartColors`.
    static let unknown = PartColor(
        name: String(localized: "Unknown"), rgb: "000000", isTransparent: false,
        partsCount: 0, setsCount: 0, year1: nil, year2: nil
    )

    /// The color whose index in `AllPartColors` is `id`, or `unknown`.
    static func lookup(id: Int32) -> PartColor {
        let index = Int(id)
        return AllPartColors.indices.contains(index) ? AllPartColors[index] : unknown
    }

    var swiftUIColor: Color {
        let value = rgbValue
        return Color(red: value.red, green: value.green, blue: value.blue)
    }
}
