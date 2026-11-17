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
    /// Cancelled when the sheet goes away, so a dismissed export stops downloading.
    @State private var exportTask: Task<Void, Never>?
    #if os(iOS)
    @State private var pdfDocument: PDFDataDocument?
    @State private var isExportingFile: Bool = false
    #endif

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
        #if os(iOS)
        .fileExporter(
            isPresented: $isExportingFile,
            document: pdfDocument,
            contentType: .pdf,
            defaultFilename: partsList.name
        ) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        #endif
        .onDisappear {
            exportTask?.cancel()
        }
    }

    private func exportPDF() {
        isGenerating = true
        errorMessage = nil
        progress = 0
        progressMessage = "Preparing..."

        exportTask = Task {
            do {
                // Read on the main actor: the parts belong to the view context.
                let generator = PDFGenerator(
                    imageURLs: partsList.partsArray.map { $0.imageURL.flatMap(URL.init(string:)) },
                    columns: columns
                )

                let pdfData = try await generator.generate { currentProgress, message in
                    Task { @MainActor in
                        self.progress = currentProgress
                        self.progressMessage = message
                    }
                }

                try Task.checkCancellation()
                await MainActor.run {
                    savePDF(data: pdfData)
                }
            } catch is CancellationError {
                // The sheet was dismissed: nothing is left to show the result in.
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
        pdfDocument = PDFDataDocument(data: data)
        isGenerating = false
        isExportingFile = true
        #endif
    }
}

#if os(iOS)
/// Wraps the generated PDF bytes so `fileExporter` can hand them to a document picker.
private struct PDFDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    static var writableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileContents: data)
    }
}
#endif
