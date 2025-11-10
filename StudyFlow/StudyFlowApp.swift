//
//  StudyFlowApp.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct StudyFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudyClass.self,
            Lecture.self,
            Flashcard.self,
            StudySession.self,
            DailyCardCompletion.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Generate sample data on first launch
                    SampleDataGenerator.createSampleDataIfNeeded(modelContext: sharedModelContainer.mainContext)
                    
                    // Request notification permissions
                    requestNotificationPermissions()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Notification Setup
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    // Initialize notification scheduling
                    NotificationManager.shared.initializeNotificationScheduling(modelContext: sharedModelContainer.mainContext)
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        // Set the app as the notification center delegate
        center.delegate = NotificationDelegate.shared
    }
}
