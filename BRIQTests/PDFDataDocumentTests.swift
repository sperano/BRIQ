//
//  PDFDataDocumentTests.swift
//  BRIQTests
//

import Testing
import Foundation
@testable import BRIQ

@Suite struct PDFDataDocumentTests {
    @Test func roundTripsThroughAFileWrapper() throws {
        let data = Data("not a real PDF, just test bytes".utf8)

        let wrapper = PDFDataDocument(data: data).fileWrapper()
        #expect(wrapper.regularFileContents == data)

        let roundTripped = try PDFDataDocument(fileWrapper: wrapper)
        #expect(roundTripped.data == data)
    }

    @Test func readingAWrapperWithNoRegularContentsThrowsCorruptFile() {
        let directoryWrapper = FileWrapper(directoryWithFileWrappers: [:])

        do {
            _ = try PDFDataDocument(fileWrapper: directoryWrapper)
            Issue.record("Expected CocoaError.fileReadCorruptFile")
        } catch let error as CocoaError {
            #expect(error.code == .fileReadCorruptFile)
        } catch {
            Issue.record("Expected CocoaError.fileReadCorruptFile, got \(error)")
        }
    }
}
