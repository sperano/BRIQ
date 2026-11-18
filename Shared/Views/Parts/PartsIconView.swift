//
//  PartsIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import CoreData
import SwiftUI

struct PartsIconView: View {
    let parts: [SetPart]

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\PartsList.name, order: .forward)],
        animation: .default
    )
    private var partsLists: FetchedResults<PartsList>

    @State private var partToAddAfterCreate: SetPart?

    var body: some View {
        IconGridView(
            items: parts,
            imageURL: { $0.imageURL },
            quantity: { Int($0.quantity) },
            number: { $0.part?.number ?? String(localized: "Unknown") },
            name: { $0.part?.name ?? String(localized: "Unknown Part") },
            contextMenuContent: { setPart in
                AddToPartsListMenu(
                    setPart: setPart,
                    partsLists: partsLists,
                    partToAddAfterCreate: $partToAddAfterCreate
                )
            }
        )
        .addToPartsListSheet(item: $partToAddAfterCreate)
    }
}

#if DEBUG
#Preview {
    PartsIconView(parts: SetPart.sampleData)
        .frame(width: 400, height: 600)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
