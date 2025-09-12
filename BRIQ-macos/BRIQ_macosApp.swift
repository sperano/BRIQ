//
//  MacBRIQApp.swift
//  MacBRIQ
//
//  Created by Éric Spérano on 8/21/25.
//

import SwiftData
import SwiftUI

@main
struct MacBRIQApp: App {
    static let modelTypes: [any PersistentModel.Type] = [
        Set.self, Part.self, Minifig.self, SetPart.self,
        SetMinifig.self, SetUserData.self
    ]
    
    @State private var modelContainer: ModelContainer
    @State private var showingReinitializeConfirmation = false
    @State private var isReinitializing = false
    @State private var preserveUserData = true
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
    
    private func recreateContainer() async throws {
        let newContainer = try resetDefaultStore(modelTypes: Self.modelTypes)
        await MainActor.run {
            self.modelContainer = newContainer
        }
    }
    
    private func reinitializeDatabase() async {
        await MainActor.run {
            isReinitializing = true
        }
        
        var temporaryUserData: String?
        
        do {
            // Export user data if preserveUserData is enabled
            if preserveUserData {
                temporaryUserData = await MainActor.run {
                    exportUserData(modelContext: modelContainer.mainContext)
                }
            }
            
            try await recreateContainer()
            
            // Use InitializationState to wait for completion
            await initializationState.reinitialize()
            
            // Re-import user data if it was exported
            if let userData = temporaryUserData {
                // Wait a bit for the new container to be fully ready
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    importUserData(modelContext: modelContainer.mainContext, jsonString: userData)
                }
            }
            
            print("Database reinitialization completed successfully")
        } catch {
            print("Failed to reinitialize database: \(error)")
        }
        
        await MainActor.run {
            isReinitializing = false
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
                .modelContainer(modelContainer)
                .environmentObject(initializationState)
                .sheet(isPresented: $showingReinitializeConfirmation) {
                    ReinitializeConfirmationView(
                        preserveUserData: $preserveUserData,
                        onConfirm: {
                            showingReinitializeConfirmation = false
                            Task {
                                await reinitializeDatabase()
                            }
                        },
                        onCancel: {
                            showingReinitializeConfirmation = false
                        }
                    )
                }
        }
        .commands {
            CommandMenu("View") {
                ViewModeCommands()
            }
            CommandMenu("Database") {
                Button("Re-Initialize") {
                    showingReinitializeConfirmation = true
                }
                .disabled(isReinitializing)
                Divider()
                Button("Import User Data") {
                    if let data = readUserDataFromFile() {
                        Task { @MainActor in
                            importUserData(modelContext: modelContainer.mainContext, jsonString: data)
                        }
                    }
                }
                Button("Export User Data") {
                    Task { @MainActor in
                        if let data = exportUserData(modelContext: modelContainer.mainContext) {
                            saveUserDataToFile(data)
                        }
                    }
                }
            }
        }
        Settings {
            PreferencesView()
        }
    }
}


