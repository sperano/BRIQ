//
//  SetContentTotals.swift
//  BRIQ
//

import CoreData
import Foundation

/// Total minifigs and parts across a group of sets, summed by the store
/// (`SUM(quantity)` in SQL) so no `SetPart` or `SetMinifig` row is loaded.
nonisolated struct SetContentTotals: Equatable, Sendable {
    var minifigs: Int
    var parts: Int

    static let zero = SetContentTotals(minifigs: 0, parts: 0)

    private static let sumKey = "total"

    /// Runs on `context`'s queue. Only saved data is counted: dictionary
    /// results ignore the context's pending changes.
    static func fetch(
        forSetIDs setIDs: [NSManagedObjectID],
        in context: NSManagedObjectContext
    ) async throws -> SetContentTotals {
        guard !setIDs.isEmpty else { return .zero }
        return try await context.perform {
            SetContentTotals(
                minifigs: try sumOfQuantity(entityName: "SetMinifig", setIDs: setIDs, in: context),
                parts: try sumOfQuantity(entityName: "SetPart", setIDs: setIDs, in: context)
            )
        }
    }

    private static func sumOfQuantity(
        entityName: String,
        setIDs: [NSManagedObjectID],
        in context: NSManagedObjectContext
    ) throws -> Int {
        let sum = NSExpressionDescription()
        sum.name = sumKey
        sum.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "quantity")])
        sum.expressionResultType = .integer64AttributeType

        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "set IN %@", setIDs)
        request.propertiesToFetch = [sum]

        let row = try context.fetch(request).first
        return (row?[sumKey] as? NSNumber)?.intValue ?? 0
    }
}
