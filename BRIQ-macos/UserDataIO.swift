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

@MainActor
func readUserDataFromFile() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.json]

    if panel.runModal() == .OK, let url = panel.url {
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            Logger.dataTransfer.info("Read user data from \(url.path)")
            return data
        } catch {
            Logger.dataTransfer.error("Failed to read file: \(error)")
        }
    }
    return nil
}
