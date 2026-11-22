//
//  LegoColorPicker.swift
//  BRIQ
//

import BRIQKit
import SwiftUI

struct LegoColorPicker: View {
    @Binding var selectedColorIndex: Int32
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""

    private var filteredColors: [(index: Int, color: PartColor)] {
        let indexed = AllPartColors.enumerated().map { ($0.offset, $0.element) }

        if searchText.isEmpty {
            return indexed
        }

        return indexed.filter { _, color in
            color.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var solidColors: [(index: Int, color: PartColor)] {
        filteredColors.filter { !$0.color.isTransparent }
    }

    private var transparentColors: [(index: Int, color: PartColor)] {
        filteredColors.filter(\.color.isTransparent)
    }

    /// A swatch brighter than this gets black text, a darker one white.
    private static let darkTextLuminance = 0.5

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !solidColors.isEmpty {
                        colorSection(title: "Solid Colors", colors: solidColors)
                    }

                    if !transparentColors.isEmpty {
                        colorSection(title: "Transparent Colors", colors: transparentColors)
                    }

                    if filteredColors.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Color")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search colors")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func colorSection(title: LocalizedStringKey, colors: [(index: Int, color: PartColor)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(colors, id: \.index) { index, color in
                    colorCell(index: index, color: color)
                }
            }
        }
    }

    private func colorCell(index: Int, color: PartColor) -> some View {
        let isSelected = Int32(index) == selectedColorIndex

        return Button {
            selectedColorIndex = Int32(index)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Color swatch
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .overlay {
                            // Checkerboard for transparent colors
                            if color.isTransparent {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
                            }
                        }
                        .overlay {
                            // Selection indicator
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.accentColor, lineWidth: 3)
                            }
                        }
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Checkmark for selected
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(contrastingColor(for: color))
                    }
                }

                Text(color.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func contrastingColor(for color: PartColor) -> Color {
        color.rgbValue.luminance > Self.darkTextLuminance ? .black : .white
    }
}

#Preview {
    LegoColorPicker(selectedColorIndex: .constant(5))
}
