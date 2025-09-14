//
//  PartRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/10/25.
//

import SwiftUI

struct PartRow: View {
    var part: SetPart
    
    var body: some View {
        HStack {
            Text("\(part.quantity) x")
            RowImage(url: part.imageURL ?? "placeholder.png")
            Text(part.part?.name ?? "Unknown Part")
        }
        //.padding(.horizontal)
    }
}

#if DEBUG
//#Preview {
//    Group {
//        MinifigRow(minifig: SetMinifig.sampleData[0])
//    }
//}
#endif
