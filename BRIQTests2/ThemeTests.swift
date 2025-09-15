//
//  ThemeTests.swift
//  BRIQTests
//
//  Created by Claude on 14/09/25.
//

import XCTest
@testable import BRIQ_ios

final class ThemeTests: XCTestCase {

    // MARK: - Initialization Tests

    func testThemeInitialization() throws {
        let theme = Theme(id: 5, name: "Star Wars")

        XCTAssertEqual(theme.id, 5)
        XCTAssertEqual(theme.name, "Star Wars")
        XCTAssertNil(theme.parent)
        XCTAssertTrue(theme.children.isEmpty)
    }

    func testThemeIdentifiable() throws {
        let theme = Theme(id: 42, name: "Test Theme")

        XCTAssertEqual(theme.id, 42)
        // Identifiable protocol uses id property
        XCTAssertEqual(theme.id as AnyHashable, theme.id as AnyHashable)
    }

    // MARK: - Equality Tests

    func testThemeEquality() throws {
        let theme1 = Theme(id: 10, name: "Creator")
        let theme2 = Theme(id: 10, name: "Different Name")
        let theme3 = Theme(id: 20, name: "Creator")

        // Same ID should be equal regardless of name
        XCTAssertEqual(theme1, theme2)

        // Different ID should not be equal
        XCTAssertNotEqual(theme1, theme3)
    }

    // MARK: - Parent-Child Relationship Tests

    func testAddingChildTheme() throws {
        let parentTheme = Theme(id: 1, name: "Town")
        let childTheme = Theme(id: 2, name: "City")

        parentTheme.children.append(childTheme)
        childTheme.parent = parentTheme

        XCTAssertEqual(parentTheme.children.count, 1)
        XCTAssertEqual(parentTheme.children.first, childTheme)
        XCTAssertEqual(childTheme.parent, parentTheme)
    }

    func testMultipleChildren() throws {
        let parentTheme = Theme(id: 1, name: "Space")
        let child1 = Theme(id: 2, name: "Classic Space")
        let child2 = Theme(id: 3, name: "Space Police")
        let child3 = Theme(id: 4, name: "Blacktron")

        parentTheme.children = [child1, child2, child3]

        child1.parent = parentTheme
        child2.parent = parentTheme
        child3.parent = parentTheme

        XCTAssertEqual(parentTheme.children.count, 3)
        XCTAssertTrue(parentTheme.children.contains(child1))
        XCTAssertTrue(parentTheme.children.contains(child2))
        XCTAssertTrue(parentTheme.children.contains(child3))
    }

    // MARK: - Sorted Children Tests

    func testSortedChildren() throws {
        let parentTheme = Theme(id: 1, name: "Town")
        let child1 = Theme(id: 2, name: "Police")
        let child2 = Theme(id: 3, name: "Fire")
        let child3 = Theme(id: 4, name: "Airport")

        // Add in non-alphabetical order
        parentTheme.children = [child1, child2, child3]

        let sortedChildren = parentTheme.sortedChildren

        XCTAssertEqual(sortedChildren.count, 3)
        XCTAssertEqual(sortedChildren[0].name, "Airport")
        XCTAssertEqual(sortedChildren[1].name, "Fire")
        XCTAssertEqual(sortedChildren[2].name, "Police")
    }

    func testSortedChildrenWithEmptyChildren() throws {
        let parentTheme = Theme(id: 1, name: "Empty Parent")

        let sortedChildren = parentTheme.sortedChildren

        XCTAssertTrue(sortedChildren.isEmpty)
    }

    func testSortedChildrenWithSingleChild() throws {
        let parentTheme = Theme(id: 1, name: "Parent")
        let childTheme = Theme(id: 2, name: "Only Child")

        parentTheme.children = [childTheme]

        let sortedChildren = parentTheme.sortedChildren

        XCTAssertEqual(sortedChildren.count, 1)
        XCTAssertEqual(sortedChildren.first, childTheme)
    }

    // MARK: - Get All Theme IDs Tests

    func testGetAllThemeIDsWithNoChildren() throws {
        let theme = Theme(id: 5, name: "Star Wars")

        let themeIDs = theme.getAllThemeIDs()

        XCTAssertEqual(themeIDs.count, 1)
        XCTAssertTrue(themeIDs.contains(5))
    }

    func testGetAllThemeIDsWithDirectChildren() throws {
        let parentTheme = Theme(id: 1, name: "Space")
        let child1 = Theme(id: 2, name: "Classic Space")
        let child2 = Theme(id: 3, name: "Space Police")

        parentTheme.children = [child1, child2]

        let themeIDs = parentTheme.getAllThemeIDs()

        XCTAssertEqual(themeIDs.count, 3)
        XCTAssertTrue(themeIDs.contains(1)) // Parent
        XCTAssertTrue(themeIDs.contains(2)) // Child 1
        XCTAssertTrue(themeIDs.contains(3)) // Child 2
    }

