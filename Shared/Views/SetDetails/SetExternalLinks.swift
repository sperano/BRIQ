//
//  SetExternalLinks.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct SetExternalLinks: View {
    let set: Set
    
    var body: some View {
        HStack {
            Link("Rebrickable", destination: URL(string: "https://rebrickable.com/sets/\(set.number)/")!)
                .foregroundColor(.blue)
            Text("∙")
            Link("Bricklink", destination: URL(string: "https://www.bricklink.com/v2/catalog/catalogitem.page?S=\(set.number)")!)
                .foregroundColor(.blue)
            Text("∙")
            Link("Brickset", destination: URL(string: "https://brickset.com/sets/\(set.number)")!)
                .foregroundColor(.blue)
            Text("∙")
            Link("Brickinstructions", destination: URL(string: "https://lego.brickinstructions.com/lego_instructions/set/\(set.baseNumber)")!)
                .foregroundColor(.blue)
        }
    }
}

#if DEBUG
#Preview {
    SetExternalLinks(set: Set.sampleData[0])
        .padding()
        .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
