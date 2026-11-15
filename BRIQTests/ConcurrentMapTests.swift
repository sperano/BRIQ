//
//  ConcurrentMapTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@Suite struct ConcurrentMapTests {
    private enum TransformError: Error {
        case failed
    }

    @Test func keepsTheOrderOfTheElements() async throws {
        let items = Array(0..<20)

        let doubled = try await items.concurrentMap(maxConcurrent: 4) { item -> Int in
            // Later elements yield less, so they tend to finish first.
            for _ in 0..<(items.count - item) {
                await Task.yield()
            }
            return item * 2
        }

        #expect(doubled == items.map { $0 * 2 })
    }

    /// The barrier only lets transforms finish once `limit` of them wait on
    /// it, so a map running fewer at once never finishes (the time limit
    /// fails it) and one running more is seen by `maxRunning`.
    @Test(.timeLimit(.minutes(1)))
    func runsExactlyMaxConcurrentTransformsAtOnce() async throws {
        let limit = 3
        let barrier = Barrier(size: limit)

        _ = try await Array(0..<(limit * 4)).concurrentMap(maxConcurrent: limit) { _ in
            await barrier.arrive()
        }

        #expect(await barrier.maxRunning == limit)
    }

    @Test func mapsFewerElementsThanTheLimit() async throws {
        let result = try await [1, 2].concurrentMap(maxConcurrent: 6) { $0 * 10 }

        #expect(result == [10, 20])
    }

    @Test func mapsAnEmptyArray() async throws {
        let result = try await [Int]().concurrentMap(maxConcurrent: 6) { $0 }

        #expect(result.isEmpty)
    }

    @Test func rethrowsTheTransformsError() async {
        await #expect(throws: TransformError.failed) {
            try await Array(0..<10).concurrentMap(maxConcurrent: 2) { item -> Int in
                if item == 3 {
                    throw TransformError.failed
                }
                return item
            }
        }
    }
}

/// Holds arrivals until `size` of them are waiting, then releases them all,
/// recording how many were inside at once.
private actor Barrier {
    let size: Int
    private(set) var maxRunning = 0
    private var running = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(size: Int) {
        self.size = size
    }

    func arrive() async {
        running += 1
        maxRunning = max(maxRunning, running)
        await withCheckedContinuation { continuation in
            waiting.append(continuation)
            if waiting.count == size {
                let released = waiting
                waiting = []
                released.forEach { $0.resume() }
            }
        }
        running -= 1
    }
}
