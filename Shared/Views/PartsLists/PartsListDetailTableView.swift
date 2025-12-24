//
//  PartsListDetailTableView.swift
//  BRIQ
//

import SwiftUI

extension PartsListPart {
    var partNumber: String {
        part?.number ?? ""
    }

    var partName: String {
        part?.name ?? ""
    }

    var colorName: String {
        color().name
    }

    var categoryName: String {
        part?.category.displayName ?? ""
    }
}

extension PartCategory {
    var displayName: String {
        let name = String(describing: self)
        // Convert camelCase to Title Case with spaces
        var result = ""
        for char in name {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result += String(char)
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}

struct PartsListDetailTableView: View {
    let parts: [PartsListPart]
    let onEdit: (PartsListPart) -> Void
    let onDelete: (PartsListPart) -> Void

    @State private var sortOrder = [KeyPathComparator<PartsListPart>(\.partNumber)]

    private var sortedParts: [PartsListPart] {
        parts.sorted(using: sortOrder)
    }

    private var quantityColumn: some TableColumnContent<PartsListPart, KeyPathComparator<PartsListPart>> {
        TableColumn("Qty", value: \.quantity) { part in
            Text("\(part.quantity)")
        }
        .width(min: 40, ideal: 50, max: 60)
    }

    private var numberColumn: some TableColumnContent<PartsListPart, KeyPathComparator<PartsListPart>> {
        TableColumn("Number", value: \.partNumber) { part in
            Text(part.partNumber)
        }
        .width(min: 80, ideal: 100, max: 150)
    }

    private var nameColumn: some TableColumnContent<PartsListPart, KeyPathComparator<PartsListPart>> {
        TableColumn("Name", value: \.partName) { part in
            Text(part.partName)
        }
        .width(min: 150, ideal: 250, max: 400)
    }

    private var colorColumn: some TableColumnContent<PartsListPart, KeyPathComparator<PartsListPart>> {
        TableColumn("Color", value: \.colorName) { part in
            HStack(spacing: 4) {
                Circle()
                    .fill(part.color().swiftUIColor)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                Text(part.colorName)
            }
        }
        .width(min: 100, ideal: 150, max: 200)
    }

    private var categoryColumn: some TableColumnContent<PartsListPart, KeyPathComparator<PartsListPart>> {
        TableColumn("Category", value: \.categoryName) { part in
            Text(part.categoryName)
        }
        .width(min: 100, ideal: 150, max: 200)
    }

    var body: some View {
        Table(sortedParts, sortOrder: $sortOrder) {
            quantityColumn
            numberColumn
            nameColumn
            colorColumn
            categoryColumn
        }
        .contextMenu(forSelectionType: PartsListPart.ID.self) { selection in
            if let partId = selection.first,
               let part = parts.first(where: { $0.id == partId }) {
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
