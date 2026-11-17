//
//  PDFDataDocumentTests.swift
//  BRIQTests
//

import Testing
import Foundation
import SwiftUI
import UniformTypeIdentifiers
@testable import BRIQ

@Suite struct PDFDataDocumentTests {
    @Test func roundTripsThroughAFileWrapper() throws {
        let data = Data("not a real PDF, just test bytes".utf8)

        let writeConfiguration = FileDocumentWriteConfiguration(contentType: .pdf, existingFile: nil)
        let wrapper = try PDFDataDocument(data: data).fileWrapper(configuration: writeConfiguration)
        #expect(wrapper.regularFileContents == data)

        let readConfiguration = FileDocumentReadConfiguration(contentType: .pdf, file: wrapper)
        let roundTripped = try PDFDataDocument(configuration: readConfiguration)
        #expect(roundTripped.data == data)
    }

    @Test func readingAWrapperWithNoRegularContentsThrowsCorruptFile() {
        let directoryWrapper = FileWrapper(directoryWithFileWrappers: [:])
        let readConfiguration = FileDocumentReadConfiguration(contentType: .pdf, file: directoryWrapper)

        do {
            _ = try PDFDataDocument(configuration: readConfiguration)
            Issue.record("Expected CocoaError.fileReadCorruptFile")
        } catch let error as CocoaError {
            #expect(error.code == .fileReadCorruptFile)
        } catch {
            Issue.record("Expected CocoaError.fileReadCorruptFile, got \(error)")
        }
    }
}
