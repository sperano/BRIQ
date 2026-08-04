//
//  BundledDataTests.swift
//  BRIQTests
//

import Testing
import CoreData
@testable import BRIQ

private final class FixtureLocator {}

@Suite struct BundledDataTests {
    private func fixtureURL() throws -> URL {
        try #require(Bundle(for: FixtureLocator.self).url(forResource: "test-init", withExtension: "zip"))
    }

    @Test func importsFixtureArchive() async throws {
        let stack = CoreDataStack(inMemory: true)
        let context = stack.newBackgroundContext()

        try await BundledData.loadAll(from: fixtureURL(), into: context) { _, _ in }

        let (partCount, minifigCount, sets) = try await context.perform {
            let parts = try context.count(for: Part.fetchRequest())
            let minifigs = try context.count(for: Minifig.fetchRequest())
            let request = Set.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sortKey", ascending: true)]
            let sets = try context.fetch(request).map { set in
                (number: set.number, sortKey: set.sortKey, parts: set.actualPartsCount, minifigs: set.minifigsCount)
            }
            return (parts, minifigs, sets)
        }

        #expect(partCount == 2)
        #expect(minifigCount == 1)
        #expect(sets.count == 2)

        let first = try #require(sets.first)
        #expect(first.number == "100-1")
        #expect(first.sortKey == 100_001)
        #expect(first.parts == 6) // 4 + 2 across two part entries
        #expect(first.minifigs == 2)

        let second = try #require(sets.last)
        #expect(second.number == "200-1")
        #expect(second.parts == 0)
        #expect(second.minifigs == 0)
    }

    @Test func reportsProgressAndFinishesAtOne() async throws {
        let stack = CoreDataStack(inMemory: true)
        let context = stack.newBackgroundContext()

        final class ProgressLog: @unchecked Sendable {
            var fractions: [Double] = []
        }
        let log = ProgressLog()

        try await BundledData.loadAll(from: fixtureURL(), into: context) { _, fraction in
            log.fractions.append(fraction)
        }

        #expect(log.fractions.last == 1.0)
    }

    @Test func missingArchiveThrows() async {
        let stack = CoreDataStack(inMemory: true)
        let context = stack.newBackgroundContext()
        let missing = URL(fileURLWithPath: "/nonexistent/init.zip")

        await #expect(throws: (any Error).self) {
            try await BundledData.loadAll(from: missing, into: context) { _, _ in }
        }
    }
}
