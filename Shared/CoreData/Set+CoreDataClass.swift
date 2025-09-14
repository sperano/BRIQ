//
//  Set+CoreDataClass.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import Foundation
import CoreData

@objc(Set)
public class Set: NSManagedObject, Identifiable, Comparable {

    @NSManaged public var imageURL: String?
    @NSManaged public var isAccessory: Bool
    @NSManaged public var isPack: Bool
    @NSManaged public var isUnreleased: Bool
    @NSManaged public var isUSNumber: Bool
    @NSManaged public var name: String
    @NSManaged public var number: String
    @NSManaged public var partsCount: Int32
    @NSManaged public var sameAsNumber: String?
    @NSManaged public var themeID: Int32
    @NSManaged public var year: Int32
    @NSManaged public var minifigs: NSSet?
    @NSManaged public var parts: NSSet?
    @NSManaged public var userData: SetUserData?

    public var id: String { number }

    var baseNumber: String {
        return number.components(separatedBy: "-").first ?? number
    }

    var minifigsCount: Int {
        guard let minifigs = minifigs else { return 0 }
        return minifigs.compactMap { $0 as? SetMinifig }.reduce(0) { sum, setMinifig in
            sum + Int(setMinifig.quantity)
        }
    }

    var actualPartsCount: Int {
        guard let parts = parts else { return 0 }
        return parts.compactMap { $0 as? SetPart }.reduce(0) { sum, setPart in
            sum + Int(setPart.quantity)
        }
    }

    var themeName: String {
        let index = Int(themeID)
        guard index >= 0 && index < AllThemes.count else {
            return "Unknown"
        }
        return AllThemes[index].name
    }

    public static func < (lhs: Set, rhs: Set) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.number < rhs.number
    }
}

// MARK: - Core Data Convenience
extension Set {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        number: String,
        isUSNumber: Bool,
        name: String,
        year: Int32,
        imageURL: String?,
        partsCount: Int32,
        themeID: Int32,
        sameAsNumber: String? = nil,
        isPack: Bool = false,
        isUnreleased: Bool = false,
        isAccessory: Bool = false
    ) -> Set {
        let set = Set(context: context)
        set.number = number
        set.isUSNumber = isUSNumber
        set.name = name
        set.year = year
        set.imageURL = imageURL
        set.partsCount = partsCount
        set.themeID = themeID
        set.sameAsNumber = sameAsNumber
        set.isPack = isPack
        set.isUnreleased = isUnreleased
        set.isAccessory = isAccessory
        return set
    }

    static func fetchRequest() -> NSFetchRequest<Set> {
        return NSFetchRequest<Set>(entityName: "Set")
    }

    static func fetch(byNumber number: String, in context: NSManagedObjectContext) -> Set? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", number)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching set by number: \(error)")
            return nil
        }
    }
}