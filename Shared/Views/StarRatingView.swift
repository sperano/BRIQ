//
//  StarRatingView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/25/25.
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    nonisolated static let maxRating = 5
    let isInteractive: Bool
    /// What VoiceOver calls the rating.
    let label: LocalizedStringKey

    init(rating: Binding<Int>, isInteractive: Bool = true, label: LocalizedStringKey = "Rating") {
        _rating = rating
        self.isInteractive = isInteractive
        self.label = label
    }

    var body: some View {
        let stars = HStack(spacing: 4) {
            ForEach(1...Self.maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        if isInteractive {
                            rating = Self.rating(afterTapping: star, current: rating)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Self.valueDescription(rating: rating))

        if isInteractive {
            stars.accessibilityAdjustableAction { direction in
                rating = Self.rating(adjusting: rating, direction)
            }
        } else {
            stars
        }
    }

    /// Tapping the star of the current rating clears it.
    static func rating(afterTapping star: Int, current: Int) -> Int {
        star == current ? 0 : star
    }

    /// VoiceOver's increment and decrement, kept within `0...maxRating`.
    static func rating(adjusting rating: Int, _ direction: AccessibilityAdjustmentDirection) -> Int {
        switch direction {
        case .increment: min(rating + 1, maxRating)
        case .decrement: max(rating - 1, 0)
        @unknown default: rating
        }
    }

    static func valueDescription(rating: Int) -> String {
        rating == 0
            ? String(localized: "Not rated", comment: "Star rating of zero stars")
            : String(localized: "\(rating) stars", comment: "Star rating")
    }
}

#if DEBUG
#Preview("Interactive") {
    @Previewable @State var rating1 = 3
    @Previewable @State var rating2 = 5
    @Previewable @State var rating3 = 0

    VStack(spacing: 20) {
        Text("Interactive Star Rating")
            .font(.headline)

        VStack {
            Text("Rating: \(rating1)")
            StarRatingView(rating: $rating1, isInteractive: true)
        }

        VStack {
            Text("Rating: \(rating2)")
            StarRatingView(rating: $rating2, isInteractive: true)
        }

        VStack {
            Text("Rating: \(rating3)")
            StarRatingView(rating: $rating3, isInteractive: true)
        }
    }
    .padding()
}

#Preview("Non-Interactive") {
    @Previewable @State var rating1 = 1
    @Previewable @State var rating2 = 3
    @Previewable @State var rating3 = 5

    VStack(spacing: 20) {
        Text("Non-Interactive Star Rating")
            .font(.headline)

        VStack {
            Text("Rating: \(rating1)")
            StarRatingView(rating: $rating1, isInteractive: false)
        }

        VStack {
            Text("Rating: \(rating2)")
            StarRatingView(rating: $rating2, isInteractive: false)
        }

        VStack {
            Text("Rating: \(rating3)")
            StarRatingView(rating: $rating3, isInteractive: false)
        }
    }
    .padding()
}
#endif
