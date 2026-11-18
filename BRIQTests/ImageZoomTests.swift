//
//  ImageZoomTests.swift
//  BRIQTests
//

import CoreGraphics
import Testing
@testable import BRIQ

struct ImageZoomTests {
    @Test func pinchMultipliesTheScale() {
        #expect(ImageZoom.scale(1, magnifiedBy: 1.5) == 1.5)
        #expect(ImageZoom.scale(3, magnifiedBy: 0.5) == 1.5)
    }

    @Test func pinchingInStopsAtTheLargestZoom() {
        #expect(ImageZoom.scale(3, magnifiedBy: 2) == ImageZoom.range.upperBound)
    }

    @Test func pinchingOutStopsAtTheFittedSize() {
        #expect(ImageZoom.scale(1.5, magnifiedBy: 0.25) == ImageZoom.range.lowerBound)
    }

    @Test func doubleTapZoomsAFittedImageInByOneStep() {
        #expect(ImageZoom.scaleAfterDoubleTap(1) == 2)
    }

    @Test func doubleTapFitsAZoomedImageBack() {
        #expect(ImageZoom.scaleAfterDoubleTap(1.2) == 1)
        #expect(ImageZoom.scaleAfterDoubleTap(4) == 1)
    }
}
