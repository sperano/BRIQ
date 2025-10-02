//
//  Database.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import CoreData

// This function is no longer needed - CoreDataStack handles reset functionality
@available(*, deprecated, message: "Use CoreDataStack.resetStore() instead")
public func resetDefaultStore() throws {
    try CoreDataStack.shared.resetStore()
}

public func exportUserData(context: NSManagedObjectContext) -> String? {
    do {
        let request = SetUserData.fetchRequest()
        let userDataList = try context.fetch(request)

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

public func importUserData(context: NSManagedObjectContext, jsonString: String) {
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
        let deleteRequest = SetUserData.fetchRequest()
        let existingUserData = try context.fetch(deleteRequest)
        for data in existingUserData {
            context.delete(data)
        }

        // Import new user data
        for data in userData {
            guard let number = data["number"] as? String else { continue }

            let newUserData = SetUserData.create(
                in: context,
                number: number,
                owned: data["owned"] as? Bool ?? false,
                favorite: data["favorite"] as? Bool ?? false,
                ownsInstructions: data["ownsInstructions"] as? Bool ?? false,
                instructionsQuality: Int32(data["instructionsQuality"] as? Int ?? 0)
            )

            // Link to the corresponding Set if it exists
            if let set = Set.fetch(byNumber: number, in: context) {
                newUserData.set = set
                set.userData = newUserData
            }
        }

        try context.save()
        print("Successfully imported \(userData.count) user data entries")

        // Post notification to refresh UI
        NotificationCenter.default.post(name: NSNotification.Name("UserDataImported"), object: nil)
    } catch {
        print("Failed to import user data: \(error)")
    }
}
