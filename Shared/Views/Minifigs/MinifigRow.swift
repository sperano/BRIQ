//
//  MinifigRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/10/25.
//

import SwiftUI

struct MinifigRow: View {
    var minifig: SetMinifig
    
    var body: some View {
        HStack {
            Text("\(minifig.quantity) x")
            RowImage(url: minifig.minifig?.imageURL ?? "placeholder.png")
            Text(minifig.minifig?.name ?? "Unknown Minifig")
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
