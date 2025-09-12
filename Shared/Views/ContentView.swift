//
//  ContentView.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let modelContainer: ModelContainer
    @Environment(\.modelContext) private var context
    @AppStorage("hasInitialized") private var hasInitialized: Bool = false
    @EnvironmentObject var initializationState: InitializationState
    
    @State private var count: Int = 0
    @State private var progress: Double = 0

    var body: some View {
        if hasInitialized {
            NavigationStack {
                SetList()
            }
        } else {
            VStack(spacing: 20) {
                if count == 0 {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                    Text("Initializing...")
                } else {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .padding()
                    //Text("Initializing... \(Int(progress * 100))%")
                    Text("\(count) sets imported.")
                }
            }
            .task {
                await initDB()
                hasInitialized = true
                initializationState.isInitializing = false
                initializationState.hasCompleted = true
            }
        }
    }
    
    func initDB() async {
        await BundledData.loadAll(modelContainer: modelContainer) { newCount, newProgress in
            await MainActor.run {
                self.count = newCount
                self.progress = newProgress
            }
        }
    }
}

#if DEBUG
//#Preview {
//    ContentView()
//        .modelContainer(SampleData.shared.modelContainer)
//}
#endif

