//
//  SetRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/26/25.
//

import SwiftUI

struct RowImage: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if phase.error != nil {
                Color(.red) // or a placeholder image
            } else {
                ProgressView()
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SetRow: View {
    var set: Set
    
    var body: some View {
        HStack {
            RowImage(url: set.imageURL ?? "") // TODO
            Text("\(set.baseNumber)  \(set.name)")
                //.font(.headline) // Or any font/style you prefer
        }
        //.padding(.horizontal)
    }
}

#if DEBUG
//#Preview {
//    Group {
//        SetRow(set: Set.sampleData[0])
//        //SetRow(set: Set.sampleData[1])
//    }
//}
#endif
