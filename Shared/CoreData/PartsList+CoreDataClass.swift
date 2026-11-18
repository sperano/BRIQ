//
//  PartsList+CoreDataClass.swift
//  BRIQ
//

import CoreData
import Foundation

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
        NSFetchRequest<PartsList>(entityName: "PartsList")
    }

    static func fetch(byName name: String, in context: NSManagedObjectContext) -> PartsList? {
        context.fetchFirst(fetchRequest(), where: "name", equals: name)
    }
}
