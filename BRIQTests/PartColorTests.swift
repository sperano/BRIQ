//
//  PartColorTests.swift
//  BRIQTests
//
//  Created by Claude on 14/09/25.
//

import XCTest
@testable import BRIQ

final class PartColorTests: XCTestCase {

    // MARK: - Initialization Tests

    func testPartColorInitialization() throws {
        let partColor = PartColor(
            name: "Bright Red",
            rgb: "C91A09",
            isTransparent: false,
            partsCount: 150000,
            setsCount: 25000,
            year1: 1958,
            year2: 2025
        )

        XCTAssertEqual(partColor.name, "Bright Red")
        XCTAssertEqual(partColor.rgb, "C91A09")
        XCTAssertFalse(partColor.isTransparent)
        XCTAssertEqual(partColor.partsCount, 150000)
        XCTAssertEqual(partColor.setsCount, 25000)
        XCTAssertEqual(partColor.year1, 1958)
        XCTAssertEqual(partColor.year2, 2025)
    }

    func testPartColorWithNilYears() throws {
        let partColor = PartColor(
            name: "Transparent Blue",
            rgb: "0055BF",
            isTransparent: true,
            partsCount: 50000,
            setsCount: 8000,
            year1: nil,
            year2: nil
        )

        XCTAssertEqual(partColor.name, "Transparent Blue")
        XCTAssertEqual(partColor.rgb, "0055BF")
        XCTAssertTrue(partColor.isTransparent)
        XCTAssertEqual(partColor.partsCount, 50000)
        XCTAssertEqual(partColor.setsCount, 8000)
        XCTAssertNil(partColor.year1)
        XCTAssertNil(partColor.year2)
    }

    func testPartColorWithPartialYears() throws {
        let partColor = PartColor(
            name: "Dark Green",
            rgb: "184632",
            isTransparent: false,
            partsCount: 75000,
            setsCount: 12000,
            year1: 1968,
            year2: nil
        )

        XCTAssertEqual(partColor.year1, 1968)
        XCTAssertNil(partColor.year2)
    }

    // MARK: - Property Tests

    func testTransparentColor() throws {
        let transparentColor = PartColor(
            name: "Trans-Clear",
            rgb: "FCFCFC",
            isTransparent: true,
            partsCount: 25000,
            setsCount: 5000,
            year1: 1970,
            year2: 2025
        )

        XCTAssertTrue(transparentColor.isTransparent)
    }

    func testOpaqueColor() throws {
        let opaqueColor = PartColor(
            name: "White",
            rgb: "FFFFFF",
            isTransparent: false,
            partsCount: 200000,
            setsCount: 40000,
            year1: 1958,
            year2: 2025
        )

        XCTAssertFalse(opaqueColor.isTransparent)
    }

    func testRgbFormat() throws {
        let partColor = PartColor(
            name: "Black",
            rgb: "05131D",
            isTransparent: false,
            partsCount: 180000,
            setsCount: 35000,
            year1: 1958,
            year2: 2025
        )

        XCTAssertEqual(partColor.rgb, "05131D")
        XCTAssertEqual(partColor.rgb.count, 6) // Should be hex color code
    }

    // MARK: - Identifiable Tests

    func testIdentifiableConformance() throws {
        let partColor = PartColor(
            name: "Blue",
            rgb: "0055BF",
            isTransparent: false,
            partsCount: 100000,
            setsCount: 20000,
            year1: 1958,
            year2: 2025
        )

        // Test that it conforms to Identifiable
        XCTAssertNotNil(partColor.id)
    }

    // MARK: - Sendable Tests

    func testSendableConformance() throws {
        // Test that PartColor can be sent across actor boundaries
        let partColor = PartColor(
            name: "Yellow",
            rgb: "F2CD37",
            isTransparent: false,
            partsCount: 120000,
            setsCount: 22000,
            year1: 1958,
            year2: 2025
        )

        let expectation = XCTestExpectation(description: "Sendable across actors")

        Task {
            await withCheckedContinuation { continuation in
                Task {
                    // This should compile without issues due to Sendable conformance
                    let name = partColor.name
                    XCTAssertEqual(name, "Yellow")
                    continuation.resume()
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Edge Cases Tests

    func testZeroCounts() throws {
        let partColor = PartColor(
            name: "Rare Color",
            rgb: "ABCDEF",
            isTransparent: false,
            partsCount: 0,
            setsCount: 0,
            year1: 2020,
            year2: 2020
        )

        XCTAssertEqual(partColor.partsCount, 0)
        XCTAssertEqual(partColor.setsCount, 0)
    }

    func testSameYear() throws {
        let partColor = PartColor(
            name: "Limited Edition",
            rgb: "123456",
            isTransparent: false,
            partsCount: 1000,
            setsCount: 100,
            year1: 2023,
            year2: 2023
        )

        XCTAssertEqual(partColor.year1, partColor.year2)
    }

    func testEmptyName() throws {
        let partColor = PartColor(
            name: "",
            rgb: "FFFFFF",
            isTransparent: false,
            partsCount: 1,
            setsCount: 1,
            year1: 2023,
            year2: 2023
        )

        XCTAssertEqual(partColor.name, "")
        XCTAssertTrue(partColor.name.isEmpty)
    }

    func testEmptyRgb() throws {
        let partColor = PartColor(
            name: "No Color",
            rgb: "",
            isTransparent: false,
            partsCount: 1,
            setsCount: 1,
            year1: 2023,
            year2: 2023
        )

        XCTAssertEqual(partColor.rgb, "")
        XCTAssertTrue(partColor.rgb.isEmpty)
    }

    // MARK: - Performance Tests

    func testPartColorCreationPerformance() throws {
        measure {
            for i in 0..<1000 {
                _ = PartColor(
                    name: "Color \(i)",
                    rgb: String(format: "%06X", i % 0xFFFFFF),
                    isTransparent: i % 2 == 0,
                    partsCount: i * 100,
                    setsCount: i * 10,
                    year1: 1958 + (i % 67),
                    year2: 2025
                )
            }
        }
    }
}
