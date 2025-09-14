//
//  SetUserData+CoreDataClass.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import Foundation
import CoreData

@objc(SetUserData)
public class SetUserData: NSManagedObject, Identifiable, Comparable {

    @NSManaged public var favorite: Bool
    @NSManaged public var instructionsQuality: Int32
    @NSManaged public var number: String
    @NSManaged public var owned: Bool
    @NSManaged public var ownsInstructions: Bool
    @NSManaged public var set: Set?

    public var id: String { number }

    public static func < (lhs: SetUserData, rhs: SetUserData) -> Bool {
        return lhs.number < rhs.number
    }
}

// MARK: - Core Data Convenience
extension SetUserData {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        number: String,
        owned: Bool = false,
        favorite: Bool = false,
        ownsInstructions: Bool = false,
        instructionsQuality: Int32 = 0
    ) -> SetUserData {
        let userData = SetUserData(context: context)
        userData.number = number
        userData.owned = owned
        userData.favorite = favorite
        userData.ownsInstructions = ownsInstructions
        userData.instructionsQuality = instructionsQuality
        return userData
    }

    static func fetchRequest() -> NSFetchRequest<SetUserData> {
        return NSFetchRequest<SetUserData>(entityName: "SetUserData")
    }

    static func fetch(byNumber number: String, in context: NSManagedObjectContext) -> SetUserData? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", number)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching user data by number: \(error)")
            return nil
        }
    }
}
