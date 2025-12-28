//
//  PDFGenerator.swift
//  BRIQ
//

import Foundation
import CoreGraphics
import ImageIO

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

actor PDFGenerator {
    private let parts: [PartsListPart]
    private let columns: Int

    // US Letter size in points (72 points per inch)
    private let pageWidth: CGFloat = 612  // 8.5 inches
    private let pageHeight: CGFloat = 792 // 11 inches
    private let margin: CGFloat = 36      // 0.5 inch margin

    init(parts: [PartsListPart], columns: Int) {
        self.parts = parts
        self.columns = columns
    }

    func generate(progress: @escaping (Double, String) -> Void) async throws -> Data {
        guard !parts.isEmpty else {
            throw PDFGeneratorError.noImages
        }

        // Calculate cell size based on columns
        let availableWidth = pageWidth - (margin * 2)
        let cellSize = availableWidth / CGFloat(columns)
        let rowsPerPage = Int((pageHeight - (margin * 2)) / cellSize)
        let partsPerPage = columns * rowsPerPage

        // Download all images first
        progress(0, "Downloading images...")
        let images = try await downloadImages(progress: progress)

        progress(0.9, "Creating PDF...")

        // Create PDF
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFGeneratorError.pdfCreationFailed
        }

        let totalPages = (images.count + partsPerPage - 1) / partsPerPage

        for pageIndex in 0..<totalPages {
            pdfContext.beginPDFPage(nil)

            let startIndex = pageIndex * partsPerPage
            let endIndex = min(startIndex + partsPerPage, images.count)

            // Calculate actual rows on this page
            let partsOnPage = endIndex - startIndex
            let rowsOnPage = (partsOnPage + columns - 1) / columns

            // Draw cut lines (grid)
            pdfContext.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
            pdfContext.setLineWidth(0.5)

            // Vertical lines
            for col in 0...columns {
                let x = margin + CGFloat(col) * cellSize
                let yStart = pageHeight - margin
                let yEnd = pageHeight - margin - CGFloat(rowsOnPage) * cellSize
                pdfContext.move(to: CGPoint(x: x, y: yStart))
                pdfContext.addLine(to: CGPoint(x: x, y: yEnd))
            }

            // Horizontal lines
            for row in 0...rowsOnPage {
                let y = pageHeight - margin - CGFloat(row) * cellSize
                let xStart = margin
                let xEnd = margin + CGFloat(columns) * cellSize
                pdfContext.move(to: CGPoint(x: xStart, y: y))
                pdfContext.addLine(to: CGPoint(x: xEnd, y: y))
            }

            pdfContext.strokePath()

            // Draw images
            for i in startIndex..<endIndex {
                let indexOnPage = i - startIndex
                let col = indexOnPage % columns
                let row = indexOnPage / columns

                let x = margin + CGFloat(col) * cellSize
                // PDF coordinate system has origin at bottom-left, so flip Y
                let y = pageHeight - margin - CGFloat(row + 1) * cellSize

                if let cgImage = images[i] {
                    let imageRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    let fittedRect = fitImageRect(imageSize: CGSize(width: cgImage.width, height: cgImage.height), in: imageRect)
                    pdfContext.draw(cgImage, in: fittedRect)
                }
            }

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        progress(1.0, "Complete")
        return pdfData as Data
    }

    private func downloadImages(progress: @escaping (Double, String) -> Void) async throws -> [CGImage?] {
        var images: [CGImage?] = []
        let total = parts.count

        for (index, part) in parts.enumerated() {
            let currentProgress = Double(index) / Double(total) * 0.85
            progress(currentProgress, "Downloading image \(index + 1) of \(total)...")

            if let urlString = part.imageURL, let url = URL(string: urlString) {
                let image = await downloadImage(from: url)
                images.append(image)
            } else {
                images.append(nil)
            }
        }

        return images
    }

    private func downloadImage(from url: URL) async -> CGImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return createCGImage(from: data)
        } catch {
            print("Failed to download image from \(url): \(error)")
            return nil
        }
    }

    private func createCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return cgImage
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
