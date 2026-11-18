//
//  IconSizeSliderToolbarItem.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/13/25.
//

import SwiftUI

struct IconSizeSliderToolbarItem: ToolbarContent {
    private static let sizeRange: ClosedRange<CGFloat> = 80...400
    private static let sizeStep: CGFloat = 20
    private static let sliderWidth: CGFloat = 150

    @Binding var iconSize: CGFloat

    var body: some ToolbarContent {
        ToolbarItem {
            HStack(spacing: 4) {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
                    .padding(.leading, 8)
                    .accessibilityHidden(true)

                Slider(value: $iconSize, in: Self.sizeRange, step: Self.sizeStep)
                    .frame(width: Self.sliderWidth)
                    .accessibilityLabel("Icon Size")

                Image(systemName: "plus.magnifyingglass")
                    .foregroundStyle(Color.secondary)
                    .font(.caption)
                    .padding(.trailing, 8)
                    .accessibilityHidden(true)
            }
        }
    }
}
