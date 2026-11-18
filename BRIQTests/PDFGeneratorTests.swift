//
//  PDFGeneratorTests.swift
//  BRIQTests
//

import CoreGraphics
import Foundation
import Testing
@testable import BRIQ

struct PDFGeneratorTests {
    /// Six columns on US Letter with half-inch margins: 90-point cells,
    /// 8 rows, 48 cells per page.
    private static let columns = 6
    private static let cellsPerPage = 48

    private let loader = ImageLoader(session: StubURLProtocol.makeSession())

    private func generate(
        _ urls: [URL?],
        columns: Int = Self.columns,
        progress: @escaping (Double, String) -> Void = { _, _ in }
    ) async throws -> CGPDFDocument {
        let generator = PDFGenerator(imageURLs: urls, columns: columns, loader: loader)
        let data = try await generator.generate(progress: progress)
        let provider = try #require(CGDataProvider(data: data as CFData))
        return try #require(CGPDFDocument(provider))
    }

    @Test func anEmptyListThrowsNoImages() async {
        let generator = PDFGenerator(imageURLs: [], columns: Self.columns, loader: loader)
        do {
            _ = try await generator.generate { _, _ in }
            Issue.record("Expected PDFGeneratorError.noImages")
        } catch PDFGeneratorError.noImages {
        } catch {
            Issue.record("Expected PDFGeneratorError.noImages, got \(error)")
        }
    }

    @Test(arguments: [
        (1, 1),
        (PDFGeneratorTests.cellsPerPage, 1),
        (PDFGeneratorTests.cellsPerPage + 1, 2),
        (PDFGeneratorTests.cellsPerPage * 2, 2),
        (PDFGeneratorTests.cellsPerPage * 2 + 1, 3),
    ])
    func startsANewPageOnlyAfterAFullOne(cells: Int, pages: Int) async throws {
        let document = try await generate([URL?](repeating: nil, count: cells))

        #expect(document.numberOfPages == pages)
    }

    @Test func reportsProgressPageByPage() async throws {
        let log = ProgressLog()
        let total = Self.cellsPerPage + 1

        _ = try await generate([URL?](repeating: nil, count: total)) { log.append($0, $1) }

        #expect(log.entries == [
            ProgressLog.Entry(fraction: 0, message: "Downloading images 1-48 of 49..."),
            ProgressLog.Entry(
                fraction: Double(Self.cellsPerPage) / Double(total),
                message: "Downloading images 49-49 of 49..."
            ),
            ProgressLog.Entry(fraction: 1, message: "Complete"),
        ])
    }

    /// Six columns give 90-point cells and three give 180-point ones: 375
    /// and 750 pixels at 300 dpi. The fixtures are larger than both.
    @Test(arguments: [(PDFGeneratorTests.columns, 375), (3, 750)])
    func drawsEachImageDecodedAtTheCellsPrintSize(columns: Int, cellPixelSize: Int) async throws {
        let wide = StubURLProtocol.uniqueURL("wide.png")
        StubURLProtocol.setReply(
            .data(status: TestImage.httpOK, body: TestImage.png(width: 2000, height: 1000)),
            for: wide
        )
        let tall = StubURLProtocol.uniqueURL("tall.png")
        StubURLProtocol.setReply(
            .data(status: TestImage.httpOK, body: TestImage.png(width: 800, height: 1600)),
            for: tall
        )
        let missing = StubURLProtocol.uniqueURL("missing.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpNotFound, body: Data()), for: missing)

        let document = try await generate([wide, missing, nil, tall], columns: columns)

        let sizes = Self.imageSizes(onPage: 1, of: document)
        #expect(sizes.count == 2)
        #expect(sizes.map(\.width).max() == cellPixelSize)
        #expect(sizes.map(\.height).max() == cellPixelSize)
        #expect([wide, missing, tall].map(StubURLProtocol.requestCount(for:)) == [1, 1, 1])
    }

    @Test func cancellingStopsTheExport() async {
        let url = StubURLProtocol.uniqueURL("slow.png")
        StubURLProtocol.setReply(.hang, for: url)
        let generator = PDFGenerator(imageURLs: [url], columns: Self.columns, loader: loader)
        let export = Task { try await generator.generate { _, _ in } }
        await StubURLProtocol.waitForRequest(to: url)

        export.cancel()

        await #expect(throws: CancellationError.self) {
            try await export.value
        }
    }

    /// URLSession reports a cancelled request as URLError(.cancelled), not
    /// CancellationError: it must stop the export, not leave the cell empty.
    @Test func aDownloadCancelledByURLSessionStopsTheExport() async {
        let url = StubURLProtocol.uniqueURL("cancelled.png")
        StubURLProtocol.setReply(.failure(.cancelled), for: url)

        await #expect(throws: CancellationError.self) {
            try await generate([url])
        }
    }

    /// Pixel sizes of the image XObjects drawn on a page.
    private static func imageSizes(onPage number: Int, of document: CGPDFDocument) -> [(width: Int, height: Int)] {
        guard let page = document.page(at: number)?.dictionary else { return [] }
        var resources: CGPDFDictionaryRef?
        var xObjects: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(page, "Resources", &resources), let resources,
              CGPDFDictionaryGetDictionary(resources, "XObject", &xObjects), let xObjects
        else {
            return []
        }
        var sizes: [(width: Int, height: Int)] = []
        CGPDFDictionaryApplyBlock(xObjects, { _, object, _ in
            var stream: CGPDFStreamRef?
            var subtype: UnsafePointer<CChar>?
            var width: CGPDFInteger = 0
            var height: CGPDFInteger = 0
            guard CGPDFObjectGetValue(object, .stream, &stream), let stream,
                  let dictionary = CGPDFStreamGetDictionary(stream),
                  CGPDFDictionaryGetName(dictionary, "Subtype", &subtype), let subtype,
                  String(cString: subtype) == "Image",
                  CGPDFDictionaryGetInteger(dictionary, "Width", &width),
                  CGPDFDictionaryGetInteger(dictionary, "Height", &height)
            else {
                return true
            }
            sizes.append((width, height))
            return true
        }, nil)
        return sizes
    }
}

/// Collects `generate`'s progress reports, which arrive on the generator's actor.
private final class ProgressLog: @unchecked Sendable {
    struct Entry: Equatable {
        let fraction: Double
        let message: String
    }

    private let lock = NSLock()
    private var recorded: [Entry] = []

    var entries: [Entry] {
        lock.withLock { recorded }
    }

    func append(_ fraction: Double, _ message: String) {
        lock.withLock { recorded.append(Entry(fraction: fraction, message: message)) }
    }
}
