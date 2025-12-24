//
//  PartsList+CoreDataClass.swift
//  BRIQ
//

import Foundation
import CoreData

@objc(PartsList)
public class PartsList: NSManagedObject, Identifiable {

    @NSManaged public var name: String
    @NSManaged public var parts: NSSet?

    public var id: String { name }

    var partsArray: [PartsListPart] {
        let partsSet = parts as? Swift.Set<PartsListPart> ?? []
        return Array(partsSet)
    }
}

// MARK: - Core Data Convenience
extension PartsList {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String
    ) -> PartsList {
        let partsList = PartsList(context: context)
        partsList.name = name
        return partsList
    }

    static func fetchRequest() -> NSFetchRequest<PartsList> {
        return NSFetchRequest<PartsList>(entityName: "PartsList")
    }

    static func fetch(byName name: String, in context: NSManagedObjectContext) -> PartsList? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching parts list by name: \(error)")
            return nil
        }
    }
}
