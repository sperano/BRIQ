//
//  MinifigsIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct MinifigsIconView: View {
    let minifigs: [SetMinifig]

    var body: some View {
        IconGridView(
            items: minifigs,
            imageURL: { $0.minifig?.imageURL },
            quantity: { Int($0.quantity) },
            number: { $0.minifig?.number ?? String(localized: "Unknown") },
            name: { $0.minifig?.name ?? String(localized: "Unknown Minifig") }
        )
    }
}

#if DEBUG
#Preview {
    MinifigsIconView(minifigs: SetMinifig.sampleData)
        .frame(width: 400, height: 600)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
