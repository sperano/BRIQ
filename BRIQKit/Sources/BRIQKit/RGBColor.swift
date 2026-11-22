//
//  RGBColor.swift
//  BRIQKit
//

import Foundation

/// A color as red, green and blue components from 0 to 1.
public struct RGBColor: Equatable, Sendable {
    private static let channelMax = 255.0
    private static let redShift: UInt64 = 16
    private static let greenShift: UInt64 = 8
    private static let channelMask: UInt64 = 0xFF

    // Rec. 601 luma weights.
    private static let redWeight = 0.299
    private static let greenWeight = 0.587
    private static let blueWeight = 0.114

    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Parses `RRGGBB` hex digits. Only the leading hex digits count; a string that starts with
    /// none is black.
    public init(hex: String) {
        let value = Scanner(string: hex).scanUInt64(representation: .hexadecimal) ?? 0
        func channel(_ shift: UInt64) -> Double {
            Double((value >> shift) & Self.channelMask) / Self.channelMax
        }
        self.init(red: channel(Self.redShift), green: channel(Self.greenShift), blue: channel(0))
    }

    /// Perceived brightness, from 0 (black) to 1 (white).
    public var luminance: Double {
        Self.redWeight * red + Self.greenWeight * green + Self.blueWeight * blue
    }
}
