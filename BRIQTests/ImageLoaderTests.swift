//
//  ImageLoaderTests.swift
//  BRIQTests
//

import Testing
import Foundation
import CoreGraphics
@testable import BRIQ

@Suite struct ImageLoaderTests {
    private let loader = ImageLoader(session: StubURLProtocol.makeSession())

    private func servePNG(width: Int, height: Int, name: String = "image.png") -> URL {
        let url = StubURLProtocol.uniqueURL(name)
        StubURLProtocol.setReply(.data(status: TestImage.httpOK, body: TestImage.png(width: width, height: height)), for: url)
        return url
    }

    @Test func decodesAtTheRequestedPixelSize() async throws {
        let url = servePNG(width: 400, height: 200)

        let image = try #require(await loader.image(at: url, maxPixelSize: 100))

        #expect(image.width == 100)
        #expect(image.height == 50)
    }

    @Test func reusesTheCachedImageForTheSameOrASmallerSize() async throws {
        let url = servePNG(width: 400, height: 200)

        let first = try #require(await loader.image(at: url, maxPixelSize: 100))
        let again = await loader.image(at: url, maxPixelSize: 100)
        let smaller = await loader.image(at: url, maxPixelSize: 50)

        #expect(again === first)
        #expect(smaller === first)
        #expect(StubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func requestsAgainForALargerSize() async throws {
        let url = servePNG(width: 400, height: 200)

        _ = await loader.image(at: url, maxPixelSize: 100)
        let larger = try #require(await loader.image(at: url, maxPixelSize: 200))

        #expect(larger.width == 200)
        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func doesNotRequestAURLThatGotAnHTTPErrorAgain() async {
        let url = StubURLProtocol.uniqueURL("missing.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpNotFound, body: Data()), for: url)

        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)
        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)

        #expect(StubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func doesNotRequestDataThatIsNotAnImageAgain() async {
        let url = StubURLProtocol.uniqueURL("garbage.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpOK, body: Data("not an image".utf8)), for: url)

        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)
        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)

        #expect(StubURLProtocol.requestCount(for: url) == 1)
    }

    @Test func requestsAgainAfterANetworkError() async {
        // No reply set: the stub fails with URLError(.cannotConnectToHost).
        let url = StubURLProtocol.uniqueURL("offline.png")

        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)
        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)

        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func forgetFailureLetsTheURLBeRequestedAgain() async {
        let url = StubURLProtocol.uniqueURL("flaky.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpNotFound, body: Data()), for: url)
        #expect(await loader.image(at: url, maxPixelSize: 100) == nil)

        StubURLProtocol.setReply(.data(status: TestImage.httpOK, body: TestImage.png(width: 100, height: 100)), for: url)
        await loader.forgetFailure(at: url)

        #expect(await loader.image(at: url, maxPixelSize: 100) != nil)
        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func aFailedLargerRequestReturnsTheCachedSmallerImage() async throws {
        let url = servePNG(width: 400, height: 200)
        let small = try #require(await loader.image(at: url, maxPixelSize: 100))

        StubURLProtocol.setReply(.data(status: TestImage.httpNotFound, body: Data()), for: url)
        let larger = await loader.image(at: url, maxPixelSize: 200)

        #expect(larger === small)
        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func aCancelledRequestIsNotRememberedAsFailed() async {
        let url = StubURLProtocol.uniqueURL("slow.png")
        StubURLProtocol.setReply(.hang, for: url)
        let loader = self.loader
        let pending = Task { await loader.image(at: url, maxPixelSize: 100) }
        await StubURLProtocol.waitForRequest(to: url)

        pending.cancel()

        #expect(await pending.value == nil)
        StubURLProtocol.setReply(.data(status: TestImage.httpOK, body: TestImage.png(width: 100, height: 100)), for: url)
        #expect(await loader.image(at: url, maxPixelSize: 100) != nil)
        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func downsampledImageThrowsTheHTTPStatus() async {
        let url = StubURLProtocol.uniqueURL("missing.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpNotFound, body: Data()), for: url)

        await #expect(throws: ImageLoaderError.badStatus(TestImage.httpNotFound)) {
            try await loader.downsampledImage(at: url, maxPixelSize: 100)
        }
    }

    @Test func downsampledImageThrowsUndecodableForDataThatIsNotAnImage() async {
        let url = StubURLProtocol.uniqueURL("garbage.png")
        StubURLProtocol.setReply(.data(status: TestImage.httpOK, body: Data("not an image".utf8)), for: url)

        await #expect(throws: ImageLoaderError.undecodable) {
            try await loader.downsampledImage(at: url, maxPixelSize: 100)
        }
    }

    @Test func downsampledImageBypassesTheCache() async {
        let url = servePNG(width: 400, height: 200)

        _ = try? await loader.downsampledImage(at: url, maxPixelSize: 100)
        _ = await loader.image(at: url, maxPixelSize: 100)

        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test func onlyErrorsThatRepeatArePermanent() {
        #expect(ImageLoader.isPermanent(ImageLoaderError.badStatus(TestImage.httpNotFound)))
        #expect(ImageLoader.isPermanent(ImageLoaderError.undecodable))
        #expect(ImageLoader.isPermanent(URLError(.badURL)))
        #expect(ImageLoader.isPermanent(URLError(.unsupportedURL)))
        #expect(!ImageLoader.isPermanent(URLError(.notConnectedToInternet)))
        #expect(!ImageLoader.isPermanent(URLError(.timedOut)))
        #expect(!ImageLoader.isPermanent(CancellationError()))
    }

    @Test func recognizesBothFormsOfCancellation() {
        #expect(ImageLoader.isCancellation(CancellationError()))
        #expect(ImageLoader.isCancellation(URLError(.cancelled)))
        #expect(!ImageLoader.isCancellation(URLError(.timedOut)))
    }
}
