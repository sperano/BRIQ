//
//  Theme.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/12/25.
//

import Foundation

class Theme: Identifiable, Equatable {
    let id: Int;
    let name: String
    var parent: Theme?
    var children: [Theme] = []
    
    var sortedChildren: [Theme] {
        children.sorted { $0.name < $1.name }
    }
    
    func getAllThemeIDs() -> Swift.Set<Int> {
        var themeIDs: Swift.Set<Int> = [id]
        
        func addChildrenIDs(_ theme: Theme) {
            for child in theme.children {
                themeIDs.insert(child.id)
                addChildrenIDs(child)
            }
        }
        
        addChildrenIDs(self)
        return themeIDs
    }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.id == rhs.id
    }

}
