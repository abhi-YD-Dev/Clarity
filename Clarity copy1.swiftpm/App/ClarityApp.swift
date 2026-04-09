
import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    
    
    let container: ModelContainer
    
    init() {
        do {
            
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            
            container = try ModelContainer(for: Concept.self, Topic.self, Attempt.self, configurations: config)
            
            if !UserDefaults.standard.bool(forKey: "hasInsertedSampleData") {
                MockData.insertSampleData(modelContext: container.mainContext)
                UserDefaults.standard.set(true, forKey: "hasInsertedSampleData")
            }
            
        } catch {
            fatalError("Failed to initialize SwiftData container.")
        }
    }
    
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                
                if hasSeenOnboarding {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    WelcomeView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
