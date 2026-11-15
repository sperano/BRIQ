//
//  PartsListPart+CoreDataClass.swift
//  BRIQ
//

import Foundation
import CoreData

@objc(PartsListPart)
public class PartsListPart: NSManagedObject, Identifiable {

    @NSManaged public var colorID: Int32
    @NSManaged public var imageURL: String?
    @NSManaged public var quantity: Int32
    @NSManaged public var part: Part?
    @NSManaged public var partsList: PartsList?

    public var id: String {
        return "\(partsList?.name ?? "unknown")-\(part?.number ?? "unknown")-\(colorID)"
    }

    func color() -> PartColor {
        PartColor.lookup(id: colorID)
    }
}

// MARK: - Core Data Convenience
extension PartsListPart {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        partsList: PartsList,
        part: Part,
        colorID: Int32,
        quantity: Int32,
        imageURL: String? = nil
    ) -> PartsListPart {
        let partsListPart = PartsListPart(context: context)
        partsListPart.partsList = partsList
        partsListPart.part = part
        partsListPart.colorID = colorID
        partsListPart.quantity = quantity
        partsListPart.imageURL = imageURL
        return partsListPart
    }

    /// Adds `setPart`'s part, color, quantity and image to `partsList`; nil
    /// when `setPart` has no part.
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        partsList: PartsList,
        copying setPart: SetPart
    ) -> PartsListPart? {
        guard let part = setPart.part else { return nil }
        return create(
            in: context,
            partsList: partsList,
            part: part,
            colorID: setPart.colorID,
            quantity: setPart.quantity,
            imageURL: setPart.imageURL
        )
    }

    static func fetchRequest() -> NSFetchRequest<PartsListPart> {
        return NSFetchRequest<PartsListPart>(entityName: "PartsListPart")
    }
}
