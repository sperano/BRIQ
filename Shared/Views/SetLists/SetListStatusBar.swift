//
//  SetList.swift
//  SharedBRIQ
//
//  Created by Éric Spérano on 9/10/25.
//

import SwiftUI

struct SetListStatusBar: View {
    @Binding var sets: [Set]
    
    private var totalMinifigs: Int {
        sets.reduce(0) { total, set in
            total + set.minifigsCount
        }
    }
    
    private var totalParts: Int {
        sets.reduce(0) { total, set in
            total + set.actualPartsCount
        }
    }

    var body: some View {
        HStack {
            Text("\(sets.count) set\(sets.count < 2 ? "" : "s"), \(totalMinifigs) minifig\(totalMinifigs < 2 ? "" : "s") and  \(totalParts) part\(totalParts < 2 ? "" : "s")")
                .foregroundStyle(Color.secondary)
                .font(.caption)
            Spacer()
        }
    }
}
