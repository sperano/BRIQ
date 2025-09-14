//
//  StarRatingView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/25/25.
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int = 5
    let isInteractive: Bool
    
    init(rating: Binding<Int>, isInteractive: Bool = true) {
        self._rating = rating
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        if isInteractive {
                            if rating == star {
                                rating = 0  // Tap same star to clear
                            } else {
                                rating = star
                            }
                        }
                    }
            }
        }
    }
}

#if DEBUG
#Preview("Interactive") {
    @Previewable @State var rating1: Int = 3
    @Previewable @State var rating2: Int = 5
    @Previewable @State var rating3: Int = 0

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
    @Previewable @State var rating1: Int = 1
    @Previewable @State var rating2: Int = 3
    @Previewable @State var rating3: Int = 5

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
