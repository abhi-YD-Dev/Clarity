//
//  MainTabView.swift
//  Clarity
//
//  Created by Abhinav Yadav on 20/02/26.
//


import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2.fill")
                }
            
            
            ProgressViewTab()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.xaxis")
                }
        }
        .tint(.cyan)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}



#Preview {
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Concept.self, Topic.self, Attempt.self, configurations: config)
    
    
    MockData.insertSampleData(modelContext: container.mainContext)
    
    
    return NavigationStack {
        MainTabView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark) 
}
