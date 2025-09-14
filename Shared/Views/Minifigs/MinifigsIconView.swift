//
//  MinifigsIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct MinifigsIconView: View {
    let minifigs: [SetMinifig]
    
    var body: some View {
        IconGridView(
            items: minifigs,
            imageURL: { $0.minifig?.imageURL ?? "placeholder.png" },
            quantity: { Int($0.quantity) },
            number: { $0.minifig?.number ?? "Unknown" },
            name: { $0.minifig?.name ?? "Unknown Minifig" }
        )
    }
}
