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
    @EnvironmentObject private var coreDataStack: CoreDataStack

    /// Observes the set's SetUserData directly — it may not exist yet, and
    /// @ObservedObject can't watch an optional — so the toggles update without
    /// manual refresh triggers.
    @FetchRequest private var userDataResults: FetchedResults<SetUserData>

    init(set: Set, selectedSet: Binding<Set?>? = nil) {
        self.set = set
        self.selectedSet = selectedSet
        _userDataResults = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "number == %@", set.number)
        )
    }

    private var userData: SetUserData? { userDataResults.first }

    private var ownedBinding: Binding<Bool> {
        Binding(
            get: { userData?.owned ?? false },
            set: { newValue in
                ensureUserData().owned = newValue
                save()
            }
        )
    }

    private var favoriteBinding: Binding<Bool> {
        Binding(
            get: { userData?.favorite ?? false },
            set: { newValue in
                ensureUserData().favorite = newValue
                save()
            }
        )
    }

    private var ownsInstructionsBinding: Binding<Bool> {
        Binding(
            get: { userData?.ownsInstructions ?? false },
            set: { newValue in
                ensureUserData().ownsInstructions = newValue
                save()
            }
        )
    }

    private var instructionsQualityBinding: Binding<Int> {
        Binding(
            get: { Int(userData?.instructionsQuality ?? 0) },
            set: { newValue in
                ensureUserData().instructionsQuality = Int32(newValue)
                save()
            }
        )
    }

    private func ensureUserData() -> SetUserData {
        if let userData = set.userData {
            return userData
        }
        let userData = SetUserData.create(in: context, number: set.number)
        set.userData = userData
        userData.set = set
        return userData
    }

    private func save() {
        if coreDataStack.saveViewContext() {
            // The set list's fetch request filters on userData key paths, but
            // Core Data only re-evaluates fetched Set objects themselves;
            // refreshing the set makes the list re-filter it.
            context.refresh(set, mergeChanges: true)
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
                                SetDetailNavigationLink(set: sameAsSet, selectedSet: selectedSet) {
                                    Text("\(set.sameAsNumber!) (\(set.isUSNumber ? "Intl" : "US")): \(sameAsSet.name)")
                                        .foregroundColor(.blue)
                                }
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
                        isInteractive: userData?.ownsInstructions ?? false
                    )
                    .opacity((userData?.ownsInstructions ?? false) ? 1.0 : 0.5)
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
        .environmentObject(CoreDataStack.shared)
}
#endif
