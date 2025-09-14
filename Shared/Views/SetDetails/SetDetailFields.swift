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

    private var userDataManager: SetUserDataManager {
        SetUserDataManager(set: set, context: context)
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
                    Toggle("", isOn: userDataManager.ownedBinding)
                )),
                ("Favorite", AnyView(
                    Toggle("", isOn: userDataManager.favoriteBinding)
                )),
                ("Has Instructions", AnyView(
                    Toggle("", isOn: userDataManager.ownsInstructionsBinding)
                )),
                ("Instr. Quality", AnyView(
                    StarRatingView(
                        rating: userDataManager.instructionsQualityBinding, 
                        isInteractive: set.userData?.ownsInstructions ?? false
                    )
                    .opacity((set.userData?.ownsInstructions ?? false) ? 1.0 : 0.5)
                )),
            ])
            SetExternalLinks(set: set)
        }
    }
}
