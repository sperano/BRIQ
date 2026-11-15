//
//  NSManagedObjectContext+SaveOrRollback.swift
//  BRIQ
//

import CoreData

extension NSManagedObjectContext {
    /// Saves the context. On failure, discards every pending change before
    /// rethrowing, so a later save elsewhere cannot commit what the user saw
    /// fail.
    func saveOrRollback() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
