//
//  EditPartsListPartSheet.swift
//  BRIQ
//

import SwiftUI
import CoreData

struct EditPartsListPartSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var partsListPart: PartsListPart

    @State private var quantity: Int32 = 1
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        if let imageURL = partsListPart.imageURL {
                            RowImage(url: imageURL)
                        }
                        Text(partsListPart.part?.name ?? "Unknown Part")
                    }
                }

                Section("Quantity") {
                    Stepper(value: $quantity, in: 1...9999) {
                        Text("\(quantity)")
                    }
                }

                Section("Color") {
                    Text(partsListPart.color().name)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Part")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                quantity = partsListPart.quantity
            }
        }
    }

    private func save() {
        partsListPart.quantity = quantity

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
