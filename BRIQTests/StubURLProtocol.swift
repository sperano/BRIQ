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
    private nonisolated(unsafe) static var replies: [URL: Reply] = [:]
    private nonisolated(unsafe) static var requestCounts: [URL: Int] = [:]
    private nonisolated(unsafe) static var arrivalWaiters: [URL: [ArrivalWaiter]] = [:]

    private struct ArrivalWaiter {
        let count: Int
        let continuation: CheckedContinuation<Void, Never>
    }

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

    /// Returns once `count` requests for `url` have reached the stub.
    static func waitForRequest(to url: URL, count: Int = 1) async {
        await withCheckedContinuation { continuation in
            let arrived = lock.withLock {
                if requestCounts[url, default: 0] >= count {
                    return true
                }
                arrivalWaiters[url, default: []].append(ArrivalWaiter(count: count, continuation: continuation))
                return false
            }
            if arrived {
                continuation.resume()
            }
        }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        let (reply, arrived) = Self.lock.withLock {
            Self.requestCounts[url, default: 0] += 1
            let count = Self.requestCounts[url, default: 0]
            let waiters = Self.arrivalWaiters[url] ?? []
            Self.arrivalWaiters[url] = waiters.filter { $0.count > count }
            return (Self.replies[url], waiters.filter { $0.count <= count })
        }
        arrived.forEach { $0.continuation.resume() }

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
