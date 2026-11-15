//
//  StubURLProtocol.swift
//  BRIQTests
//

import Foundation

/// Answers requests to `https://briq-tests.invalid/...` with canned replies
/// and counts them, so the image tests never touch the network. Each test
/// uses its own `uniqueURL`, so tests running in parallel do not interfere.
final class StubURLProtocol: URLProtocol {
    static let host = "briq-tests.invalid"

    enum Reply {
        case data(status: Int, body: Data)
        /// Never answers: the request ends only when it is cancelled.
        case hang
        /// Fails with `URLError(code)`.
        case failure(URLError.Code)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies: [URL: Reply] = [:]
    nonisolated(unsafe) private static var requestCounts: [URL: Int] = [:]
    nonisolated(unsafe) private static var arrivalWaiters: [URL: [CheckedContinuation<Void, Never>]] = [:]

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    static func uniqueURL(_ name: String) -> URL {
        URL(string: "https://\(host)/\(UUID().uuidString)/\(name)")!
    }

    /// With no reply set, a request fails with `URLError(.cannotConnectToHost)`.
    static func setReply(_ reply: Reply, for url: URL) {
        lock.withLock { replies[url] = reply }
    }

    static func requestCount(for url: URL) -> Int {
        lock.withLock { requestCounts[url, default: 0] }
    }

    /// Returns once a request for `url` has reached the stub.
    static func waitForRequest(to url: URL) async {
        await withCheckedContinuation { continuation in
            let arrived = lock.withLock {
                if requestCounts[url, default: 0] > 0 {
                    return true
                }
                arrivalWaiters[url, default: []].append(continuation)
                return false
            }
            if arrived {
                continuation.resume()
            }
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        let (reply, waiters) = Self.lock.withLock {
            Self.requestCounts[url, default: 0] += 1
            return (Self.replies[url], Self.arrivalWaiters.removeValue(forKey: url) ?? [])
        }
        waiters.forEach { $0.resume() }

        switch reply {
        case .data(let status, let body):
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .hang:
            break
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
        }
    }

    override func stopLoading() {}
}
