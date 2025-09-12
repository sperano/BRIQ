//
//  IconGridView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct IconGridView<Item: Identifiable>: View {
    let items: [Item]
    let imageURL: (Item) -> String
    let quantity: (Item) -> Int
    let number: (Item) -> String
    let name: (Item) -> String
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 4)], spacing: 4) {
            ForEach(items) { item in
                VStack(spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        IconImage(url: imageURL(item))
                        Text("\(quantity(item))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(4)
                            .background(Color.black.opacity(0.7))                        
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .help("\(number(item)): \(name(item))")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
