//
//  SetPart+CoreDataClass.swift
//  BRIQ
//
//  Created by Claude on 13/09/25.
//

import Foundation
import CoreData

@objc(SetPart)
public class SetPart: NSManagedObject, Identifiable {

    @NSManaged public var colorID: Int32
    @NSManaged public var imageURL: String?
    @NSManaged public var quantity: Int32
    @NSManaged public var part: Part?
    @NSManaged public var set: Set?

    public var id: String {
        return "\(set?.number ?? "unknown")-\(part?.number ?? "unknown")-\(colorID)"
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
extension SetPart {

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        part: Part,
        colorID: Int32,
        quantity: Int32,
        imageURL: String? = nil
    ) -> SetPart {
        let setPart = SetPart(context: context)
        setPart.part = part
        setPart.colorID = colorID
        setPart.quantity = quantity
        setPart.imageURL = imageURL
        return setPart
    }

    static func fetchRequest() -> NSFetchRequest<SetPart> {
        return NSFetchRequest<SetPart>(entityName: "SetPart")
    }
}