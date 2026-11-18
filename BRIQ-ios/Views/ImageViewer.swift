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
                    Button {
                        showFullImage = true
                    } label: {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show Full-Size Image")
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

/// The set image on black, fitted to the screen; pinch or double-tap to zoom
/// and scroll around the zoomed image.
struct FullSizeImageViewer: View {
    var set: Set
    @Environment(\.dismiss) private var dismiss
    /// The zoom once the last gesture ended; `pinch` is the one in progress.
    @State private var scale = ImageZoom.range.lowerBound
    @GestureState private var pinch: CGFloat = 1

    private var currentScale: CGFloat {
        ImageZoom.scale(scale, magnifiedBy: pinch)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    image
                        .frame(
                            width: geometry.size.width * currentScale,
                            height: geometry.size.height * currentScale
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = ImageZoom.scaleAfterDoubleTap(scale)
                            }
                        }
                }
                .simultaneousGesture(magnifyGesture)
            }
            .background(Color.black)
            .accessibilityZoomAction { action in
                let factor = action.direction == .zoomIn ? ImageZoom.step : 1 / ImageZoom.step
                scale = ImageZoom.scale(scale, magnifiedBy: factor)
            }
            .navigationTitle(set.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var image: some View {
        AsyncImage(url: URL(string: set.imageURL ?? "")) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text(set.name))
            } else if phase.error != nil {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Image Unavailable")
            } else {
                ProgressView()
            }
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                scale = ImageZoom.scale(scale, magnifiedBy: value.magnification)
            }
    }
}
