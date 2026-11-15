//
//  ThumbnailImage.swift
//  BRIQ
//

import SwiftUI

/// What `ThumbnailImage` hands its content, like `AsyncImagePhase`.
enum ThumbnailPhase {
    case empty
    case success(Image)
    /// `retry` requests the URL again; nil when there is no URL.
    case failure(retry: (() -> Void)?)
}

/// `AsyncImage` replacement that loads through `ImageLoader.shared`: the image
/// is decoded at `size` points times the display scale and cached, and a URL
/// that cannot load is not requested again each time the view appears.
struct ThumbnailImage<Content: View>: View {
    let url: URL?
    let size: CGFloat
    @ViewBuilder let content: (ThumbnailPhase) -> Content

    @Environment(\.displayScale) private var displayScale
    @State private var loaded: (url: URL, image: Image)?
    @State private var failedURL: URL?
    @State private var reloadCount = 0

    var body: some View {
        content(phase)
            .task(id: ThumbnailRequest(url: url, maxPixelSize: maxPixelSize, reloadCount: reloadCount)) {
                await load()
            }
    }

    private var maxPixelSize: Int {
        Int((size * displayScale).rounded(.up))
    }

    private var phase: ThumbnailPhase {
        guard let url else { return .failure(retry: nil) }
        if let loaded, loaded.url == url {
            return .success(loaded.image)
        }
        return failedURL == url ? .failure(retry: { retry(url) }) : .empty
    }

    private func load() async {
        guard let url else { return }
        let image = await ImageLoader.shared.image(at: url, maxPixelSize: maxPixelSize)
        guard !Task.isCancelled else { return }
        if let image {
            loaded = (url, Image(decorative: image, scale: displayScale))
            failedURL = nil
        } else if loaded?.url != url {
            failedURL = url
        }
    }

    private func retry(_ url: URL) {
        Task {
            await ImageLoader.shared.forgetFailure(at: url)
            failedURL = nil
            reloadCount += 1
        }
    }
}

private nonisolated struct ThumbnailRequest: Equatable {
    let url: URL?
    let maxPixelSize: Int
    let reloadCount: Int
}
