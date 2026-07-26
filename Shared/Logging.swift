//
//  Logging.swift
//  BRIQ
//

import Foundation
import OSLog

nonisolated extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "BRIQ"

    /// Core Data operations: fetches, saves, deletes, store lifecycle.
    static let database = Logger(subsystem: subsystem, category: "database")
    /// Bundled-data import and user-data import/export.
    static let dataTransfer = Logger(subsystem: subsystem, category: "dataTransfer")
    /// PDF generation.
    static let pdf = Logger(subsystem: subsystem, category: "pdf")
}
