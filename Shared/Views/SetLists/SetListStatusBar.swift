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
    static func summary(setCount: Int, totals: SetContentTotals?) -> String {
        let setsText = counted(setCount, "set")
        guard let totals else { return setsText }
        return "\(setsText), \(counted(totals.minifigs, "minifig")) and \(counted(totals.parts, "part"))"
    }

    private static func counted(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
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
