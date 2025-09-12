//
//  PartsList.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/9/25.
//

import SwiftUI

struct PartsList: View {
    let parts: [SetPart]
    let viewMode: ViewMode
    
    private var sortedParts: [SetPart] {
        parts.sorted { $0.part.number < $1.part.number }
    }
    
    var body: some View {
        Group {
            if viewMode == .list {
                PartsListView(parts: sortedParts)
            } else {
                PartsIconView(parts: sortedParts)
            }
        }
    }
}

#if DEBUG
//#Preview {
//    PartsList(parts: SetPart.sampleData, viewMode: .list)
//        .modelContainer(SampleData.shared.modelContainer)
//}
#endif
