//
//  SetNumber.swift
//  BRIQKit
//

import Foundation

/// Set numbers such as "6080-2": a base number and an optional variant suffix.
public enum SetNumber {
    /// Room for the variant suffix in a sort key: suffixes from here on share the last slot.
    static let sortKeySuffixRange: Int64 = 1000

    /// Numeric sort key derived from a set number like "6080-2": the base
    /// number scaled, plus the variant suffix (0 when absent, so "6080" sorts
    /// before "6080-1"). Precomputed so fetch requests can sort numerically.
    public static func sortKey(for number: String) -> Int64 {
        let components = number.components(separatedBy: "-")
        let base = Int64(components[0]) ?? 0
        let suffix = components.count > 1 ? Int64(components[1]) ?? 0 : 0
        return base * sortKeySuffixRange + min(suffix, sortKeySuffixRange - 1)
    }
}
