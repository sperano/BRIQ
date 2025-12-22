//
//  PartsIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import CoreData

struct PartsIconView: View {
    @Environment(\.managedObjectContext) private var context

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
            imageURL: { $0.imageURL ?? "placeholder.png" },
            quantity: { Int($0.quantity) },
            number: { $0.part?.number ?? "Unknown" },
            name: { $0.part?.name ?? "Unknown Part" }
        ) { setPart in
            addToPartsListMenu(for: setPart)
        }
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
    PartsIconView(parts: SetPart.sampleData)
        .frame(width: 400, height: 600)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
