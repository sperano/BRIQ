//
//  LegoColorPicker.swift
//  BRIQ
//

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
        filteredColors.filter { $0.color.isTransparent }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
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

    @ViewBuilder
    private func colorSection(title: String, colors: [(index: Int, color: PartColor)]) -> some View {
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
    }

    private func contrastingColor(for color: PartColor) -> Color {
        // Parse RGB to determine luminance
        let scanner = Scanner(string: color.rgb)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        // Calculate relative luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue

        return luminance > 0.5 ? .black : .white
    }
}

#Preview {
    LegoColorPicker(selectedColorIndex: .constant(5))
}
