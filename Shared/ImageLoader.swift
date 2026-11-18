//
//  ImageLoader.swift
//  BRIQ
//

import CoreGraphics
import Foundation
import ImageIO
import OSLog

nonisolated enum ImageLoaderError: Error, Equatable {
    case badStatus(Int)
    case undecodable
}

/// Downloads images and decodes them with ImageIO at the pixel size they are
/// drawn at, so a 100-point cell never decodes a full-resolution photo.
///
/// `image(at:maxPixelSize:)` keeps the result in memory and remembers URLs
/// that can never load (an HTTP client error, data that is not an image, a
/// malformed URL), so a cell scrolling back into view does not request them
/// again. Network errors, server errors, 408 and 429 are not remembered: the
/// next appearance tries again.
actor ImageLoader {
    static let shared = ImageLoader()

    /// Decoded pixels kept in memory, in bytes.
    private nonisolated static let memoryCacheCostLimit = 128 * 1024 * 1024
    /// Encoded responses kept by the URL cache, in bytes.
    private nonisolated static let urlCacheMemoryCapacity = 16 * 1024 * 1024
    private nonisolated static let urlCacheDiskCapacity = 256 * 1024 * 1024
    private nonisolated static let successStatusCodes = 200..<300
    private nonisolated static let permanentURLErrors: Swift.Set<URLError.Code> = [.badURL, .unsupportedURL]
    private nonisolated static let clientErrorStatusCodes = 400..<500
    /// Client errors that a later request can get past: Request Timeout and
    /// Too Many Requests.
    private nonisolated static let transientClientErrorStatusCodes: Swift.Set<Int> = [408, 429]

    private let session: URLSession
    private let cache = NSCache<NSURL, CachedImage>()
    private var failedURLs: Swift.Set<URL> = []

    init(session: URLSession = ImageLoader.makeDefaultSession()) {
        self.session = session
        cache.totalCostLimit = Self.memoryCacheCostLimit
    }

    /// The image at `url`, at most `maxPixelSize` pixels on its longer side.
    /// A cached copy at least that large is reused. When the image cannot be
    /// loaded or the calling task is cancelled, the cached copy at a smaller
    /// size is returned, or nil when there is none.
    func image(at url: URL, maxPixelSize: Int) async -> CGImage? {
        let cached = cache.object(forKey: url as NSURL)
        if let cached, cached.pixelSize >= maxPixelSize {
            return cached.image
        }
        guard !failedURLs.contains(url) else { return cached?.image }
        do {
            let image = try await downsampledImage(at: url, maxPixelSize: maxPixelSize)
            store(image, pixelSize: maxPixelSize, for: url)
            return image
        } catch {
            if !Self.isCancellation(error) {
                Logger.images.error("Failed to load image from \(url): \(error)")
                if Self.isPermanent(error) {
                    failedURLs.insert(url)
                }
            }
            return cached?.image
        }
    }

    /// Lets `image(at:maxPixelSize:)` request a URL that failed before.
    func forgetFailure(at url: URL) {
        failedURLs.remove(url)
    }

    /// Downloads `url` and decodes it at most `maxPixelSize` pixels on its
    /// longer side, bypassing the memory cache and the failure list.
    @concurrent
    nonisolated func downsampledImage(at url: URL, maxPixelSize: Int) async throws -> CGImage {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !Self.successStatusCodes.contains(http.statusCode) {
            throw ImageLoaderError.badStatus(http.statusCode)
        }
        guard let image = Self.downsample(data, maxPixelSize: maxPixelSize) else {
            throw ImageLoaderError.undecodable
        }
        return image
    }

    nonisolated static func downsample(_ data: Data, maxPixelSize: Int) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
    }

    private func store(_ image: CGImage, pixelSize: Int, for url: URL) {
        // A concurrent request for a larger size may have finished first.
        if let existing = cache.object(forKey: url as NSURL), existing.pixelSize >= pixelSize {
            return
        }
        let entry = CachedImage(image: image, pixelSize: pixelSize)
        cache.setObject(entry, forKey: url as NSURL, cost: image.bytesPerRow * image.height)
    }

    nonisolated static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    /// Errors that will repeat on every request: the URL is remembered as failed.
    nonisolated static func isPermanent(_ error: Error) -> Bool {
        switch error as? ImageLoaderError {
        case .badStatus(let status):
            return clientErrorStatusCodes.contains(status) && !transientClientErrorStatusCodes.contains(status)
        case .undecodable:
            return true
        case nil:
            break
        }
        guard let code = (error as? URLError)?.code else { return false }
        return permanentURLErrors.contains(code)
    }

    nonisolated static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: urlCacheMemoryCapacity,
            diskCapacity: urlCacheDiskCapacity
        )
        return URLSession(configuration: configuration)
    }
}

/// `pixelSize` is the size that was requested, not the decoded one: an
/// original smaller than the request is not fetched again for the same size.
private final nonisolated class CachedImage {
    let image: CGImage
    let pixelSize: Int

    init(image: CGImage, pixelSize: Int) {
        self.image = image
        self.pixelSize = pixelSize
    }
}
