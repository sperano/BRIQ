//
//  EditPartsListPartSheet.swift
//  BRIQ

import SwiftUI
import CoreData

struct EditPartsListPartSheet: View {
    private static let quantityRange: ClosedRange<Int32> = 1...9999

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var partsListPart: PartsListPart

    @State private var quantity: Int32 = 1
    @State private var colorIndex: Int32 = 0
    @State private var showColorPicker: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PartHeader(partsListPart: partsListPart)
                }

                Section {
                    Stepper(value: $quantity, in: Self.quantityRange) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text("\(quantity)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                Section {
                    ColorRow(color: PartColor.lookup(id: colorIndex)) {
                        showColorPicker = true
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Part")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .sheet(isPresented: $showColorPicker) {
                LegoColorPicker(selectedColorIndex: $colorIndex)
                    #if os(macOS)
                    .frame(minWidth: 500, minHeight: 400)
                    #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                quantity = partsListPart.quantity
                colorIndex = partsListPart.colorID
            }
        }
        #if os(macOS)
        .frame(width: 380, height: 400)
        #endif
    }

    private func save() {
        partsListPart.quantity = quantity
        partsListPart.colorID = colorIndex

        do {
            try context.saveOrRollback()
            dismiss()
        } catch {
            errorMessage = String(localized: "Failed to save: \(error.localizedDescription)")
            showError = true
        }
    }
}

/// The part's image, name and number, centered.
private struct PartHeader: View {
    private static let imageHeight: CGFloat = 120
    private static let placeholderSize: CGFloat = 40

    @ObservedObject var partsListPart: PartsListPart

    var body: some View {
        VStack(spacing: 12) {
            image
                .frame(height: Self.imageHeight)

            VStack(spacing: 4) {
                Text(partsListPart.part?.name ?? String(localized: "Unknown Part"))
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if let number = partsListPart.part?.number {
                    Text(number)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var image: some View {
        if let imageURL = partsListPart.imageURL {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "cube.fill")
            .font(.system(size: Self.placeholderSize))
            .foregroundStyle(.secondary)
    }
}

/// "Color" with a swatch and the color's name; tapping it opens the picker.
private struct ColorRow: View {
    private static let swatchSize: CGFloat = 24
    private static let swatchCornerRadius: CGFloat = 6

    let color: PartColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Color")
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: Self.swatchCornerRadius)
                        .fill(color.swiftUIColor)
                        .frame(width: Self.swatchSize, height: Self.swatchSize)
                        .overlay {
                            RoundedRectangle(cornerRadius: Self.swatchCornerRadius)
                                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                        }

                    Text(color.name)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
