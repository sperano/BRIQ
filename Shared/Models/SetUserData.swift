//
//  SetUserData.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/4/25.
//

import SwiftData

@Model
class SetUserData: Identifiable, Comparable {
    @Attribute(.unique) var number: String
    var owned: Bool
    var favorite: Bool
    var ownsInstructions: Bool
    var instructionsQuality: Int
    
    @Relationship(deleteRule: .nullify, inverse: \Set.userData)
    var set: Set?
    
    init(number: String, owned: Bool = false, favorite: Bool = false, ownsInstructions: Bool = false, instructionsQuality: Int = 0) {
        self.number = number
        self.owned = owned
        self.favorite = favorite
        self.ownsInstructions = ownsInstructions
        self.instructionsQuality = instructionsQuality
    }

    public static func < (lhs: SetUserData, rhs: SetUserData) -> Bool {
        return lhs.number < rhs.number
    }

    #if DEBUG
//    nonisolated(unsafe) public static let sampleData = [
//        SetUserData(number: "6980-1", owned: true, favorite: true),
//    ]
    #endif
}
