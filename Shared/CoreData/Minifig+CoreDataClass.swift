//
//  Minifig+CoreDataClass.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import Foundation
import CoreData

@objc(Minifig)
public class Minifig: NSManagedObject, Identifiable {

    @NSManaged public var imageURL: String?
    @NSManaged public var name: String
    @NSManaged public var number: String
    @NSManaged public var partsCount: Int32
    @NSManaged public var setMinifigs: NSSet?

    public var id: String { number }
}

// MARK: - Core Data Convenience
extension Minifig {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        number: String,
        name: String,
        partsCount: Int32,
        imageURL: String? = nil
    ) -> Minifig {
        let minifig = Minifig(context: context)
        minifig.number = number
        minifig.name = name
        minifig.partsCount = partsCount
        minifig.imageURL = imageURL
        return minifig
    }

    static func fetchRequest() -> NSFetchRequest<Minifig> {
        return NSFetchRequest<Minifig>(entityName: "Minifig")
    }

    static func fetch(byNumber number: String, in context: NSManagedObjectContext) -> Minifig? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "number == %@", number)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching minifig by number: \(error)")
            return nil
        }
    }
}