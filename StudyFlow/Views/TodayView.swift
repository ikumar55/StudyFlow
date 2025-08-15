//
//  TodayView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFlashcards: [Flashcard]
    
    // Study Session State
    @State private var showingStudySession = false
    @State private var studySessionCards: [Flashcard] = []
    @State private var studySessionMode: StudySessionType = .allCards
    
    var body: some View {
        return NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header with date
                    todayHeader
                    
                    // Priority sections
                    if !overdueCards.isEmpty {
                        overdueSection
                    }
                    
                    if !pendingNotificationCards.isEmpty {
                        pendingNotificationsSection
                    }
                    
                    if !learningCards.isEmpty {
                        learningSection
                    }
                    
                    if !reviewingCards.isEmpty {
                        reviewingSection
                    }
                    
                    if !masteredCards.isEmpty {
                        masteredSection
                    }
                    
                    // Study action buttons
                    studyActionButtons
                    
                    Spacer(minLength: 100) // Bottom padding
                }
                .padding()
            }
            .navigationTitle("Today")
            .background(Color(.systemGroupedBackground))
            .fullScreenCover(isPresented: $showingStudySession) {
                StudySessionView(
                    initialCards: studySessionCards,
                    sessionMode: studySessionMode
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    var overdueCards: [Flashcard] {
        allFlashcards.filter { $0.isActive && $0.isOverdue && $0.overdueStatus.warningLevel <= 3 }
            .sorted { $0.nextScheduledDate < $1.nextScheduledDate }
    }
    
    var pendingNotificationCards: [Flashcard] {
        // For now, return empty array - will implement notification tracking later
        []
    }
    
    var learningCards: [Flashcard] {
        allFlashcards.filter {
            $0.isActive &&
            $0.studyState == .learning &&
            !$0.isOverdue &&
            shouldAppearToday($0)
        }
        .sorted { $0.createdDate > $1.createdDate }
        .prefix(20) // Limit for now
        .map { $0 }
    }
    
    var reviewingCards: [Flashcard] {
        allFlashcards.filter {
            $0.isActive &&
            $0.studyState == .reviewing &&
            shouldAppearToday($0)
        }
        .sorted { $0.nextScheduledDate < $1.nextScheduledDate }
    }
    
    var masteredCards: [Flashcard] {
        allFlashcards.filter {
            $0.isActive &&
            $0.studyState == .mastered &&
            shouldAppearToday($0)
        }
        .sorted { $0.nextScheduledDate < $1.nextScheduledDate }
    }
    
    var totalCardsToday: Int {
        overdueCards.count + pendingNotificationCards.count +
        learningCards.count + reviewingCards.count + masteredCards.count
    }
    
    var estimatedTimeMinutes: Int {
        // Estimate ~30 seconds per card
        max(1, totalCardsToday / 2)
    }
    
    // MARK: - View Components
    var todayHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Date(), style: .date)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Quick stats
                if totalCardsToday > 0 {
                    Text("\(totalCardsToday) cards • ~\(estimatedTimeMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemFill))
                        .clipShape(Capsule())
                }
            }
            
            if totalCardsToday == 0 {
                Text("No cards scheduled for today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var overdueSection: some View {
        CardSectionView(
            title: "🚨 OVERDUE",
            subtitle: "\(overdueCards.count) cards",
            cards: overdueCards,
            backgroundColor: Color.red.opacity(0.1),
            accentColor: .red
        )
    }
    
    var pendingNotificationsSection: some View {
        CardSectionView(
            title: "🔔 PENDING NOTIFICATIONS",
            subtitle: "\(pendingNotificationCards.count) cards",
            cards: pendingNotificationCards,
            backgroundColor: Color.blue.opacity(0.1),
            accentColor: .blue
        )
    }
    
    var learningSection: some View {
        CardSectionView(
            title: "🟠 LEARNING TODAY",
            subtitle: "\(learningCards.count) cards",
            cards: learningCards,
            backgroundColor: Color.orange.opacity(0.1),
            accentColor: .orange
        )
    }
    
    var reviewingSection: some View {
        CardSectionView(
            title: "🟡 REVIEWING TODAY",
            subtitle: "\(reviewingCards.count) cards",
            cards: reviewingCards,
            backgroundColor: Color.yellow.opacity(0.1),
            accentColor: .yellow
        )
    }
    
    var masteredSection: some View {
        CardSectionView(
            title: "🟢 MASTERED TODAY",
            subtitle: "\(masteredCards.count) cards",
            cards: masteredCards,
            backgroundColor: Color.green.opacity(0.1),
            accentColor: .green
        )
    }
    
    var studyActionButtons: some View {
        VStack(spacing: 12) {
            if totalCardsToday > 0 {
                // Primary study button
                Button(action: startAllCardsSession) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Study All • \(totalCardsToday) cards • ~\(estimatedTimeMinutes) min")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Quick session button
                Button(action: startQuickSession) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                        Text("Quick Session • 5 cards")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // No cards message with add cards button
                Button(action: navigateToLibrary) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Cards to Study")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    func shouldAppearToday(_ card: Flashcard) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cardDate = calendar.startOfDay(for: card.nextScheduledDate)
        
        switch card.studyState {
        case .learning:
            return true // Learning cards appear daily
        case .reviewing:
            return cardDate <= today // Reviewing cards appear when due
        case .mastered:
            return cardDate <= today // Mastered cards appear when due
        case .inactive:
            return false // Inactive cards never appear
        }
    }
    
    // MARK: - Actions
    func startAllCardsSession() {
        let allCards = overdueCards + pendingNotificationCards + learningCards + reviewingCards + masteredCards
        studySessionCards = allCards
        studySessionMode = .allCards
        showingStudySession = true
    }
    
    func startQuickSession() {
        // Select up to 5 random cards from available cards
        let allCards = overdueCards + pendingNotificationCards + learningCards + reviewingCards + masteredCards
        studySessionCards = Array(allCards.shuffled().prefix(5))
        studySessionMode = .custom
        showingStudySession = true
    }
    
    func navigateToLibrary() {
        // TODO: Navigate to library tab
        print("Navigate to library")
    }
}


// MARK: - Card Section View
struct CardSectionView: View {
    let title: String
    let subtitle: String
    let cards: [Flashcard]
    let backgroundColor: Color
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !cards.isEmpty {
                    Button("View All") {
                        // TODO: Show all cards in this category
                    }
                    .font(.caption)
                    .foregroundColor(accentColor)
                }
            }
            
            // Card previews (show first 3)
            if !cards.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(cards.prefix(3)), id: \.self) { card in
                        CardPreviewRow(card: card)
                    }
                    
                    if cards.count > 3 {
                        Text("and \(cards.count - 3) more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Card Preview Row
struct CardPreviewRow: View {
    let card: Flashcard
    
    var body: some View {
        HStack {
            // Study state indicator
            Text(card.studyState.emoji)
                .font(.caption)
            
            // Question preview
            Text(card.question)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Class name (if available)
            if let className = card.lecture?.studyClass?.name {
                Text(className)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}

