//
//  SetMinifig+CoreDataClass.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import Foundation
import CoreData

@objc(SetMinifig)
public class SetMinifig: NSManagedObject, Identifiable {

    @NSManaged public var quantity: Int32
    @NSManaged public var minifig: Minifig?
    @NSManaged public var set: Set?

    public var id: String {
        return "\(set?.number ?? "unknown")-\(minifig?.number ?? "unknown")"
    }
}

// MARK: - Core Data Convenience
extension SetMinifig {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        minifig: Minifig,
        quantity: Int32
    ) -> SetMinifig {
        let setMinifig = SetMinifig(context: context)
        setMinifig.minifig = minifig
        setMinifig.quantity = quantity
        return setMinifig
    }

    static func fetchRequest() -> NSFetchRequest<SetMinifig> {
        return NSFetchRequest<SetMinifig>(entityName: "SetMinifig")
    }
}