//
//  PartsList.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/9/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct PartsList: View {
    let parts: [SetPart]
    let viewMode: ViewMode
    
    private var sortedParts: [SetPart] {
        parts.sorted { ($0.part?.number ?? "") < ($1.part?.number ?? "") }
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
#Preview("List") {
    PartsList(parts: SetPart.sampleData, viewMode: .list)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
        .frame(width: 400, height: 600)
}

#Preview("Icon") {
    PartsList(parts: SetPart.sampleData, viewMode: .icon)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
        .frame(width: 400, height: 600)
}

#endif
