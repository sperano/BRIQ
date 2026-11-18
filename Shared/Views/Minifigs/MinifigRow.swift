//
//  MinifigRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/10/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct MinifigRow: View {
    var minifig: SetMinifig
    
    var body: some View {
        HStack {
            Text("\(minifig.quantity) x")
            RowImage(url: minifig.minifig?.imageURL)
            Text(minifig.minifig?.name ?? String(localized: "Unknown Minifig"))
        }
        //.padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    Group {
        MinifigRow(minifig: SetMinifig.sampleData[0])
        MinifigRow(minifig: SetMinifig.sampleData[1])
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
