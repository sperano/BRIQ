//
//  IconImage.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct IconImage: View {
    let url: String
    @State private var retryCount = 0
    @State private var imageKey = 0
    
    private let maxRetries = 3
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.title2)
                    if retryCount < maxRetries {
                        Button("Retry") {
                            retryLoad()
                        }
                        .font(.caption)
                        .padding(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
                .onAppear {
                    if retryCount < maxRetries {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            retryLoad()
                        }
                    }
                }
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            @unknown default:
                Color.gray.opacity(0.2)
            }
        }
        .id(imageKey)
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func retryLoad() {
        retryCount += 1
        imageKey += 1
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

