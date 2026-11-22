//
//  RGBColorTests.swift
//  BRIQKitTests
//

import BRIQKit
import Testing

struct RGBColorTests {
    private static let tolerance = 1e-12

    @Test func parsesEachChannel() {
        #expect(RGBColor(hex: "C91A09") == RGBColor(red: 201 / 255, green: 26 / 255, blue: 9 / 255))
    }

    @Test func parsesLowercaseDigits() {
        #expect(RGBColor(hex: "c91a09") == RGBColor(hex: "C91A09"))
    }

    @Test func nonHexStringIsBlack() {
        #expect(RGBColor(hex: "zzzzzz") == RGBColor(red: 0, green: 0, blue: 0))
        #expect(RGBColor(hex: "") == RGBColor(red: 0, green: 0, blue: 0))
    }

    @Test func partColorParsesItsRGB() {
        let color = PartColor(
            name: "Red", rgb: "FF0000", isTransparent: false,
            partsCount: 0, setsCount: 0, year1: nil, year2: nil
        )
        #expect(color.rgbValue == RGBColor(red: 1, green: 0, blue: 0))
    }

    @Test func luminanceWeighsChannels() {
        #expect(RGBColor(hex: "000000").luminance == 0)
        #expect(abs(RGBColor(hex: "FFFFFF").luminance - 1) < Self.tolerance)
        #expect(abs(RGBColor(hex: "FF0000").luminance - 0.299) < Self.tolerance)
        #expect(abs(RGBColor(hex: "00FF00").luminance - 0.587) < Self.tolerance)
        #expect(abs(RGBColor(hex: "0000FF").luminance - 0.114) < Self.tolerance)
    }
}
