//
//  SetRow.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/26/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct RowImage: View {
    let url: String?

    private static let size: CGFloat = 40
    private static let cornerRadius: CGFloat = 8

    var body: some View {
        ThumbnailImage(url: url.flatMap(URL.init(string:)), size: Self.size) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Color(.red) // or a placeholder image
            case .empty:
                ProgressView()
            }
        }
        .frame(width: Self.size, height: Self.size)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }
}

struct SetRow: View {
    var set: Set
    
    var body: some View {
        HStack {
            RowImage(url: set.imageURL)
            Text("\(set.baseNumber)  \(set.name)")
        }
    }
}

#if DEBUG
#Preview {
    Group {
        SetRow(set: Set.sampleData[0])
        SetRow(set: Set.sampleData[1])
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