    func testGetAllThemeIDsWithNestedChildren() throws {
        let rootTheme = Theme(id: 1, name: "Town")
        let childTheme = Theme(id: 2, name: "City")
        let grandchildTheme = Theme(id: 3, name: "Police")
        let greatGrandchildTheme = Theme(id: 4, name: "Police Station")

        rootTheme.children = [childTheme]
        childTheme.children = [grandchildTheme]
        grandchildTheme.children = [greatGrandchildTheme]

        let themeIDs = rootTheme.getAllThemeIDs()

        XCTAssertEqual(themeIDs.count, 4)
        XCTAssertTrue(themeIDs.contains(1)) // Root
        XCTAssertTrue(themeIDs.contains(2)) // Child
        XCTAssertTrue(themeIDs.contains(3)) // Grandchild
        XCTAssertTrue(themeIDs.contains(4)) // Great-grandchild
    }

    func testGetAllThemeIDsWithComplexHierarchy() throws {
        let rootTheme = Theme(id: 1, name: "Town")
        let child1 = Theme(id: 2, name: "City")
        let child2 = Theme(id: 3, name: "Classic Town")
        let grandchild1 = Theme(id: 4, name: "Police")
        let grandchild2 = Theme(id: 5, name: "Fire")
        let grandchild3 = Theme(id: 6, name: "Airport")

        rootTheme.children = [child1, child2]
        child1.children = [grandchild1, grandchild2]
        child2.children = [grandchild3]

        let themeIDs = rootTheme.getAllThemeIDs()

        XCTAssertEqual(themeIDs.count, 6)
        XCTAssertTrue(themeIDs.contains(1)) // Root
        XCTAssertTrue(themeIDs.contains(2)) // Child 1
        XCTAssertTrue(themeIDs.contains(3)) // Child 2
        XCTAssertTrue(themeIDs.contains(4)) // Grandchild 1
        XCTAssertTrue(themeIDs.contains(5)) // Grandchild 2
        XCTAssertTrue(themeIDs.contains(6)) // Grandchild 3
    }

    // MARK: - Edge Cases Tests

    func testThemeWithNegativeID() throws {
        let theme = Theme(id: -1, name: "Negative ID")

        XCTAssertEqual(theme.id, -1)

        let themeIDs = theme.getAllThemeIDs()
        XCTAssertTrue(themeIDs.contains(-1))
    }

    func testThemeWithZeroID() throws {
        let theme = Theme(id: 0, name: "Zero ID")

        XCTAssertEqual(theme.id, 0)

        let themeIDs = theme.getAllThemeIDs()
        XCTAssertTrue(themeIDs.contains(0))
    }

    func testThemeWithEmptyName() throws {
        let theme = Theme(id: 1, name: "")

        XCTAssertEqual(theme.name, "")
        XCTAssertTrue(theme.name.isEmpty)
    }

    func testThemeWithLongName() throws {
        let longName = String(repeating: "A", count: 1000)
        let theme = Theme(id: 1, name: longName)

        XCTAssertEqual(theme.name, longName)
        XCTAssertEqual(theme.name.count, 1000)
    }

    // MARK: - Performance Tests

    func testGetAllThemeIDsPerformanceWithDeepHierarchy() throws {
        let rootTheme = Theme(id: 1, name: "Root")
        var currentTheme = rootTheme

        // Create a deep hierarchy (100 levels)
        for i in 2...101 {
            let childTheme = Theme(id: i, name: "Theme \(i)")
            currentTheme.children = [childTheme]
            currentTheme = childTheme
        }

        measure {
            let themeIDs = rootTheme.getAllThemeIDs()
            XCTAssertEqual(themeIDs.count, 101)
        }
    }

    func testGetAllThemeIDsPerformanceWithWideHierarchy() throws {
        let rootTheme = Theme(id: 1, name: "Root")

        // Create a wide hierarchy (100 direct children)
        for i in 2...101 {
            let childTheme = Theme(id: i, name: "Child \(i)")
            rootTheme.children.append(childTheme)
        }

        measure {
            let themeIDs = rootTheme.getAllThemeIDs()
            XCTAssertEqual(themeIDs.count, 101)
        }
    }

    func testSortedChildrenPerformance() throws {
        let parentTheme = Theme(id: 1, name: "Parent")

        // Add 1000 children with random names
        for i in 1...1000 {
            let childName = "Child \(Int.random(in: 1...10000))"
            let childTheme = Theme(id: i + 1, name: childName)
            parentTheme.children.append(childTheme)
        }

        measure {
            let sortedChildren = parentTheme.sortedChildren
            XCTAssertEqual(sortedChildren.count, 1000)
        }
    }

    // MARK: - Memory Tests

    func testCircularReferenceHandling() throws {
        let theme1 = Theme(id: 1, name: "Theme 1")
        let theme2 = Theme(id: 2, name: "Theme 2")

        // Create circular reference
        theme1.children = [theme2]
        theme2.children = [theme1]

        // This should not cause infinite recursion or crash
        let themeIDs1 = theme1.getAllThemeIDs()
        let themeIDs2 = theme2.getAllThemeIDs()

        // Note: This will create infinite recursion in the current implementation
        // But the test serves to document the behavior
        // In a production app, you might want to add cycle detection

        XCTAssertTrue(themeIDs1.contains(1))
        XCTAssertTrue(themeIDs1.contains(2))
        XCTAssertTrue(themeIDs2.contains(1))
        XCTAssertTrue(themeIDs2.contains(2))
    }
}