//
//  SetMinifig.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/3/25.
//

import Foundation
import SwiftData

@Model
class SetMinifig {
    var minifig: Minifig
    var quantity: Int
    
    init(minifig: Minifig, quantity: Int) {
        self.minifig = minifig
        self.quantity = quantity        
    }
    
    #if DEBUG
//    nonisolated(unsafe) public static let sampleData: [SetMinifig] = [
//        SetMinifig(minifig: Minifig.fig1, quantity: 1),
//        SetMinifig(minifig: Minifig.fig2, quantity: 2)
//    ]
    #endif
}
