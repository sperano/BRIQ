//
//  PartsListRow.swift
//  BRIQ
//

import SwiftUI

struct PartsListRow: View {
    @ObservedObject var partsList: PartsList

    private var partsCount: Int {
        partsList.parts?.count ?? 0
    }

    var body: some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(partsList.name)
            Spacer()
            Text("\(partsCount)")
                .foregroundStyle(.secondary)
                .font(.caption)
                .accessibilityLabel(Self.partsCountDescription(partsCount))
        }
        .accessibilityElement(children: .combine)
    }

    /// What VoiceOver reads for the count shown next to the name.
    static func partsCountDescription(_ count: Int) -> String {
        String(localized: "\(count) parts", comment: "Number of parts")
    }
}
