//
//  MinifigsListView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct MinifigsListView: View {
    let minifigs: [SetMinifig]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(minifigs) { minifig in
                MinifigRow(minifig: minifig)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#if DEBUG
#Preview {
    MinifigsListView(minifigs: SetMinifig.sampleData)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
