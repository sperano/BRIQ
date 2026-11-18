//
//  ImageZoom.swift
//  BRIQ
//

import CoreGraphics

/// Zoom levels of the full-size set image (iOS `FullSizeImageViewer`), as
/// multiples of the size that fits the screen.
nonisolated enum ImageZoom {
    static let range: ClosedRange<CGFloat> = 1...4
    /// Where a double tap at the fitted size zooms to; also the factor of one
    /// VoiceOver zoom step.
    static let step: CGFloat = 2

    /// `scale` times a pinch's `magnification`, kept within `range`.
    static func scale(_ scale: CGFloat, magnifiedBy magnification: CGFloat) -> CGFloat {
        min(max(scale * magnification, range.lowerBound), range.upperBound)
    }

    /// A double tap fits a zoomed-in image back to the screen and zooms a
    /// fitted one in by `step`.
    static func scaleAfterDoubleTap(_ scale: CGFloat) -> CGFloat {
        scale > range.lowerBound ? range.lowerBound : self.scale(scale, magnifiedBy: step)
    }
}
