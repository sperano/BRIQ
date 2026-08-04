//
//  BRIQ_iosApp.swift
//  BRIQ-ios
//
//  Created by Éric Spérano on 9/11/25.
//

import SwiftUI
import CoreData

@main
struct BRIQ_iosApp: App {
    @StateObject private var coreDataStack: CoreDataStack
    @StateObject private var databaseInitializer: DatabaseInitializer

    init() {
        initThemesTree()
        let stack = CoreDataStack()
        _coreDataStack = StateObject(wrappedValue: stack)
        _databaseInitializer = StateObject(wrappedValue: DatabaseInitializer(coreDataStack: stack))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(databaseInitializer)
        }
    }
}
