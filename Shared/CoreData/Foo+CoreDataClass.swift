//
//  Foo+CoreDataClass.swift
//  BRIQ
//
//  Created by Claude on 14/09/25.
//

import Foundation
import CoreData

@objc(Foo)
public class Foo: NSManagedObject {

}

extension Foo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Foo> {
        return NSFetchRequest<Foo>(entityName: "Foo")
    }

    @NSManaged public var babeu: Int32

}

extension Foo : Identifiable {

}

