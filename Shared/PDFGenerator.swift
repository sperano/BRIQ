//
//  PDFGenerator.swift
//  BRIQ
//

import Foundation
import CoreGraphics
import OSLog

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

enum PDFGeneratorError: LocalizedError {
    case noImages
    case pdfCreationFailed
    case imageDownloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .noImages:
            return "No images to export"
        case .pdfCreationFailed:
            return "Failed to create PDF"
        case .imageDownloadFailed(let url):
            return "Failed to download image: \(url)"
        }
    }
}

/// Draws a parts list as a grid of images on US Letter pages. Each page's
/// images are downloaded a few at a time, decoded at the cell's print size
/// and released once the page is drawn.
actor PDFGenerator {
    private static let maxConcurrentDownloads = 6
    /// Resolution the images are decoded at, in dots per inch.
    private static let printResolution: CGFloat = 300
    private static let pointsPerInch: CGFloat = 72

    private let imageURLs: [URL?]
    private let columns: Int
    private let loader: ImageLoader

    // US Letter size in points (72 points per inch)
    private let pageWidth: CGFloat = 612  // 8.5 inches
    private let pageHeight: CGFloat = 792 // 11 inches
    private let margin: CGFloat = 36      // 0.5 inch margin

    /// `imageURLs` holds one entry per cell; a nil entry leaves its cell empty.
    init(imageURLs: [URL?], columns: Int, loader: ImageLoader = .shared) {
        self.imageURLs = imageURLs
        self.columns = columns
        self.loader = loader
    }

    func generate(progress: @escaping (Double, String) -> Void) async throws -> Data {
        guard !imageURLs.isEmpty else {
            throw PDFGeneratorError.noImages
        }

        // Calculate cell size based on columns
        let availableWidth = pageWidth - (margin * 2)
        let cellSize = availableWidth / CGFloat(columns)
        let rowsPerPage = Int((pageHeight - (margin * 2)) / cellSize)
        let partsPerPage = columns * rowsPerPage
        let maxPixelSize = Int((cellSize * Self.printResolution / Self.pointsPerInch).rounded(.up))

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFGeneratorError.pdfCreationFailed
        }

        let total = imageURLs.count
        let totalPages = (total + partsPerPage - 1) / partsPerPage

        for pageIndex in 0..<totalPages {
            let startIndex = pageIndex * partsPerPage
            let endIndex = min(startIndex + partsPerPage, total)
            progress(Double(startIndex) / Double(total), "Downloading images \(startIndex + 1)-\(endIndex) of \(total)...")

            let images = try await downloadImages(Array(imageURLs[startIndex..<endIndex]), maxPixelSize: maxPixelSize)
            try Task.checkCancellation()

            pdfContext.beginPDFPage(nil)
            drawGrid(in: pdfContext, cellSize: cellSize, rows: (images.count + columns - 1) / columns)
            drawImages(images, in: pdfContext, cellSize: cellSize)
            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        progress(1.0, "Complete")
        return pdfData as Data
    }

    /// Cut lines around the cells of the page's first `rows` rows.
    private func drawGrid(in pdfContext: CGContext, cellSize: CGFloat, rows: Int) {
        pdfContext.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
        pdfContext.setLineWidth(0.5)

        // Vertical lines
        for col in 0...columns {
            let x = margin + CGFloat(col) * cellSize
            let yStart = pageHeight - margin
            let yEnd = pageHeight - margin - CGFloat(rows) * cellSize
            pdfContext.move(to: CGPoint(x: x, y: yStart))
            pdfContext.addLine(to: CGPoint(x: x, y: yEnd))
        }

        // Horizontal lines
        for row in 0...rows {
            let y = pageHeight - margin - CGFloat(row) * cellSize
            let xStart = margin
            let xEnd = margin + CGFloat(columns) * cellSize
            pdfContext.move(to: CGPoint(x: xStart, y: y))
            pdfContext.addLine(to: CGPoint(x: xEnd, y: y))
        }

        pdfContext.strokePath()
    }

    private func drawImages(_ images: [CGImage?], in pdfContext: CGContext, cellSize: CGFloat) {
        for (indexOnPage, image) in images.enumerated() {
            guard let cgImage = image else { continue }
            let col = indexOnPage % columns
            let row = indexOnPage / columns

            let x = margin + CGFloat(col) * cellSize
            // PDF coordinate system has origin at bottom-left, so flip Y
            let y = pageHeight - margin - CGFloat(row + 1) * cellSize

            let imageRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
            let fittedRect = fitImageRect(imageSize: CGSize(width: cgImage.width, height: cgImage.height), in: imageRect)
            pdfContext.draw(cgImage, in: fittedRect)
        }
    }

    /// A cell whose image fails to download stays empty; cancellation is rethrown.
    private func downloadImages(_ urls: [URL?], maxPixelSize: Int) async throws -> [CGImage?] {
        let loader = self.loader
        return try await urls.concurrentMap(maxConcurrent: Self.maxConcurrentDownloads) { url -> CGImage? in
            guard let url else { return nil }
            do {
                return try await loader.downsampledImage(at: url, maxPixelSize: maxPixelSize)
            } catch where ImageLoader.isCancellation(error) {
                // URLSession reports a cancelled task as URLError(.cancelled).
                throw CancellationError()
            } catch {
                Logger.pdf.error("Failed to download image from \(url): \(error)")
                return nil
            }
        }
    }

    private func fitImageRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
        let padding: CGFloat = 4
        let availableRect = rect.insetBy(dx: padding, dy: padding)

        let imageAspect = imageSize.width / imageSize.height
        let rectAspect = availableRect.width / availableRect.height

        var fittedSize: CGSize
        if imageAspect > rectAspect {
            // Image is wider than rect
            fittedSize = CGSize(width: availableRect.width, height: availableRect.width / imageAspect)
        } else {
            // Image is taller than rect
            fittedSize = CGSize(width: availableRect.height * imageAspect, height: availableRect.height)
        }

        let x = availableRect.midX - fittedSize.width / 2
        let y = availableRect.midY - fittedSize.height / 2

        return CGRect(x: x, y: y, width: fittedSize.width, height: fittedSize.height)
    }
}
