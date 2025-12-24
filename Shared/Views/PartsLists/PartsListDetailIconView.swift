//
//  PartsListDetailIconView.swift
//  BRIQ
//

import SwiftUI

struct PartsListDetailIconView: View {
    let parts: [PartsListPart]
    let onEdit: (PartsListPart) -> Void
    let onDelete: (PartsListPart) -> Void

    var body: some View {
        ScrollView {
            IconGridView(
                items: parts,
                imageURL: { $0.imageURL ?? "placeholder.png" },
                quantity: { Int($0.quantity) },
                number: { $0.part?.number ?? "" },
                name: { $0.part?.name ?? "" }
            ) { part in
                Button {
                    onEdit(part)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete(part)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
