//
//  CreatePartsListSheet.swift
//  BRIQ
//

import SwiftUI
import CoreData

struct CreatePartsListSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Optional part to add to the new list after creation
    var partToAdd: SetPart?

    @State private var name: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle("New Parts List")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty."
            showError = true
            return
        }

        if PartsList.fetch(byName: trimmedName, in: context) != nil {
            errorMessage = "A parts list with this name already exists."
            showError = true
            return
        }

        let partsList = PartsList.create(in: context, name: trimmedName)

        if let setPart = partToAdd, let part = setPart.part {
            PartsListPart.create(
                in: context,
                partsList: partsList,
                part: part,
                colorID: setPart.colorID,
                quantity: setPart.quantity,
                imageURL: setPart.imageURL
            )
        }

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
