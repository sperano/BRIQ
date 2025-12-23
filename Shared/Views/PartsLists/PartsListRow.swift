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
            Text(partsList.name)
            Spacer()
            Text("\(partsCount)")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
