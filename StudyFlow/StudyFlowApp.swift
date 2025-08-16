//
//  StudyFlowApp.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

@main
struct StudyFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudyClass.self,
            Lecture.self,
            Flashcard.self,
            StudySession.self
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
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
