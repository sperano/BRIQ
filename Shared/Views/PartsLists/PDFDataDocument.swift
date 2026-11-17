//
//  PDFDataDocument.swift
//  BRIQ
//

import SwiftUI
import UniformTypeIdentifiers

/// Wraps the generated PDF bytes so `fileExporter` can hand them to a document picker.
struct PDFDataDocument: FileDocument {
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
