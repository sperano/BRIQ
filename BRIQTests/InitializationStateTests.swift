//
//  InitializationStateTests.swift
//  BRIQTests
//
//  Created by Claude on 14/09/25.
//

import XCTest
import Combine
@testable import BRIQ

@MainActor
final class InitializationStateTests: XCTestCase {

    var initState: InitializationState!

    override func setUpWithError() throws {
        initState = InitializationState()
        // Clear any existing UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasInitialized")
    }

    override func tearDownWithError() throws {
        initState = nil
        UserDefaults.standard.removeObject(forKey: "hasInitialized")
    }

    // MARK: - Initialization Tests

    func testInitialState() throws {
        XCTAssertFalse(initState.isInitializing)
        XCTAssertFalse(initState.hasCompleted)
    }

    func testReinitializeResetsUserDefaults() throws {
        // Set the flag first
        UserDefaults.standard.set(true, forKey: "hasInitialized")

        Task {
            await initState.reinitialize()
        }

        // Should have been cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasInitialized"))
    }

    func testReinitializeSetsInitializing() async throws {
        let expectation = XCTestExpectation(description: "Initialization starts")

        Task {
            XCTAssertFalse(initState.isInitializing)

            // Start reinitialization in background
            Task {
                await initState.reinitialize()
            }

            // Give it time to start
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

            XCTAssertTrue(initState.isInitializing)
            XCTAssertFalse(initState.hasCompleted)

            // Complete initialization
            UserDefaults.standard.set(true, forKey: "hasInitialized")

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testReinitializeCompletesWhenFlagSet() async throws {
        let expectation = XCTestExpectation(description: "Initialization completes")

        Task {
            // Start reinitialization
            let reinitTask = Task {
                await initState.reinitialize()
            }

            // Wait a bit then set the flag
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            UserDefaults.standard.set(true, forKey: "hasInitialized")

            // Wait for completion
            await reinitTask.value

            XCTAssertFalse(initState.isInitializing)
            XCTAssertTrue(initState.hasCompleted)

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    // MARK: - Published Properties Tests

    func testPublishedPropertiesAreObservable() throws {
        var initializingChanges = 0
        var completedChanges = 0

        let initializingCancellable = initState.$isInitializing.sink { _ in
            initializingChanges += 1
        }

        let completedCancellable = initState.$hasCompleted.sink { _ in
            completedChanges += 1
        }

        // Trigger changes
        initState.isInitializing = true
        initState.hasCompleted = true

        XCTAssertGreaterThan(initializingChanges, 1) // Initial + change
        XCTAssertGreaterThan(completedChanges, 1) // Initial + change

        initializingCancellable.cancel()
        completedCancellable.cancel()
    }

    // MARK: - State Transition Tests

    func testStateTransitionDuringReinit() async throws {
        let expectation = XCTestExpectation(description: "State transitions correctly")

        Task {
            // Initial state
            XCTAssertFalse(initState.isInitializing)
            XCTAssertFalse(initState.hasCompleted)

            // Start reinit
            let reinitTask = Task {
                await initState.reinitialize()
            }

            // Check intermediate state
            try await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            XCTAssertTrue(initState.isInitializing)
            XCTAssertFalse(initState.hasCompleted)

            // Complete the initialization
            UserDefaults.standard.set(true, forKey: "hasInitialized")
            await reinitTask.value

            // Check final state
            XCTAssertFalse(initState.isInitializing)
            XCTAssertTrue(initState.hasCompleted)

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    // MARK: - Error Handling Tests

    func testMultipleConcurrentReinits() async throws {
        let expectation = XCTestExpectation(description: "Multiple reinits handled")

        Task {
            // Start multiple reinit tasks
            let task1 = Task { await initState.reinitialize() }
            let task2 = Task { await initState.reinitialize() }

            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

            // Complete initialization
            UserDefaults.standard.set(true, forKey: "hasInitialized")

            // Wait for both to complete
            await task1.value
            await task2.value

            // Should be in completed state
            XCTAssertFalse(initState.isInitializing)
            XCTAssertTrue(initState.hasCompleted)

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
