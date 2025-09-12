//
//  SetImageDisplay.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct SetImageDisplay: View {
    let set: Set
    
    var body: some View {
        #if os(iOS)
        ImageViewer(set: set)
        #elseif os(macOS)
        AsyncImage(url: URL(string: set.imageURL ?? "")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(maxHeight: 500, alignment: .leading)
            case .failure:
                Image(systemName: "xmark.octagon")
            @unknown default:
                EmptyView()
            }
        }
        #endif
    }
}
