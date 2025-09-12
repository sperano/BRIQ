//
//  Part.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/30/25.

import Foundation
import SwiftData

@Model
class Part: Identifiable {
    @Attribute(.unique) var number: String
    var name: String
    var material: String
    var categoryRawValue: Int
    
    var category: PartCategory {
        get { PartCategory(rawValue: categoryRawValue)! }
        set { categoryRawValue = newValue.rawValue }
    }
 
    init(number: String, name: String, material: String, category: Int) {
        self.number = number
        self.name = name
        self.material = material
        self.categoryRawValue = category
    }
    
    #if DEBUG
//    static let part3001 = Part(number: "3001", name: "Brick 2 x 4", material: "Plastic", category: PartCategory.bricks.rawValue)
//    static let part3003 = Part(number: "3003", name: "Brick 2 x 2", material: "Plastic", category: PartCategory.bricks.rawValue)
//    static let sampleData: [Part] = [part3001, part3003]
    #endif
}
