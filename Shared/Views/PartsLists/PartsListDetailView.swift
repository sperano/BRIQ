//
//  PartsListDetailView.swift
//  BRIQ
//

import SwiftUI
import CoreData

struct PartsListDetailView: View {
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var partsList: PartsList

    @AppStorage("partsListViewMode") private var viewMode: PartsListViewMode = .icon

    @State private var partToEdit: PartsListPart?
    @State private var partToDelete: PartsListPart?
    @State private var showPDFOptions: Bool = false

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
                switch viewMode {
                case .icon:
                    PartsListDetailIconView(
                        parts: sortedParts,
                        onEdit: { partToEdit = $0 },
                        onDelete: { partToDelete = $0 }
                    )
                case .table:
                    #if os(macOS)
                    PartsListDetailTableView(
                        parts: sortedParts,
                        onEdit: { partToEdit = $0 },
                        onDelete: { partToDelete = $0 }
                    )
                    #else
                    PartsListDetailIconView(
                        parts: sortedParts,
                        onEdit: { partToEdit = $0 },
                        onDelete: { partToDelete = $0 }
                    )
                    #endif
                }
            }
        }
        .navigationTitle(partsList.name)
        .toolbar {
            ToolbarItem {
                Button {
                    showPDFOptions = true
                } label: {
                    Label("Export PDF", systemImage: "doc.richtext")
                }
                .help("Export parts list as PDF")
            }
            PartsListViewModeMenuToolbarItem(viewMode: $viewMode)
        }
        .focusedSceneValue(\.exportPDFAction) {
            showPDFOptions = true
        }
        .sheet(isPresented: $showPDFOptions) {
            PDFOptionsSheet(partsList: partsList)
        }
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
