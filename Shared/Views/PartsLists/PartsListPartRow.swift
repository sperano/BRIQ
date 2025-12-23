//
//  PartsListPartRow.swift
//  BRIQ
//

import SwiftUI

struct PartsListPartRow: View {
    var part: PartsListPart

    var body: some View {
        HStack {
            Text("\(part.quantity) x")
            RowImage(url: part.imageURL ?? "placeholder.png")
            Text(part.part?.name ?? "Unknown Part")
        }
    }
}
