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
