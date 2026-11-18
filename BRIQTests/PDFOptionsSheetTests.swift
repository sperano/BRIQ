//
//  PDFOptionsSheetTests.swift
//  BRIQTests
//

import Testing
@testable import BRIQ

@MainActor struct PDFOptionsSheetTests {
    @Test func exportSummaryUsesTheSingularForOnePart() {
        #expect(PDFOptionsSheet.exportSummary(partCount: 1) == "1 part will be exported")
    }

    @Test func exportSummaryUsesThePluralForMoreParts() {
        #expect(PDFOptionsSheet.exportSummary(partCount: 0) == "0 parts will be exported")
        #expect(PDFOptionsSheet.exportSummary(partCount: 42) == "42 parts will be exported")
    }
}
