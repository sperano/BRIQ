//
//  SetPart.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/3/25.
//

import Foundation
import SwiftData

@Model
class SetPart {
    var part: Part
    var colorID: Int = 0
    var quantity: Int = 0
    var imageURL: String? = nil
    
    init(part: Part, colorID: Int, quantity: Int, imageURL: String? = nil) {
        self.part = part
        self.colorID = colorID
        self.quantity = quantity
        self.imageURL = imageURL
    }
    
    func color() -> PartColor {
        return AllPartColors[self.colorID]
    }
    
    #if DEBUG
//    public static let sampleData: [SetPart] = [
//        SetPart(part: Part.part3001, colorID: 0, quantity: 3, imageURL: "https://cdn.rebrickable.com/media/parts/elements/300123.jpg"),
//        SetPart(part: Part.part3003, colorID: 0, quantity: 2, imageURL: "https://cdn.rebrickable.com/media/parts/ldraw/1/3003.png")
//    ]
    #endif
}
