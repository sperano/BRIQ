import Combine
import Foundation

@MainActor
class InitializationState: ObservableObject {
    @Published public var isInitializing = false
    @Published public var hasCompleted = false
    
    public init() {}
    
    public func reinitialize() async {
        UserDefaults.standard.removeObject(forKey: "hasInitialized")
        isInitializing = true
        hasCompleted = false
        
        // Wait for next ContentView initialization cycle
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Monitor until initialization completes
        while !UserDefaults.standard.bool(forKey: "hasInitialized") {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        }
        
        isInitializing = false
        hasCompleted = true
    }
}
