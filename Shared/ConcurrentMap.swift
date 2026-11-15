//
//  ConcurrentMap.swift
//  BRIQ
//

import Foundation

nonisolated extension Array where Element: Sendable {
    /// `map` with at most `maxConcurrent` transforms running at once; the
    /// results keep the order of the elements. The first error thrown cancels
    /// the transforms still running and is rethrown.
    func concurrentMap<T: Sendable>(
        maxConcurrent: Int,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        precondition(maxConcurrent > 0, "maxConcurrent must be positive")
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var results = [T?](repeating: nil, count: count)
            var nextIndex = 0
            func startNext() {
                let index = nextIndex
                let element = self[index]
                group.addTask { (index, try await transform(element)) }
                nextIndex += 1
            }
            while nextIndex < Swift.min(maxConcurrent, count) {
                startNext()
            }
            while let (index, result) = try await group.next() {
                results[index] = result
                if nextIndex < count {
                    startNext()
                }
            }
            return results.map { $0! }
        }
    }
}
