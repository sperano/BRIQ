//
//  BRIQ_iosApp.swift
//  BRIQ-ios
//
//  Created by Éric Spérano on 9/11/25.
//

import SwiftUI
import SwiftData

@main
struct BRIQ_iosApp: App {
    static let modelTypes: [any PersistentModel.Type] = [
        Set.self, Part.self, Minifig.self, SetPart.self,
        SetMinifig.self, SetUserData.self
    ]
    
    @State private var modelContainer: ModelContainer
    @StateObject private var initializationState = InitializationState()

    init() {
        initThemesTree()
        do {
            let container = try ModelContainer(for: Schema(Self.modelTypes))
            _modelContainer = State(initialValue: container)
        } catch {
            print("Failed to create model container: \(error)")
            print("Attempting to recreate database...")
            
            do {
                let newContainer = try resetDefaultStore(modelTypes: Self.modelTypes)
                _modelContainer = State(initialValue: newContainer)
                print("Successfully recreated database after initial failure")
            } catch {
                fatalError("Failed to recreate model container after database corruption: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
                .modelContainer(modelContainer)
                .environmentObject(initializationState)
        }
    }
}
