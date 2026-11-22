//
//  Theme.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/12/25.
//

public final class Theme: Identifiable, Equatable {
    public let id: Int
    public let name: String
    public var parent: Theme?
    public var children: [Theme] = []

    public var sortedChildren: [Theme] {
        children.sorted { $0.name < $1.name }
    }

    public func getAllThemeIDs() -> Set<Int> {
        var themeIDs: Set<Int> = [id]

        func addChildrenIDs(_ theme: Theme) {
            for child in theme.children {
                themeIDs.insert(child.id)
                addChildrenIDs(child)
            }
        }

        addChildrenIDs(self)
        return themeIDs
    }

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    public static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.id == rhs.id
    }
}
