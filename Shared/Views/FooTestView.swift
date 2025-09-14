//
//  FooTestView.swift
//  BRIQ
//
//  Created by Claude on 14/09/25.
//

import SwiftUI
import CoreData

struct FooTestView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Foo.babeu, ascending: true)],
        animation: .default
    ) private var foos: FetchedResults<Foo>

    @State private var newBabeuValue: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(foos, id: \.objectID) { foo in
                        HStack {
                            Text("Foo")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(foo.babeu)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteFoos)
                }

                HStack {
                    TextField("Enter babeu value", text: $newBabeuValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Add Foo") {
                        addFoo()
                    }
                    .disabled(newBabeuValue.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Foo Entities (CloudKit Sync)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Random") {
                        addRandomFoo()
                    }
                }
            }
        }
    }

    private func addFoo() {
        guard let value = Int32(newBabeuValue) else { return }

        let newFoo = Foo(context: context)
        newFoo.babeu = value

        saveContext()
        newBabeuValue = ""
    }

    private func addRandomFoo() {
        let newFoo = Foo(context: context)
        newFoo.babeu = Int32.random(in: 1...1000)
        saveContext()
    }

    private func deleteFoos(offsets: IndexSet) {
        for index in offsets {
            context.delete(foos[index])
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    FooTestView()
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif