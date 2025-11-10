//
//  MainTabView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var notificationDelegate = NotificationDelegate.shared
    @State private var selectedTab = 0
    @State private var showingNotificationStudySession = false
    @State private var notificationCards: [Flashcard] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Today")
                }
                .tag(0)
            
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }
                .tag(1)
            
            ProgressDashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue) // Will customize this later with our color system
        .onAppear {
            // Process any pending notification actions
            if let action = notificationDelegate.processNotificationAction() {
                handleNotificationAction(action)
            }
        }
        .onChange(of: notificationDelegate.pendingNotificationAction) { _, newAction in
            if let action = newAction {
                handleNotificationAction(action)
            }
        }
        .fullScreenCover(isPresented: $showingNotificationStudySession) {
            StudySessionView(
                initialCards: notificationCards,
                sessionMode: .notification
            )
        }
    }
    
    // MARK: - Notification Action Handling
    private func handleNotificationAction(_ action: NotificationAction) {
        switch action {
        case .studyCards(let cardIDs):
            loadCardsAndStartSession(cardIDs: cardIDs)
        }
    }
    
    private func loadCardsAndStartSession(cardIDs: [String]) {
        // Fetch cards by their IDs
        let descriptor = FetchDescriptor<Flashcard>()
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            let matchingCards = allCards.filter { card in
                let cardIDString = card.persistentModelID.hashValue.description
                return cardIDs.contains(cardIDString)
            }
            
            guard !matchingCards.isEmpty else {
                print("MainTabView: No matching cards found for notification")
                return
            }
            
            // Switch to Today tab and start study session
            selectedTab = 0
            notificationCards = matchingCards
            
            // Mark notification as sent (user is now studying)
            NotificationManager.shared.markNotificationAsSent(
                identifier: "notification-\(cardIDs.joined(separator: "-"))",
                modelContext: modelContext
            )
            
            // Small delay to ensure tab switch completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingNotificationStudySession = true
            }
            
        } catch {
            print("MainTabView: Error loading cards for notification: \(error)")
        }
    }
}

#Preview {
    MainTabView()
}