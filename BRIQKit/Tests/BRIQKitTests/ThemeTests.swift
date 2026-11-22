//
//  ThemeTests.swift
//  BRIQKitTests
//

import BRIQKit
import Testing

/// A small tree:
/// ```
/// root (1)
/// ├── zed (3)
/// └── able (2)
///     └── grandchild (4)
/// ```
private struct ThemeTree {
    let root = Theme(id: 1, name: "Root")
    let able = Theme(id: 2, name: "Able")
    let zed = Theme(id: 3, name: "Zed")
    let grandchild = Theme(id: 4, name: "Grandchild")

    init() {
        able.parent = root
        zed.parent = root
        grandchild.parent = able
        root.children = [zed, able]
        able.children = [grandchild]
    }
}

struct ThemeTests {
    @Test func parentsAndChildrenAreLinkedBothWays() {
        let tree = ThemeTree()

        #expect(tree.root.parent == nil)
        #expect(tree.root.children.map(\.id).sorted() == [tree.able.id, tree.zed.id].sorted())
        #expect(tree.able.parent == tree.root)
        #expect(tree.zed.parent == tree.root)
        #expect(tree.grandchild.parent == tree.able)
        #expect(tree.able.children == [tree.grandchild])
    }

    @Test func getAllThemeIDsCoversEveryDescendant() {
        let tree = ThemeTree()

        #expect(tree.root.getAllThemeIDs() == [tree.root.id, tree.able.id, tree.zed.id, tree.grandchild.id])
        #expect(tree.able.getAllThemeIDs() == [tree.able.id, tree.grandchild.id])
        #expect(tree.zed.getAllThemeIDs() == [tree.zed.id])
        #expect(tree.grandchild.getAllThemeIDs() == [tree.grandchild.id])
    }

    @Test func sortedChildrenOrderByName() {
        let tree = ThemeTree()

        #expect(tree.root.sortedChildren == [tree.able, tree.zed])
    }

    @Test func equalityComparesID() {
        let sameID = Theme(id: 1, name: "Alpha")
        let otherSameID = Theme(id: 1, name: "Beta")
        let differentID = Theme(id: 2, name: "Alpha")

        #expect(sameID == otherSameID)
        #expect(sameID != differentID)
    }
}
