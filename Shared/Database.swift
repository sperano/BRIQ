//
//  Database.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import SwiftData

public func resetDefaultStore(modelTypes: [any PersistentModel.Type]) throws -> ModelContainer {
    print("Resetting default store...")
    
    // 1. Figure out where SwiftData puts default.store
    let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let storeURL = supportURL.appendingPathComponent("default.store")
    print("Store location: \(storeURL.path)")

    // 2. Delete old store files if they exist
    let fm = FileManager.default
    var deletedFiles: [String] = []
    for ext in ["", "-wal", "-shm"] {
        let url = URL(fileURLWithPath: storeURL.path + ext)
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
            deletedFiles.append(url.lastPathComponent)
        }
    }
    
    if !deletedFiles.isEmpty {
        print("Deleted old store files: \(deletedFiles.joined(separator: ", "))")
    } else {
        print("No existing store files found to delete")
    }

    // 3. Create a fresh container (like app launch)
    let config = ModelConfiguration(url: storeURL)
    let schema = Schema(modelTypes)
    let container = try ModelContainer(for: schema, configurations: config)
    
    print("Successfully created new model container")
    return container
}

public func exportUserData(modelContext: ModelContext) -> String? {
    do {
        let request = FetchDescriptor<SetUserData>()
        let userDataList = try modelContext.fetch(request)
        
        var exportData: [String: Any] = [:]
        var userData: [[String: Any]] = []
        
        for setUserData in userDataList {
            let data: [String: Any] = [
                "number": setUserData.number,
                "owned": setUserData.owned,
                "favorite": setUserData.favorite,
                "ownsInstructions": setUserData.ownsInstructions,
                "instructionsQuality": setUserData.instructionsQuality
            ]
            userData.append(data)
        }
        
        exportData["userData"] = userData
        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["version"] = "1.0"
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8)
    } catch {
        print("Failed to export user data: \(error)")
        return nil
    }
}

public func importUserData(modelContext: ModelContext, jsonString: String) {
    do {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return
        }
        
        let importData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        guard let importData = importData,
              let userData = importData["userData"] as? [[String: Any]] else {
            print("Invalid import data format")
            return
        }
        
        // Clear existing user data
        let deleteRequest = FetchDescriptor<SetUserData>()
        let existingUserData = try modelContext.fetch(deleteRequest)
        for data in existingUserData {
            modelContext.delete(data)
        }
        
        // Import new user data
        for data in userData {
            guard let number = data["number"] as? String else { continue }
            
            let setUserData = SetUserData(
                number: number,
                owned: data["owned"] as? Bool ?? false,
                favorite: data["favorite"] as? Bool ?? false,
                ownsInstructions: data["ownsInstructions"] as? Bool ?? false,
                instructionsQuality: data["instructionsQuality"] as? Int ?? 0
            )
            
            modelContext.insert(setUserData)
        }
        
        try modelContext.save()
        print("Successfully imported \(userData.count) user data entries")
    } catch {
        print("Failed to import user data: \(error)")
    }
}
