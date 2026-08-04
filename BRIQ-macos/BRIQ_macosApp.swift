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
    @StateObject private var coreDataStack: CoreDataStack
    @StateObject private var databaseInitializer: DatabaseInitializer
    @State private var showingReinitializeConfirmation = false
    @State private var preserveUserData = true
    @FocusedValue(\.exportPDFAction) private var exportPDFAction

    /// True when the app is running as a unit-test host; the tests create
    /// their own in-memory stacks, so the app must not touch the real store.
    private static let isTestHost = NSClassFromString("XCTestCase") != nil

    init() {
        initThemesTree()
        let stack = CoreDataStack(inMemory: Self.isTestHost)
        _coreDataStack = StateObject(wrappedValue: stack)
        _databaseInitializer = StateObject(wrappedValue: DatabaseInitializer(coreDataStack: stack))
    }

    var body: some Scene {
        WindowGroup {
            if Self.isTestHost {
                Text("Running tests")
            } else {
                appContent
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

    private var appContent: some View {
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
}


