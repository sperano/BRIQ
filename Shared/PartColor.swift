//
//  Color.swift
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

    var swiftUIColor: Color {
        let scanner = Scanner(string: rgb)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }

    #if DEBUG
    //static let blue = PartColor(name: "Blue", rgb:"0055BF", isTransparent: false, partsCount: 194982, setsCount: 47095, year1:1949, year2: 2025)
    //static let sampleData: [PartColor] = [blue]
    #endif
}
