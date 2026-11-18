//
//  SetList.swift
//  SharedBRIQ
//
//  Created by Éric Spérano on 9/10/25.
//

import SwiftUI
import CoreData
import OSLog

struct SetListStatusBar: View {
    let sets: [Set]
    @EnvironmentObject private var coreDataStack: CoreDataStack
    /// Nil until the first fetch ends; later fetches keep the previous totals on screen.
    @State private var totals: SetContentTotals?

    var body: some View {
        let setIDs = sets.map(\.objectID)
        HStack {
            Text(summary)
                .foregroundStyle(Color.secondary)
                .font(.caption)
            Spacer()
        }
        .task(id: setIDs) {
            await loadTotals(forSetIDs: setIDs)
        }
    }

    private var summary: String {
        Self.summary(setCount: sets.count, totals: totals)
    }

    /// The set count, followed by the minifig and part totals once they are known.
    /// The singular and plural forms come from the String Catalog.
    static func summary(setCount: Int, totals: SetContentTotals?) -> String {
        let sets = String(localized: "\(setCount) sets", comment: "Number of sets")
        guard let totals else { return sets }
        let minifigs = String(localized: "\(totals.minifigs) minifigs", comment: "Number of minifigs")
        let parts = String(localized: "\(totals.parts) parts", comment: "Number of parts")
        return String(
            localized: "\(sets), \(minifigs) and \(parts)",
            comment: "Set list status bar: the set count, then the minifig and part totals"
        )
    }

    private func loadTotals(forSetIDs setIDs: [NSManagedObjectID]) async {
        do {
            let fetched = try await SetContentTotals.fetch(
                forSetIDs: setIDs,
                in: coreDataStack.newBackgroundContext()
            )
            guard !Task.isCancelled else { return }
            totals = fetched
        } catch {
            Logger.database.error("Error summing set contents: \(error)")
        }
    }
}
