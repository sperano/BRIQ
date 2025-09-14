//
//  SetDetailFields.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import CoreData

struct SetDetailFields: View {
    @ObservedObject var set: Set
    var selectedSet: Binding<Set?>? = nil
    @Environment(\.managedObjectContext) private var context
    @State private var refreshTrigger: Bool = false

    // Direct Core Data bindings with UI refresh
    private var ownedBinding: Binding<Bool> {
        Binding(
            get: {
                _ = refreshTrigger // Force dependency on refresh trigger
                return set.userData?.owned ?? false
            },
            set: { newValue in
                ensureUserData()
                set.userData?.owned = newValue
                saveContext()
                refreshTrigger.toggle() // Force UI refresh
            }
        )
    }

    private var favoriteBinding: Binding<Bool> {
        Binding(
            get: {
                _ = refreshTrigger // Force dependency on refresh trigger
                return set.userData?.favorite ?? false
            },
            set: { newValue in
                ensureUserData()
                set.userData?.favorite = newValue
                saveContext()
                refreshTrigger.toggle() // Force UI refresh
            }
        )
    }

    private var ownsInstructionsBinding: Binding<Bool> {
        Binding(
            get: {
                _ = refreshTrigger // Force dependency on refresh trigger
                return set.userData?.ownsInstructions ?? false
            },
            set: { newValue in
                ensureUserData()
                set.userData?.ownsInstructions = newValue
                saveContext()
                refreshTrigger.toggle() // Force UI refresh
            }
        )
    }

    private var instructionsQualityBinding: Binding<Int> {
        Binding(
            get: {
                _ = refreshTrigger // Force dependency on refresh trigger
                return Int(set.userData?.instructionsQuality ?? 0)
            },
            set: { newValue in
                ensureUserData()
                set.userData?.instructionsQuality = Int32(newValue)
                saveContext()
                refreshTrigger.toggle() // Force UI refresh
            }
        )
    }

    private func ensureUserData() {
        if set.userData == nil {
            let userData = SetUserData.create(in: context, number: set.number)
            set.userData = userData
            userData.set = set
        }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    private func findSetByNumber(_ number: String) -> Set? {
        return Set.fetch(byNumber: number, in: context)
    }

    var body: some View {
        VStack(alignment: .leading) {
            InfoTable(rows: [
                ("Number", AnyView(Text("\(set.number) (\(set.isUSNumber ? "US" : "International"))"))),
                ("Name", AnyView(Text(set.name))),
                set.sameAsNumber == nil ? nil : ("Same as set", AnyView(
                    Group {
                        if let sameAsSet = findSetByNumber(set.sameAsNumber!) {
                            if let selectedSetBinding = selectedSet {
                                Button(action: {
                                    selectedSetBinding.wrappedValue = sameAsSet
                                }) {
                                    Text("\(set.sameAsNumber!) (\(set.isUSNumber ? "Intl" : "US")): \(sameAsSet.name)")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink(destination: SetDetail(set: sameAsSet)) {
                                    Text("\(set.sameAsNumber!) (\(set.isUSNumber ? "Intl" : "US")): \(sameAsSet.name)")
                                        .foregroundColor(.blue)
                                }.buttonStyle(.plain)
                            }
                        } else {
                            Text(set.sameAsNumber!)
                                .foregroundColor(.secondary)
                        }
                    }
                )),
                ("Year Released", AnyView(Text(String(set.year)))),
                ("Pieces", AnyView(Text("\(set.partsCount)"))),
                ("Theme", AnyView(Text(set.themeName))),
                ("In Collection", AnyView(
                    Toggle("", isOn: ownedBinding)
                )),
                ("Favorite", AnyView(
                    Toggle("", isOn: favoriteBinding)
                )),
                ("Has Instructions", AnyView(
                    Toggle("", isOn: ownsInstructionsBinding)
                )),
                ("Instr. Quality", AnyView(
                    StarRatingView(
                        rating: instructionsQualityBinding,
                        isInteractive: set.userData?.ownsInstructions ?? false
                    )
                    .opacity((set.userData?.ownsInstructions ?? false) ? 1.0 : 0.5)
                )),
            ])
            SetExternalLinks(set: set)
        }
    }
}

#if DEBUG
#Preview {
    SetDetailFields(set: Set.sampleData[0])
        .padding()
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
