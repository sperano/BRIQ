//
//  SetContentSection.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

enum ViewMode: String, CaseIterable {
    case list
    case icon
}

struct SetContentSection: View {
    let set: Set
    let viewMode: ViewMode
    
    private var totalMinifigs: Int {
        return set.minifigsCount
    }

    private var totalParts: Int {
        return set.actualPartsCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if set.minifigsCount > 0 {
                Text("\(totalMinifigs) mini-figurines:")
                    .font(.title2)
                    .fontWeight(.bold)
                MinifigList(minifigs: (set.minifigs?.allObjects as? [SetMinifig]) ?? [], viewMode: viewMode)
            }
            if set.actualPartsCount > 0 {
                Text("\(totalParts) parts:")
                    .font(.title2)
                    .fontWeight(.bold)
                PartsList(parts: (set.parts?.allObjects as? [SetPart]) ?? [], viewMode: viewMode)
            }
        }
    }
}

#if DEBUG
#Preview("List") {
    ScrollView {
        SetContentSection(set: Set.sampleData[0], viewMode: .list)
            .padding()
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}

#Preview("Icons") {
    ScrollView {
        SetContentSection(set: Set.sampleData[0], viewMode: .icon)
            .padding()
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}

#endif
