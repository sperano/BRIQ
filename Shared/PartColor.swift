//
//  PartColor.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/12/25.
//

import SwiftUI

class PartColor: Identifiable, Sendable {
    let name: String
    let rgb: String
    let isTransparent: Bool
    let partsCount: Int
    let setsCount: Int
    let year1: Int?
    let year2: Int?

    init(name: String, rgb: String, isTransparent: Bool, partsCount: Int, setsCount: Int, year1: Int?, year2: Int?) {
        self.name = name
        self.rgb = rgb
        self.isTransparent = isTransparent
        self.partsCount = partsCount
        self.setsCount = setsCount
        self.year1 = year1
        self.year2 = year2
    }

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
        let scanner = Scanner(string: rgb)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
