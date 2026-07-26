//
//  Database.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/11/25.
//

import Foundation
import CoreData
import OSLog

extension Notification.Name {
    static let userDataImported = Notification.Name("UserDataImported")
}

func exportUserData(context: NSManagedObjectContext) -> String? {
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
        Logger.dataTransfer.error("Failed to export user data: \(error)")
        return nil
    }
}

func importUserData(context: NSManagedObjectContext, jsonString: String) {
    do {
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.dataTransfer.error("Failed to convert string to data")
            return
        }

        let importData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        guard let importData = importData,
              let userData = importData["userData"] as? [[String: Any]] else {
            Logger.dataTransfer.error("Invalid import data format")
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
        Logger.dataTransfer.info("Successfully imported \(userData.count) user data entries")

        // Post notification to refresh UI
        NotificationCenter.default.post(name: .userDataImported, object: nil)
    } catch {
        Logger.dataTransfer.error("Failed to import user data: \(error)")
    }
}
