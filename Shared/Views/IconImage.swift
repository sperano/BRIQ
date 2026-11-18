//
//  IconImage.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct IconImage: View {
    let url: String?
    var size: CGFloat = IconSize.defaultSize

    private static let cornerRadius: CGFloat = 8

    var body: some View {
        ThumbnailImage(url: url.flatMap(URL.init(string:)), size: size) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure(let retry):
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.title2)
                    if let retry {
                        Button("Retry", action: retry)
                            .font(.caption)
                            .padding(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }
}

#if DEBUG
#Preview("Success") {
    VStack(spacing: 16) {
        Text("Working Image URLs")
            .font(.headline)

        HStack(spacing: 16) {
            IconImage(url: "https://cdn.rebrickable.com/media/sets/75192-1/79845.jpg")
            IconImage(url: "https://cdn.rebrickable.com/media/sets/10221-1/50693.jpg")
            IconImage(url: "https://cdn.rebrickable.com/media/sets/21108-1/95854.jpg")
        }
    }
    .padding()
}

#Preview("Failure States") {
    VStack(spacing: 16) {
        Text("Failed/Invalid URLs")
            .font(.headline)

        HStack(spacing: 16) {
            IconImage(url: "https://invalid-url-example.com/nonexistent.jpg")
            IconImage(url: "https://cdn.rebrickable.com/media/sets/invalid-set.jpg")
            IconImage(url: "not-a-valid-url")
            IconImage(url: nil)
        }
    }
    .padding()
}

#Preview("Mixed States") {
    VStack(spacing: 16) {
        Text("Mixed Loading States")
            .font(.headline)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            IconImage(url: "https://cdn.rebrickable.com/media/sets/10030-1/95902.jpg")
            IconImage(url: "https://invalid-url.com/test.jpg")
            IconImage(url: "https://cdn.rebrickable.com/media/sets/4195-1/34322.jpg")
            IconImage(url: "broken-url")
            IconImage(url: "https://cdn.rebrickable.com/media/sets/7965-1/85539.jpg")
            IconImage(url: "https://example.com/nonexistent.jpg")
        }
    }
    .padding()
}
#endif
