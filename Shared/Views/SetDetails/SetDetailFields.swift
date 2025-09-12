//
//  SetDetailFields.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import SwiftData

struct SetDetailFields: View {
    @Bindable var set: Set
    var selectedSet: Binding<Set?>? = nil
    @Environment(\.modelContext) private var context
    
    private var userDataManager: SetUserDataManager {
        SetUserDataManager(set: set, context: context)
    }
    
    private func findSetByNumber(_ number: String) -> Set? {
        let descriptor = FetchDescriptor<Set>(predicate: #Predicate { $0.number == number })
        return try? context.fetch(descriptor).first
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
                ("Theme", AnyView(Text(AllThemes[set.themeID].name))),
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
