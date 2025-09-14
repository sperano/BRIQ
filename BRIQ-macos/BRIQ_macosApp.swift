//
//  MacBRIQApp.swift
//  MacBRIQ
//
//  Created by Éric Spérano on 8/21/25.
//

import CoreData
import SwiftUI

@main
struct MacBRIQApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @State private var showingReinitializeConfirmation = false
    @State private var isReinitializing = false
    @State private var preserveUserData = true
    @StateObject private var initializationState = InitializationState()

    init() {
        initThemesTree()
    }

    private func recreateContainer() async throws {
        try coreDataStack.resetStore()
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
                    exportUserData(context: coreDataStack.viewContext)
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
                    importUserData(context: coreDataStack.viewContext, jsonString: userData)
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
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
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
                            importUserData(context: coreDataStack.viewContext, jsonString: data)
                        }
                    }
                }
                Button("Export User Data") {
                    Task { @MainActor in
                        if let data = exportUserData(context: coreDataStack.viewContext) {
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


