//
//  PartRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/10/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct PartRow: View {
    var part: SetPart
    
    var body: some View {
        HStack {
            Text("\(part.quantity) x")
            RowImage(url: part.imageURL)
            Text(part.part?.name ?? String(localized: "Unknown Part"))
        }
        //.padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    Group {
        PartRow(part: SetPart.sampleData[0])
        PartRow(part: SetPart.sampleData[1])
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
