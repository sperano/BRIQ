//
//  ContentView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/10/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var databaseInitializer: DatabaseInitializer
    @EnvironmentObject var coreDataStack: CoreDataStack

    var body: some View {
        Group {
            switch databaseInitializer.state {
            case .ready:
                mainTabs
            case .idle, .loading:
                loadingView
            case .failed(let message):
                failureView(message: message)
            }
        }
        .task {
            await databaseInitializer.initializeIfNeeded()
        }
        .alert(
            "Save Failed",
            isPresented: Binding(
                get: { coreDataStack.lastSaveError != nil },
                set: { if !$0 { coreDataStack.lastSaveError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(coreDataStack.lastSaveError ?? "")
        }
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                SetList()
            }
            .tabItem {
                Label("Sets", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                PartsListsView()
            }
            .tabItem {
                Label("Parts Lists", systemImage: "list.bullet.rectangle")
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            if case .loading(let setsImported, let fraction) = databaseInitializer.state, setsImported > 0 {
                ProgressView(value: fraction, total: 1.0)
                    .progressViewStyle(.linear)
                    .padding()
                Text("\(setsImported) sets imported.")
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
                Text("Initializing...")
            }
        }
    }

    private func failureView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("Database initialization failed.")
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task {
                    await databaseInitializer.initializeIfNeeded()
                }
            }
        }
        .padding()
    }
}
