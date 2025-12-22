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
        let index = Int(colorID)
        guard index >= 0 && index < AllPartColors.count else {
            return PartColor(name: "Unknown", rgb: "000000", isTransparent: false, partsCount: 0, setsCount: 0, year1: nil, year2: nil)
        }
        return AllPartColors[index]
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

    static func fetchRequest() -> NSFetchRequest<PartsListPart> {
        return NSFetchRequest<PartsListPart>(entityName: "PartsListPart")
    }
}
