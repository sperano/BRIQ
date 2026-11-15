//
//  NSManagedObjectContext+FetchFirst.swift
//  BRIQ
//

import CoreData
import OSLog

extension NSManagedObjectContext {
    /// The first object of `request` whose `key` equals `value`, or nil when
    /// none does or the fetch fails (the error is logged).
    func fetchFirst<Object: NSManagedObject>(
        _ request: NSFetchRequest<Object>,
        where key: String,
        equals value: String
    ) -> Object? {
        request.predicate = NSPredicate(format: "%K == %@", key, value)
        request.fetchLimit = 1

        do {
            return try fetch(request).first
        } catch {
            let entityName = request.entityName ?? "object"
            Logger.database.error(
                "Error fetching \(entityName, privacy: .public) by \(key, privacy: .public): \(error)"
            )
            return nil
        }
    }
}
