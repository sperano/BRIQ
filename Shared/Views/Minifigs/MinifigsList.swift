//
//  MinifigsList.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/9/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct MinifigList: View {
    let minifigs: [SetMinifig]
    let viewMode: ViewMode
    
    var body: some View {
        Group {
            if viewMode == .list {
                MinifigsListView(minifigs: minifigs)
            } else {
                MinifigsIconView(minifigs: minifigs)
            }
        }
    }
}

#if DEBUG
#Preview("List") {
    MinifigList(minifigs: SetMinifig.sampleData, viewMode: .list)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
        .frame(width: 400, height: 400)
}

#Preview("Icon") {
    MinifigList(minifigs: SetMinifig.sampleData, viewMode: .icon)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
        .frame(width: 400, height: 400)
}
#endif
