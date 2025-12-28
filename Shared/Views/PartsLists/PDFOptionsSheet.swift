//
//  PDFOptionsSheet.swift
//  BRIQ
//

import SwiftUI
import UniformTypeIdentifiers

struct PDFOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let partsList: PartsList

    @State private var columns: Int = 14
    @State private var isGenerating: Bool = false
    @State private var progress: Double = 0
    @State private var progressMessage: String = ""
    @State private var errorMessage: String?

    private let columnRange = 6...20

    var body: some View {
        NavigationStack {
            Form {
                Section("Layout") {
                    Stepper("Columns: \(columns)", value: $columns, in: columnRange)
                    Text("More columns = smaller images")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("\(partsList.partsArray.count) parts will be exported")
                        .foregroundStyle(.secondary)
                }

                if isGenerating {
                    Section("Progress") {
                        ProgressView(value: progress) {
                            Text(progressMessage)
                                .font(.caption)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Export PDF")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        exportPDF()
                    }
                    .disabled(isGenerating || partsList.partsArray.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 250)
        #endif
    }

    private func exportPDF() {
        isGenerating = true
        errorMessage = nil
        progress = 0
        progressMessage = "Preparing..."

        Task {
            do {
                let generator = PDFGenerator(
                    parts: partsList.partsArray,
                    columns: columns
                )

                let pdfData = try await generator.generate { currentProgress, message in
                    Task { @MainActor in
                        self.progress = currentProgress
                        self.progressMessage = message
                    }
                }

                await MainActor.run {
                    savePDF(data: pdfData)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func savePDF(data: Data) {
        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(partsList.name).pdf"
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                    dismiss()
                } catch {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    isGenerating = false
                }
            } else {
                isGenerating = false
            }
        }
        #else
        // iOS: Use share sheet or document picker
        // For now, just dismiss
        dismiss()
        #endif
    }
}
