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
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var initializationState = InitializationState()

    init() {
        initThemesTree()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(initializationState)
        }
    }
}
