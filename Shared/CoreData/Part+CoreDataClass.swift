//
//  Part+CoreDataClass.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import Foundation
import CoreData

@objc(Part)
public class Part: NSManagedObject, Identifiable {

    @NSManaged public var categoryRawValue: Int32
    @NSManaged public var material: String
    @NSManaged public var name: String
    @NSManaged public var number: String
    @NSManaged public var partsListParts: NSSet?
    @NSManaged public var setParts: NSSet?

    public var id: String { number }

    var category: PartCategory {
        get { PartCategory(rawValue: Int(categoryRawValue)) ?? .other }
        set { categoryRawValue = Int32(newValue.rawValue) }
    }
}

// MARK: - Core Data Convenience
extension Part {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        number: String,
        name: String,
        material: String,
        category: Int32
    ) -> Part {
        let part = Part(context: context)
        part.number = number
        part.name = name
        part.material = material
        part.categoryRawValue = category
        return part
    }

    static func fetchRequest() -> NSFetchRequest<Part> {
        return NSFetchRequest<Part>(entityName: "Part")
    }

    static func fetch(byNumber number: String, in context: NSManagedObjectContext) -> Part? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", number)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching part by number: \(error)")
            return nil
        }
    }
}
