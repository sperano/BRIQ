//
//  EditPartsListPartSheet.swift
//  BRIQ

import SwiftUI
import CoreData

struct EditPartsListPartSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var partsListPart: PartsListPart

    @State private var quantity: Int32 = 1
    @State private var colorIndex: Int32 = 0
    @State private var showColorPicker: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private var selectedColor: PartColor {
        let index = Int(colorIndex)
        guard index >= 0 && index < AllPartColors.count else {
            return AllPartColors[0]
        }
        return AllPartColors[index]
    }

    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }

    #if os(macOS)
    private var macOSContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("Edit Part")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Part image and info
                    VStack(spacing: 12) {
                        if let imageURL = partsListPart.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure:
                                    Image(systemName: "cube.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 100)
                        } else {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .frame(height: 100)
                        }

                        VStack(spacing: 4) {
                            Text(partsListPart.part?.name ?? "Unknown Part")
                                .font(.headline)
                                .multilineTextAlignment(.center)

                            if let number = partsListPart.part?.number {
                                Text(number)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)

                    Divider()
                        .padding(.horizontal)

                    // Quantity
                    HStack {
                        Text("Quantity")
                        Spacer()
                        Stepper(value: $quantity, in: 1...9999) {
                            Text("\(quantity)")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal)

                    // Color picker
                    HStack {
                        Text("Color")
                        Spacer()
                        Button {
                            showColorPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedColor.swiftUIColor)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                    }

                                Text(selectedColor.name)
                                    .foregroundStyle(.primary)

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
        }
        .frame(width: 380, height: 400)
        .sheet(isPresented: $showColorPicker) {
            LegoColorPicker(selectedColorIndex: $colorIndex)
                .frame(minWidth: 500, minHeight: 400)
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
    #endif

    #if os(iOS)
    private var iOSContent: some View {
        NavigationStack {
            Form {
                // Part header with larger image
                Section {
                    VStack(spacing: 12) {
                        if let imageURL = partsListPart.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure:
                                    Image(systemName: "cube.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 120)
                        } else {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .frame(height: 120)
                        }

                        VStack(spacing: 4) {
                            Text(partsListPart.part?.name ?? "Unknown Part")
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

                // Quantity section
                Section {
                    Stepper(value: $quantity, in: 1...9999) {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            Text("\(quantity)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                // Color section with picker
                Section {
                    Button {
                        showColorPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Text("Color")
                                .foregroundStyle(.primary)

                            Spacer()

                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedColor.swiftUIColor)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                    }

                                Text(selectedColor.name)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Edit Part")
            .navigationBarTitleDisplayMode(.inline)
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
    }
    #endif

    private func save() {
        partsListPart.quantity = quantity
        partsListPart.colorID = colorIndex

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
