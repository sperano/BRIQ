//
//  PartsListView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import CoreData

struct PartsListView: View {
    @Environment(\.managedObjectContext) private var context

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
                        addToPartsListMenu(for: part)
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .sheet(item: $partToAddAfterCreate) { setPart in
            CreatePartsListSheet(partToAdd: setPart)
        }
    }

    @ViewBuilder
    private func addToPartsListMenu(for setPart: SetPart) -> some View {
        Menu {
            ForEach(partsLists) { partsList in
                Button {
                    addToPartsList(partsList, part: setPart)
                } label: {
                    Text(partsList.name)
                }
            }

            if !partsLists.isEmpty {
                Divider()
            }

            Button {
                partToAddAfterCreate = setPart
            } label: {
                Label("New Parts List...", systemImage: "plus")
            }
        } label: {
            Label("Add to Parts List", systemImage: "list.bullet.rectangle")
        }
    }

    private func addToPartsList(_ partsList: PartsList, part setPart: SetPart) {
        guard let part = setPart.part else { return }

        PartsListPart.create(
            in: context,
            partsList: partsList,
            part: part,
            colorID: setPart.colorID,
            quantity: setPart.quantity,
            imageURL: setPart.imageURL
        )

        do {
            try context.save()
        } catch {
            print("Failed to add part to list: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    PartsListView(parts: SetPart.sampleData)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
