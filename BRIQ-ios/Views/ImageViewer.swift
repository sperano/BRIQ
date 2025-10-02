//
//  ImageViewer.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/28/25.
//

import SwiftUI

struct ImageViewer: View {
    @State private var showFullImage = false
    var set: Set

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: set.imageURL ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        //.frame(width: geometry.size.width)
                        .onTapGesture {
                            showFullImage = true
                        }
                } else if phase.error != nil {
                    Color(.red) // or a placeholder image
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showFullImage) {
            FullSizeImageViewer(set: set)
        }
    }
}

struct FullSizeImageViewer: View {
    var set: Set
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                AsyncImage(url: URL(string: set.imageURL ?? "")) { phase in // TODO
                    if let image = phase.image {
                        image
                            .resizable()
                            //.aspectRatio(contentMode: .none)
                            .scaledToFill()
                            //.scaledToFit()
                            //.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .padding()
                        .foregroundColor(.white)
                }
            }
            .background(Color.black)
        }
    }
}
