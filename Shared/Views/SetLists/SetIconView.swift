//
//  SetIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/29/25.
//

import SwiftUI
#if DEBUG
import CoreData
#endif

struct SetIconView: View {
    @ObservedObject var set: Set
    var size: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: set.imageURL ?? "")) { phase in // TODO
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Color.gray.opacity(0.4)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                } else {
                    Color.gray.opacity(0.5)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: max(4, size/15)))
            .overlay(
                RoundedRectangle(cornerRadius: max(4, size/15))
                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
            )
            
            VStack(spacing: max(1, size/60)) {
                Text(set.baseNumber)
                    .font(size < 100 ? .caption2 : .caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(set.name)
                    .font(size < 100 ? .system(size: 10) : .caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(size < 100 ? 1 : 2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: size)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: max(1, size/60)) {
                if set.userData?.favorite == true {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: max(13, size/12)))
                }
                if set.userData?.owned == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: max(13, size/12)))
                }
            }
            .padding(max(2, size/30))
        }
    }
}

#if DEBUG
#Preview {
    Group {
        SetIconView(set: Set.sampleData[0])
        SetIconView(set: Set.sampleData[1], size: 150)
    }
    .padding()
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
