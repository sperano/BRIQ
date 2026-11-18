//
//  SetMinifig+CoreDataClass.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import CoreData
import Foundation

@objc(SetMinifig)
public class SetMinifig: NSManagedObject, Identifiable {
    @NSManaged public var quantity: Int32
    @NSManaged public var minifig: Minifig?
    @NSManaged public var set: Set?

    public var id: String {
        "\(set?.number ?? "unknown")-\(minifig?.number ?? "unknown")"
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
        NSFetchRequest<SetMinifig>(entityName: "SetMinifig")
    }
}
