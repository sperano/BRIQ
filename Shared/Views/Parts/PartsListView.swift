//
//  PartsListView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import CoreData
import SwiftUI

struct PartsListView: View {
    let parts: [SetPart]

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\PartsList.name, order: .forward)],
        animation: .default
    )
    private var partsLists: FetchedResults<PartsList>

    @State private var partToAddAfterCreate: SetPart?

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(parts) { part in
                PartRow(part: part)
                    .contextMenu {
                        AddToPartsListMenu(
                            setPart: part,
                            partsLists: partsLists,
                            partToAddAfterCreate: $partToAddAfterCreate
                        )
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .addToPartsListSheet(item: $partToAddAfterCreate)
    }
}

#if DEBUG
#Preview {
    PartsListView(parts: SetPart.sampleData)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
