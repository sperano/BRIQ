//
//  PartsListDetailView.swift
//  BRIQ
//

import SwiftUI

struct PartsListDetailView: View {
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var partsList: PartsList

    @State private var partToEdit: PartsListPart?
    @State private var partToDelete: PartsListPart?

    private var sortedParts: [PartsListPart] {
        partsList.partsArray.sorted { ($0.part?.number ?? "") < ($1.part?.number ?? "") }
    }

    var body: some View {
        Group {
            if sortedParts.isEmpty {
                ContentUnavailableView {
                    Label("No Parts", systemImage: "cube")
                } description: {
                    Text("This parts list is empty.")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(sortedParts) { part in
                            PartsListPartRow(part: part)
                                .contextMenu {
                                    Button {
                                        partToEdit = part
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        partToDelete = part
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(partsList.name)
        .sheet(item: $partToEdit) { part in
            EditPartsListPartSheet(partsListPart: part)
        }
        .alert("Delete Part?", isPresented: Binding(
            get: { partToDelete != nil },
            set: { if !$0 { partToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                partToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let part = partToDelete {
                    delete(part)
                }
                partToDelete = nil
            }
        } message: {
            Text("Remove this part from the list?")
        }
    }

    private func delete(_ part: PartsListPart) {
        context.delete(part)
        do {
            try context.save()
        } catch {
            print("Failed to delete part: \(error)")
        }
    }
}
