//
//  UserDataIO.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/10/25.
//

import UniformTypeIdentifiers
import CoreData
import OSLog
import SwiftUI

@MainActor
func saveUserDataToFile(_ data: String) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "briq-userdata.json"
    panel.canCreateDirectories = true
    panel.allowedContentTypes = [.json]

    if panel.runModal() == .OK, let url = panel.url {
        do {
            try data.write(to: url, atomically: true, encoding: .utf8)
            Logger.dataTransfer.info("Saved user data to \(url.path)")
        } catch {
            Logger.dataTransfer.error("Failed to save file: \(error)")
        }
    }
}

/// Returns nil when the user cancels the panel.
@MainActor
func readUserDataFromFile() throws -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.json]

    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    let json = try userDataString(from: Data(contentsOf: url))
    Logger.dataTransfer.info("Read user data from \(url.path)")
    return json
}

/// Asks for a file, imports it and reports the outcome, a file that cannot
/// be read included.
@MainActor
func importUserDataFromFile(into context: NSManagedObjectContext) {
    do {
        guard let json = try readUserDataFromFile() else { return }
        showUserDataImportResult(.success(try importUserData(context: context, jsonString: json)))
    } catch {
        Logger.dataTransfer.error("Failed to import user data file: \(error)")
        showUserDataImportResult(.failure(error))
    }
}

@MainActor
func showUserDataImportResult(_ result: Result<Int, Error>) {
    let alert = NSAlert()
    switch result {
    case .success(let count):
        alert.messageText = "User Data Imported"
        alert.informativeText = "Imported \(count) user data \(count == 1 ? "entry" : "entries")."
    case .failure(let error):
        alert.alertStyle = .warning
        alert.messageText = "Could Not Import User Data"
        alert.informativeText = "\(error.localizedDescription) Your existing user data was not changed."
    }
    alert.runModal()
}
