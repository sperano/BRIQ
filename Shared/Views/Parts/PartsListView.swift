//
//  PartsListView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct PartsListView: View {
    let parts: [SetPart]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(parts) { part in
                PartRow(part: part)
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
    PartsListView(parts: SetPart.sampleData)
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
