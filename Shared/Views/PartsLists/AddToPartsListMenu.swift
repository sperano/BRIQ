//
//  AddToPartsListMenu.swift
//  BRIQ
//

import CoreData
import SwiftUI

/// Context menu adding a set's part to an existing parts list, or asking for
/// a new list through `partToAddAfterCreate`. The container presents that
/// request with `addToPartsListSheet(item:)`: a sheet attached to the menu
/// would go away with it.
struct AddToPartsListMenu: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreDataStack: CoreDataStack

    let setPart: SetPart
    /// Fetched once by the container rather than once per menu.
    let partsLists: FetchedResults<PartsList>
    @Binding var partToAddAfterCreate: SetPart?

    var body: some View {
        Menu {
            ForEach(partsLists) { partsList in
                Button {
                    addToPartsList(partsList)
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

    private func addToPartsList(_ partsList: PartsList) {
        guard PartsListPart.create(in: context, partsList: partsList, copying: setPart) != nil else { return }
        coreDataStack.saveViewContext()
    }
}

extension View {
    /// Presents `CreatePartsListSheet` for the part an `AddToPartsListMenu`
    /// asked to add to a new list.
    func addToPartsListSheet(item: Binding<SetPart?>) -> some View {
        sheet(item: item) { setPart in
            CreatePartsListSheet(partToAdd: setPart)
        }
    }
}
