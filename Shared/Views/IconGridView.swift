//
//  IconGridView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

struct IconGridView<Item: Identifiable, MenuContent: View>: View {
    let items: [Item]
    let imageURL: (Item) -> String
    let quantity: (Item) -> Int
    let number: (Item) -> String
    let name: (Item) -> String
    let contextMenuContent: ((Item) -> MenuContent)?

    init(
        items: [Item],
        imageURL: @escaping (Item) -> String,
        quantity: @escaping (Item) -> Int,
        number: @escaping (Item) -> String,
        name: @escaping (Item) -> String,
        @ViewBuilder contextMenuContent: @escaping (Item) -> MenuContent
    ) {
        self.items = items
        self.imageURL = imageURL
        self.quantity = quantity
        self.number = number
        self.name = name
        self.contextMenuContent = contextMenuContent
    }

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
                .contextMenu {
                    if let menuBuilder = contextMenuContent {
                        menuBuilder(item)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

extension IconGridView where MenuContent == EmptyView {
    init(
        items: [Item],
        imageURL: @escaping (Item) -> String,
        quantity: @escaping (Item) -> Int,
        number: @escaping (Item) -> String,
        name: @escaping (Item) -> String
    ) {
        self.items = items
        self.imageURL = imageURL
        self.quantity = quantity
        self.number = number
        self.name = name
        self.contextMenuContent = nil
    }
}
