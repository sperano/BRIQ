//
//  Minifig.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/28/25.
//

import Foundation
import SwiftData

@Model
class Minifig {
    @Attribute(.unique) var number: String
    var name: String
    var partsCount: Int
    var imageURL: String?
    
    public init(number: String, name: String, partsCount: Int, imageURL: String? = nil) {
        self.number = number
        self.name = name
        self.partsCount = partsCount
        self.imageURL = imageURL
    }

    #if DEBUG
//    nonisolated(unsafe) static let fig1 = Minifig(number: "fig-000020", name: "Classic Spaceman, Red with Airtanks (3842a Helmet)", partsCount: 5, imageURL: "https://cdn.rebrickable.com/media/sets/fig-000020.jpg")
//    nonisolated(unsafe) static let fig2 = Minifig(number: "fig-001127", name: "Classic Spaceman, White with Airtanks (3842a Helmet)", partsCount: 5, imageURL: "https://cdn.rebrickable.com/media/sets/fig-001127.jpg")
//    nonisolated(unsafe) static let sampleData = [fig1, fig2]
    #endif
}

