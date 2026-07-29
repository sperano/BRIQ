//
//  BRIQ_macosApp.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/21/25.
//

import CoreData
import OSLog
import SwiftUI

@main
struct MacBRIQApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var databaseInitializer = DatabaseInitializer(coreDataStack: .shared)
    @State private var showingReinitializeConfirmation = false
    @State private var preserveUserData = true
    @FocusedValue(\.exportPDFAction) private var exportPDFAction

    init() {
        initThemesTree()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 400)
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(databaseInitializer)
                .sheet(isPresented: $showingReinitializeConfirmation) {
                    ReinitializeConfirmationView(
                        preserveUserData: $preserveUserData,
                        onConfirm: {
                            showingReinitializeConfirmation = false
                            Task {
                                await databaseInitializer.reinitialize(preserveUserData: preserveUserData)
                            }
                        },
                        onCancel: {
                            showingReinitializeConfirmation = false
                        }
                    )
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .importExport) {
                Button("Export Parts List as PDF...") {
                    exportPDFAction?()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(exportPDFAction == nil)
            }
            CommandGroup(after: .toolbar) {
                ViewModeCommands()
                Divider()
                Menu("Sort") {
                    SortCommands()
                }
            }
            CommandMenu("Database") {
                Button("Re-Initialize") {
                    showingReinitializeConfirmation = true
                }
                .disabled(databaseInitializer.state != .ready)
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


