//
//  PartColor.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/12/25.
//

/// A LEGO color, as listed in the auto-generated `AllPartColors`.
public final class PartColor: Identifiable, Sendable {
    public let name: String
    /// Six hex digits, `RRGGBB`.
    public let rgb: String
    public let isTransparent: Bool
    public let partsCount: Int
    public let setsCount: Int
    public let year1: Int?
    public let year2: Int?

    public init(
        name: String, rgb: String, isTransparent: Bool,
        partsCount: Int, setsCount: Int, year1: Int?, year2: Int?
    ) {
        self.name = name
        self.rgb = rgb
        self.isTransparent = isTransparent
        self.partsCount = partsCount
        self.setsCount = setsCount
        self.year1 = year1
        self.year2 = year2
    }

    /// `rgb` parsed into components.
    public var rgbValue: RGBColor {
        RGBColor(hex: rgb)
    }
}
