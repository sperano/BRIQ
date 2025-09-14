//
//  IconSizeSliderToolbarItem.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/13/25.
//

import SwiftUI

struct IconSizeSliderToolbarItem: ToolbarContent {
    @Binding var iconSize: CGFloat
    
    var body: some ToolbarContent {
        ToolbarItem {
            #if !os(iOS)
            HStack(spacing: 4) {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
                    .padding(.leading, 8)

                Slider(value: $iconSize, in: 80...400, step: 20)
                    .frame(width: 150)
                
                Image(systemName: "plus.magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
                    .padding(.trailing, 8)
            }
            #endif
        }
    }
}
