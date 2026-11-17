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

    /// Shared with `init(configuration:)`: `FileDocumentReadConfiguration` has no public
    /// initializer, so tests exercise this overload with a plain `FileWrapper` instead.
    init(fileWrapper: FileWrapper) throws {
        guard let data = fileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        try self.init(fileWrapper: configuration.file)
    }

    /// Shared with `fileWrapper(configuration:)`: `FileDocumentWriteConfiguration` has no
    /// public initializer, so tests exercise this overload directly.
    func fileWrapper() -> FileWrapper {
        FileWrapper(regularFileContents: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        fileWrapper()
    }
}
