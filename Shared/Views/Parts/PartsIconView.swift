//
//  PartsIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct PartsIconView: View {
    let parts: [SetPart]
    
    var body: some View {
        IconGridView(
            items: parts,
            imageURL: { $0.imageURL ?? "placeholder.png" },
            quantity: { Int($0.quantity) },
            number: { $0.part?.number ?? "Unknown" },
            name: { $0.part?.name ?? "Unknown Part" }
        )
    }
}

#if DEBUG
#Preview {
    PartsIconView(parts: SetPart.sampleData)
        .frame(width: 400, height: 600)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
