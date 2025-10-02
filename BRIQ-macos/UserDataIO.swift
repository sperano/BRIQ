//
//  UserData.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/10/25.
//

import UniformTypeIdentifiers
import CoreData
import SwiftUI

public func saveUserDataToFile(_ data: String) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "briq-userdata.json"
    panel.canCreateDirectories = true
    panel.allowedContentTypes = [.json]

    if panel.runModal() == .OK, let url = panel.url {
        do {
            try data.write(to: url, atomically: true, encoding: .utf8)
            print("Saved to \(url.path)")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}

public func readUserDataFromFile() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.json]

    if panel.runModal() == .OK, let url = panel.url {
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            print("Read data from \(url.path)")
            return data
        } catch {
            print("Failed to read file: \(error)")
        }
    }
    return nil
}

