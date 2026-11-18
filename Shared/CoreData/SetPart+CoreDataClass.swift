//
//  SetPart+CoreDataClass.swift
//  BRIQ
//
//  Created by Éric Spérano on 13/09/25.
//

import CoreData
import Foundation

@objc(SetPart)
public class SetPart: NSManagedObject, Identifiable {
    @NSManaged public var colorID: Int32
    @NSManaged public var imageURL: String?
    @NSManaged public var quantity: Int32
    @NSManaged public var part: Part?
    @NSManaged public var set: Set?

    public var id: String {
        "\(set?.number ?? "unknown")-\(part?.number ?? "unknown")-\(colorID)"
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
        NSFetchRequest<SetPart>(entityName: "SetPart")
    }
}
