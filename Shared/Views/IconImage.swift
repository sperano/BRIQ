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
