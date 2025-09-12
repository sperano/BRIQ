//
//  Set.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/11/25.
//

import Foundation
import SwiftData

@Model
class Set: Identifiable, Comparable {
    @Attribute(.unique) var number: String
    var isUSNumber: Bool
    @Attribute(.unique) var sameAsNumber: String?
    var name: String
    var year: Int = 0
    var imageURL: String?
    var partsCount: Int
    var themeID: Int = 0
    var minifigs: [SetMinifig]
    var parts: [SetPart]
    var isPack: Bool
    var isUnreleased: Bool
    var isAccessory: Bool
    
    @Relationship(deleteRule: .cascade)
    var userData: SetUserData?
    
    init(number: String, isUSNumber: Bool, name: String, year: Int, imageURL: String?, partsCount: Int, themeID: Int, minifigs: [SetMinifig], parts: [SetPart],
         sameAsNumber: String? = nil,
         isPack: Bool = false, isUnreleased: Bool = false, isAccessory: Bool = false) {
        self.number = number
        self.isUSNumber = isUSNumber
        self.name = name
        self.year = year
        self.imageURL = imageURL
        self.partsCount = partsCount
        self.themeID = themeID
        self.minifigs = minifigs
        self.parts = parts
        self.isPack = isPack
        self.isUnreleased = isUnreleased
        self.isAccessory = isAccessory
        self.sameAsNumber = sameAsNumber
    }

    var baseNumber: String {
        return number.components(separatedBy: "-").first ?? number
    }
    
    var minifigsCount: Int {
        return minifigs.reduce(0) { sum, minifig in
            sum + minifig.quantity
        }
    }
    
    var actualPartsCount: Int {
        return parts.reduce(0) { sum, part in
            sum + part.quantity
        }
    }
    
    var themeName: String {
        return AllThemes[themeID].name
    }
    
    static func < (lhs: Set, rhs: Set) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.number < rhs.number
    }

//#if DEBUG
//    nonisolated(unsafe) public static let sampleData = [
//        Set(
//            number: "6980-1", isUSNumber: false, name: "Galaxy Commander", year: 1983,
//            imageURL: "https://cdn.rebrickable.com/media/sets/6980-1.jpg", partsCount: 443, themeID: 50,
//            minifigs: SetMinifig.sampleData, parts: SetPart.sampleData
//        ),
////        Set(number: "6954-1", name: "Renegade", year: 1987, imageURL: "https://cdn.rebrickable.com/media/sets/6954-1.jpg", partsCount: 2, theme: Theme.space),
////        Set(number: "6931-1", name: "FX Star Patroller", year: 1985, imageURL: "https://cdn.rebrickable.com/media/sets/6931-1.jpg", partsCount: 4, theme: Theme.space)
//    ]
//#endif
}
