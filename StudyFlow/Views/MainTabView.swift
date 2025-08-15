//
//  MainTabView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Today")
                }
            
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }
            
            ProgressDashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .accentColor(.blue) // Will customize this later with our color system
    }
}

#Preview {
    MainTabView()
}