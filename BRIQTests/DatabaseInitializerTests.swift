//
//  DatabaseInitializerTests.swift
//  BRIQTests
//

import CoreData
import Foundation
import Testing
@testable import BRIQ

private final class FixtureLocator {}

/// Runs the initializer against an on-disk store (re-initializing destroys
/// and recreates it) loaded from the fixture archive.
@MainActor final class DatabaseInitializerTests {
    private let directory: URL
    private let suiteName = UUID().uuidString
    private let defaults: UserDefaults
    private let stack: CoreDataStack

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        stack = CoreDataStack(storeURL: directory.appendingPathComponent("BRIQ.sqlite"))
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    private func fixtureURL() throws -> URL {
        try #require(Bundle(for: FixtureLocator.self).url(forResource: "test-init", withExtension: "zip"))
    }

    private var missingArchiveURL: URL {
        directory.appendingPathComponent("missing.zip")
    }

    private func loadedInitializer() async throws -> DatabaseInitializer {
        let initializer = try DatabaseInitializer(coreDataStack: stack, defaults: defaults, archiveURL: fixtureURL())
        await initializer.initializeIfNeeded()
        try #require(initializer.state == .ready)
        return initializer
    }

    /// A valid export owning 100-1, as `reinitialize` leaves it pending.
    private let ownedExport = #"{"version": "1.0", "userData": [{"number": "100-1", "owned": true}]}"#

    private func fetchSet(_ number: String) throws -> Set {
        let request = Set.fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", number)
        return try #require(try stack.viewContext.fetch(request).first)
    }

    private func setNumbers() throws -> [String] {
        try stack.viewContext.fetch(Set.fetchRequest()).map(\.number).sorted()
    }

    private func userDataCount() throws -> Int {
        try stack.viewContext.count(for: SetUserData.fetchRequest())
    }

    private func addUserData(to number: String, instructionsQuality: Int32 = 2) throws {
        let owner = try fetchSet(number)
        let userData = SetUserData.create(
            in: stack.viewContext, number: number, owned: true, instructionsQuality: instructionsQuality
        )
        userData.set = owner
        owner.userData = userData
        try stack.viewContext.save()
    }

    @Test func reinitializeRestoresUserData() async throws {
        let initializer = try await loadedInitializer()
        try addUserData(to: "100-1")

        await initializer.reinitialize(preserveUserData: true)

        #expect(initializer.state == .ready)
        #expect(try setNumbers() == ["100-1", "200-1"])
        let restored = try #require(try fetchSet("100-1").userData)
        #expect(restored.owned)
        #expect(restored.instructionsQuality == 2)
        #expect(try userDataCount() == 1)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
        #expect(stack.lastSaveError == nil)
    }

    @Test func reinitializeWithoutPreservingDropsUserData() async throws {
        let initializer = try await loadedInitializer()
        try addUserData(to: "100-1")

        await initializer.reinitialize(preserveUserData: false)

        #expect(initializer.state == .ready)
        #expect(try setNumbers() == ["100-1", "200-1"])
        #expect(try userDataCount() == 0)
    }

    @Test func reinitializeWithoutPreservingDiscardsAPendingPayload() async throws {
        let initializer = try await loadedInitializer()
        defaults.set(ownedExport, forKey: DatabaseInitializer.pendingUserDataKey)

        await initializer.reinitialize(preserveUserData: false)

        #expect(initializer.state == .ready)
        #expect(try userDataCount() == 0)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
    }

    /// A quit between the load and the restore's save leaves the payload with
    /// `hasInitialized` already set; the next launch restores it.
    @Test func nextLaunchRetriesAnUnfinishedRestore() async throws {
        _ = try await loadedInitializer()
        defaults.set(ownedExport, forKey: DatabaseInitializer.pendingUserDataKey)

        _ = try await loadedInitializer()

        #expect(try fetchSet("100-1").userData?.owned == true)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
        #expect(stack.lastSaveError == nil)
    }

    /// Exporting the store while a payload is pending would overwrite the
    /// payload with the store's missing user data.
    @Test func reinitializeRestoresAPendingPayloadBeforeExporting() async throws {
        let initializer = try await loadedInitializer()
        defaults.set(ownedExport, forKey: DatabaseInitializer.pendingUserDataKey)

        await initializer.reinitialize(preserveUserData: true)

        #expect(initializer.state == .ready)
        #expect(try fetchSet("100-1").userData?.owned == true)
        #expect(try userDataCount() == 1)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
        #expect(stack.lastSaveError == nil)
    }

    /// Rows saved before the import validated its input can hold a rating
    /// the import now rejects; restoring them after the wipe would fail.
    @Test func unrestorableUserDataStopsReinitializeBeforeTheWipe() async throws {
        let initializer = try await loadedInitializer()
        try addUserData(to: "100-1", instructionsQuality: 9)

        await initializer.reinitialize(preserveUserData: true)

        #expect(initializer.state == .ready)
        #expect(try fetchSet("100-1").userData?.instructionsQuality == 9)
        #expect(defaults.bool(forKey: DatabaseInitializer.hasInitializedKey))
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
        #expect(stack.lastSaveError == "The database was not re-initialized: your user data could not be restored "
            + "afterwards. Set 100-1 has an instructions rating of 9; expected 0–5.")
    }

    @Test func failedReloadKeepsUserDataForTheNextLoad() async throws {
        _ = try await loadedInitializer()
        try addUserData(to: "100-1")
        let broken = DatabaseInitializer(coreDataStack: stack, defaults: defaults, archiveURL: missingArchiveURL)

        await broken.reinitialize(preserveUserData: true)

        #expect(broken.state == .failed(message: "The bundled LEGO database archive is missing."))
        #expect(try userDataCount() == 0)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) != nil)

        // The next launch retries the load and restores the user data.
        _ = try await loadedInitializer()

        #expect(try fetchSet("100-1").userData?.owned == true)
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == nil)
    }

    @Test func failedRestoreStaysReadyAndReportsTheError() async throws {
        defaults.set("not json at all {", forKey: DatabaseInitializer.pendingUserDataKey)

        _ = try await loadedInitializer()

        #expect(try setNumbers() == ["100-1", "200-1"])
        #expect(try userDataCount() == 0)
        #expect(stack.lastSaveError
            == "Your user data could not be restored: The user data file is not valid: it is not JSON.")
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == "not json at all {")
    }

    @Test func reinitializeKeepsAPendingPayloadThatStillFails() async throws {
        defaults.set("not json at all {", forKey: DatabaseInitializer.pendingUserDataKey)
        let initializer = try await loadedInitializer()
        try addUserData(to: "100-1")
        stack.lastSaveError = nil

        await initializer.reinitialize(preserveUserData: true)

        #expect(initializer.state == .ready)
        #expect(try fetchSet("100-1").userData?.owned == true)
        #expect(defaults.bool(forKey: DatabaseInitializer.hasInitializedKey))
        #expect(defaults.string(forKey: DatabaseInitializer.pendingUserDataKey) == "not json at all {")
        #expect(stack.lastSaveError == "The database was not re-initialized: the user data kept by the last "
            + "re-initialization could not be restored. The user data file is not valid: it is not JSON.")
    }
}
