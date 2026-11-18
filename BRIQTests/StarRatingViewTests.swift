//
//  StarRatingViewTests.swift
//  BRIQTests
//

import SwiftUI
import Testing
@testable import BRIQ

@Suite @MainActor struct StarRatingViewTests {
    @Test func tappingAnotherStarSetsTheRatingToIt() {
        #expect(StarRatingView.rating(afterTapping: 4, current: 2) == 4)
        #expect(StarRatingView.rating(afterTapping: 1, current: 0) == 1)
    }

    @Test func tappingTheStarOfTheCurrentRatingClearsIt() {
        #expect(StarRatingView.rating(afterTapping: 3, current: 3) == 0)
    }

    @Test func incrementAddsOneStar() {
        #expect(StarRatingView.rating(adjusting: 0, .increment) == 1)
        #expect(StarRatingView.rating(adjusting: 3, .increment) == 4)
    }

    @Test func incrementStopsAtTheMaximum() {
        #expect(StarRatingView.rating(adjusting: StarRatingView.maxRating, .increment) == StarRatingView.maxRating)
    }

    @Test func decrementRemovesOneStar() {
        #expect(StarRatingView.rating(adjusting: 3, .decrement) == 2)
        #expect(StarRatingView.rating(adjusting: 1, .decrement) == 0)
    }

    @Test func decrementStopsAtZero() {
        #expect(StarRatingView.rating(adjusting: 0, .decrement) == 0)
    }

    @Test func valueDescriptionNamesAMissingRating() {
        #expect(StarRatingView.valueDescription(rating: 0) == "Not rated")
    }

    @Test func valueDescriptionUsesTheSingularForOneStar() {
        #expect(StarRatingView.valueDescription(rating: 1) == "1 star")
    }

    @Test func valueDescriptionUsesThePluralForMoreStars() {
        #expect(StarRatingView.valueDescription(rating: 2) == "2 stars")
        #expect(StarRatingView.valueDescription(rating: 5) == "5 stars")
    }
}
