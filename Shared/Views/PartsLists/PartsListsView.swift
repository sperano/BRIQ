//
//  PartsListsView.swift
//  BRIQ
//

import SwiftUI
import CoreData

struct PartsListsView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.name, order: .forward)],
        animation: .default
    )
    private var partsLists: FetchedResults<PartsList>

    @State private var showCreateSheet = false
    @State private var partsListToRename: PartsList?
    @State private var partsListToDelete: PartsList?
    @State private var selectedPartsList: PartsList?

    var body: some View {
        NavigationSplitView {
            List(partsLists, selection: $selectedPartsList) { partsList in
                PartsListRow(partsList: partsList)
                    .tag(partsList)
                    .contextMenu {
                        Button {
                            partsListToRename = partsList
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            partsListToDelete = partsList
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .overlay {
                if partsLists.isEmpty {
                    ContentUnavailableView {
                        Label("No Parts Lists", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Create a parts list to get started.")
                    }
                }
            }
            .navigationTitle("Parts Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreatePartsListSheet()
            }
            .sheet(item: $partsListToRename) { partsList in
                RenamePartsListSheet(partsList: partsList)
            }
            .alert("Delete Parts List?", isPresented: Binding(
                get: { partsListToDelete != nil },
                set: { if !$0 { partsListToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    partsListToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let partsList = partsListToDelete {
                        delete(partsList)
                    }
                    partsListToDelete = nil
                }
            } message: {
                Text("This will permanently delete \"\(partsListToDelete?.name ?? "")\" and all its parts.")
            }
        } detail: {
            if let selectedPartsList = selectedPartsList {
                PartsListDetailView(partsList: selectedPartsList)
            } else {
                Text("Select a parts list")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func delete(_ partsList: PartsList) {
        context.delete(partsList)
        do {
            try context.save()
        } catch {
            print("Failed to delete parts list: \(error)")
        }
    }
}
