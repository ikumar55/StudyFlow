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
    @Query private var pendingNotifications: [PendingNotification]
    @Query private var dailyCompletions: [DailyCardCompletion]
    
    // Study Session State
    @State private var showingStudySession = false
    @State private var studySessionCards: [Flashcard] = []
    @State private var studySessionMode: StudySessionType = .allCards
    
    // View All State
    @State private var showAllOverdue = false
    @State private var showAllPendingNotifications = false
    @State private var showAllLearning = false
    @State private var showAllCompleted = false
    
    var body: some View {
        return NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with date and stats
                    todayHeader
                    
                    // Priority sections with improved spacing
                    if !overdueCards.isEmpty {
                        overdueSection
                    }
                    
                    if !pendingNotificationCards.isEmpty {
                        pendingNotificationsSection
                    }
                    
                    if !studyingCards.isEmpty {
                        studyingSection
                    }
                    
                    if !completedTodayCards.isEmpty {
                        completedTodaySection
                    }
                    
                    // Study action buttons
                    studyActionButtons
                    
                    Spacer(minLength: 100) // Bottom padding
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
    var todaysCards: [Flashcard] {
        SpacedRepetitionEngine.getTodaysCards(from: allFlashcards, maxLimit: 30)
    }
    
    var overdueCards: [Flashcard] {
        todaysCards.filter { $0.isOverdue && $0.overdueStatus.warningLevel <= 3 }
    }
    
    var pendingNotificationCards: [Flashcard] {
        // Get today's pending notifications
        let todaysPendingNotifications = pendingNotifications.filter { notification in
            Calendar.current.isDateInToday(notification.studyDate) && notification.isPending
        }
        
        // Extract card IDs from pending notifications
        let pendingCardIDs = Set(todaysPendingNotifications.flatMap { $0.cardIDs })
        
        // Return flashcards that match the pending notification IDs
        return allFlashcards.filter { card in
            let cardID = card.persistentModelID.hashValue.description
            return pendingCardIDs.contains(cardID)
        }
    }
    
    var studyingCards: [Flashcard] {
        // All cards planned for today regardless of state (learning, reviewing, mastered)
        // Exclude overdue and pending notification cards
        let completedIDs = Set(todaysCompletions.map { $0.flashcardID })
        let pendingIDs = Set(pendingNotificationCards.map { $0.persistentModelID.hashValue.description })
        return todaysCards.filter { card in
            !card.isOverdue && 
            !completedIDs.contains(card.persistentModelID.hashValue.description) &&
            !pendingIDs.contains(card.persistentModelID.hashValue.description)
        }
    }
    
    var notifiedTodayCards: [Flashcard] {
        // Cards that were sent in notifications today but not yet studied
        let todaysNotifications = pendingNotifications.filter { notification in
            Calendar.current.isDateInToday(notification.studyDate) && 
            notification.sentDate != nil && 
            notification.completedDate == nil && 
            !notification.wasSkipped
        }
        
        let notifiedCardIDs = Set(todaysNotifications.flatMap { $0.cardIDs })
        return allFlashcards.filter { card in
            let cardID = card.persistentModelID.hashValue.description
            return notifiedCardIDs.contains(cardID)
        }
    }
    
    var awaitingNotificationCards: [Flashcard] {
        // Cards scheduled for today but not yet sent in notifications
        let completedIDs = Set(todaysCompletions.map { $0.flashcardID })
        let notifiedIDs = Set(notifiedTodayCards.map { $0.persistentModelID.hashValue.description })
        
        return todaysCards.filter { card in
            let cardID = card.persistentModelID.hashValue.description
            return !card.isOverdue && 
                   !completedIDs.contains(cardID) && 
                   !notifiedIDs.contains(cardID)
        }
    }
    
    var completedTodayCards: [(Flashcard, DailyCardCompletion)] {
        // Get today's completions and match them with flashcards
        let completedIDs = todaysCompletions.map { $0.flashcardID }
        let completedFlashcards = allFlashcards.filter { completedIDs.contains($0.persistentModelID.hashValue.description) }
        
        return completedFlashcards.compactMap { flashcard in
            if let completion = todaysCompletions.first(where: { $0.flashcardID == flashcard.persistentModelID.hashValue.description }) {
                return (flashcard, completion)
            }
            return nil
        }.sorted { $0.1.completedDate > $1.1.completedDate } // Most recent first
    }
    
    var todaysCompletions: [DailyCardCompletion] {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyCompletions.filter { Calendar.current.isDate($0.studyDate, inSameDayAs: today) }
    }
    
    var totalCardsToday: Int {
        overdueCards.count + pendingNotificationCards.count + studyingCards.count
    }
    
    var estimatedTimeMinutes: Int {
        // Estimate ~30 seconds per card
        max(1, totalCardsToday / 2)
    }
    
    // MARK: - View Components
    var todayHeader: some View {
        VStack(spacing: 16) {
            // Main title and date
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Today")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                Text(Date(), style: .date)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Prominent study stats card
            if totalCardsToday > 0 {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(totalCardsToday) cards")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("~\(estimatedTimeMinutes) min estimated")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.headline)
                        .fontWeight(.medium)
                    Text("No cards scheduled for today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    var overdueSection: some View {
        CardSectionView(
            title: "OVERDUE",
            subtitle: "\(overdueCards.count) cards",
            icon: "exclamationmark.triangle.fill",
            cards: overdueCards,
            backgroundColor: Color.white,
            sectionBackgroundColor: Color.overdueBackground,
            headerBackgroundColor: Color.iosLightGray,
            accentColor: .overdueWarning,
            borderAccentColor: .overdueAccent,
            showAll: $showAllOverdue,
            onStudy: {
                HapticFeedback.light()
                startBucketSession(cards: overdueCards, title: "Overdue Cards")
            },
            onCardTap: { card in
                HapticFeedback.light()
                startSingleCardSession(card: card)
            }
        )
    }
    
    var pendingNotificationsSection: some View {
        CardSectionView(
            title: "PENDING NOTIFICATIONS",
            subtitle: "\(pendingNotificationCards.count) cards",
            icon: "bell.fill",
            cards: pendingNotificationCards,
            backgroundColor: Color.white,
            sectionBackgroundColor: Color.reviewingBackground, // Use blue tint for notifications
            headerBackgroundColor: Color.iosLightGray,
            accentColor: .notificationBlue,
            borderAccentColor: .reviewingBorderAccent,
            showAll: $showAllPendingNotifications,
            onStudy: {
                HapticFeedback.light()
                startBucketSession(cards: pendingNotificationCards, title: "Pending Notification Cards")
            },
            onCardTap: { card in
                HapticFeedback.light()
                startSingleCardSession(card: card)
            }
        )
    }
    
    var studyingSection: some View {
        StudyingTodaySection(
            notifiedCards: notifiedTodayCards,
            awaitingCards: awaitingNotificationCards,
            showAll: $showAllLearning,
            onStudyNotified: {
                HapticFeedback.light()
                startBucketSession(cards: notifiedTodayCards, title: "Notified Cards")
            },
            onStudyAwaiting: {
                HapticFeedback.light()
                startBucketSession(cards: awaitingNotificationCards, title: "Awaiting Notification Cards")
            },
            onCardTap: { card in
                HapticFeedback.light()
                startSingleCardSession(card: card)
            }
        )
    }
    

    
    var completedTodaySection: some View {
        CompletedTodayView(
            completedCards: completedTodayCards,
            showAll: $showAllCompleted,
            onCardTap: { flashcard in
                HapticFeedback.light()
                startSingleCardSession(card: flashcard)
            }
        )
    }
    
    var studyActionButtons: some View {
        VStack(spacing: 16) {
            if totalCardsToday > 0 {
                // Primary study button - more prominent
                Button(action: {
                    HapticFeedback.medium()
                    startAllCardsSession()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Study All")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("\(totalCardsToday) cards • ~\(estimatedTimeMinutes) min")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .opacity(0.6)
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Quick session button - more subtle
                Button(action: {
                    HapticFeedback.light()
                    startQuickSession()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                        Text("Quick Session")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("5 cards")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            } else {
                // No cards message with add cards button
                Button(action: navigateToLibrary) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Cards to Study")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    

    
    // MARK: - Actions
    func startAllCardsSession() {
        let allCards = overdueCards + pendingNotificationCards + studyingCards
        studySessionCards = allCards
        studySessionMode = .allCards
        showingStudySession = true
    }
    
    func startQuickSession() {
        // Select up to 5 random cards from available cards
        let allCards = overdueCards + pendingNotificationCards + studyingCards
        studySessionCards = Array(allCards.shuffled().prefix(5))
        studySessionMode = .custom
        showingStudySession = true
    }
    
    func startSingleCardSession(card: Flashcard) {
        studySessionCards = [card]
        studySessionMode = .custom
        showingStudySession = true
    }
    
    func startBucketSession(cards: [Flashcard], title: String) {
        studySessionCards = cards
        studySessionMode = .custom // Use custom mode for bucket-specific sessions
        showingStudySession = true
    }
    
    func navigateToLibrary() {
        // Note: In a TabView, we can't programmatically switch tabs from a child view
        // This button encourages users to manually switch to the Library tab
        // In a production app, we might use a coordinator pattern or notification
        print("User should switch to Library tab to add cards")
    }
}


// MARK: - Card Section View
struct CardSectionView: View {
    let title: String
    let subtitle: String
    let icon: String
    let cards: [Flashcard]
    let backgroundColor: Color
    let sectionBackgroundColor: Color
    let headerBackgroundColor: Color
    let accentColor: Color
    let borderAccentColor: Color
    @Binding var showAll: Bool
    let onStudy: () -> Void
    let onCardTap: ((Flashcard) -> Void)?
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        cards: [Flashcard],
        backgroundColor: Color,
        sectionBackgroundColor: Color,
        headerBackgroundColor: Color,
        accentColor: Color,
        borderAccentColor: Color,
        showAll: Binding<Bool>,
        onStudy: @escaping () -> Void,
        onCardTap: ((Flashcard) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.cards = cards
        self.backgroundColor = backgroundColor
        self.sectionBackgroundColor = sectionBackgroundColor
        self.headerBackgroundColor = headerBackgroundColor
        self.accentColor = accentColor
        self.borderAccentColor = borderAccentColor
        self._showAll = showAll
        self.onStudy = onStudy
        self.onCardTap = onCardTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with colored border accent
            HStack(spacing: 0) {
                // Colored left border
                Rectangle()
                    .fill(borderAccentColor)
                    .frame(width: 2)
                
                HStack(spacing: 12) {
                    // Icon with accent color
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)
                        .frame(width: 24, height: 24)
                    
                    // Title and subtitle with enhanced typography
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold) // Enhanced to semibold
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.subtitleGray) // Using custom gray color
                    }
                    
                    Spacer()
                    
                    // Action buttons - right aligned
                    if !cards.isEmpty {
                        HStack(spacing: 8) {
                            // Study button with icon
                            Button(action: onStudy) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                        .font(.caption2)
                                    Text("Study")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor)
                                .clipShape(Capsule())
                            }
                            
                            // View All button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAll.toggle()
                                }
                            }) {
                                Text(showAll ? "Less" : "All")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(headerBackgroundColor)
            
            // Card previews with enhanced styling
            if !cards.isEmpty {
                VStack(spacing: 0) {
                    let cardsToShow = showAll ? cards : Array(cards.prefix(3))
                    ForEach(Array(cardsToShow.enumerated()), id: \.element) { index, card in
                        VStack(spacing: 0) {
                            CardPreviewRow(card: card, accentColor: accentColor, onArrowTap: onCardTap)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(backgroundColor)
                            
                            // Add subtle divider between cards (except last)
                            if index < cardsToShow.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#F0F0F0") ?? Color.gray.opacity(0.2))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    if !showAll && cards.count > 3 {
                        HStack {
                            Text("and \(cards.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.subtitleGray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(backgroundColor)
                    }
                }
            }
        }
        .background(sectionBackgroundColor) // Subtle section background
        .clipShape(RoundedRectangle(cornerRadius: 6)) // Slightly rounded corners
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Card Preview Row
struct CardPreviewRow: View {
    let card: Flashcard
    let accentColor: Color
    let onArrowTap: ((Flashcard) -> Void)?
    
    init(card: Flashcard, accentColor: Color, onArrowTap: ((Flashcard) -> Void)? = nil) {
        self.card = card
        self.accentColor = accentColor
        self.onArrowTap = onArrowTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Colored dot indicator instead of emoji
            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
            
            // Question preview with better typography
            VStack(alignment: .leading, spacing: 4) {
                Text(card.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Class name moved below question, smaller and more subtle
                if let className = card.lecture?.studyClass?.name {
                    Text(className)
                        .font(.caption2)
                        .foregroundColor(.subtitleGray) // Using custom gray color
                }
            }
            
            Spacer()
            
            // Tappable chevron for single-card study
            if let onArrowTap = onArrowTap {
                Button(action: { onArrowTap(card) }) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.subtitleGray)
                        .opacity(0.8)
                        .padding(8) // Larger tap target
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Non-interactive chevron
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.subtitleGray)
                    .opacity(0.8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - Completed Today View
struct CompletedTodayView: View {
    let completedCards: [(Flashcard, DailyCardCompletion)]
    @Binding var showAll: Bool
    let onCardTap: (Flashcard) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with colored border accent
            HStack(spacing: 0) {
                // Green left border for completed
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 2)
                
                HStack(spacing: 12) {
                    // Checkmark icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COMPLETED TODAY")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("\(completedCards.count) cards")
                            .font(.caption)
                            .foregroundColor(.subtitleGray)
                    }
                    
                    Spacer()
                    
                    // View All button
                    if !completedCards.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAll.toggle()
                            }
                        }) {
                            Text(showAll ? "Less" : "All")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.iosLightGray)
            
            // Completed cards list
            if !completedCards.isEmpty {
                VStack(spacing: 0) {
                    let cardsToShow = showAll ? completedCards : Array(completedCards.prefix(3))
                    ForEach(Array(cardsToShow.enumerated()), id: \.element.0.id) { index, cardCompletion in
                        let (flashcard, completion) = cardCompletion
                        VStack(spacing: 0) {
                            CompletedCardRow(
                                flashcard: flashcard,
                                completion: completion,
                                onTap: { onCardTap(flashcard) }
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            
                            // Add subtle divider between cards (except last)
                            if index < cardsToShow.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#F0F0F0") ?? Color.gray.opacity(0.2))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    if !showAll && completedCards.count > 3 {
                        HStack {
                            Text("and \(completedCards.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.subtitleGray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white)
                    }
                }
            }
        }
        .background(Color.white) // White section background for completed
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Completed Card Row
struct CompletedCardRow: View {
    let flashcard: Flashcard
    let completion: DailyCardCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Accuracy indicator
                Image(systemName: completion.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(completion.wasCorrect ? .green : .red)
                
                // Question and details
                VStack(alignment: .leading, spacing: 4) {
                    Text(flashcard.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        // Class name
                        if let className = flashcard.lecture?.studyClass?.name {
                            Text(className)
                                .font(.caption2)
                                .foregroundColor(.subtitleGray)
                        }
                        
                        Spacer()
                        
                        // Completion time
                        Text(completion.completedDate, style: .time)
                            .font(.caption2)
                            .foregroundColor(.subtitleGray)
                    }
                }
                
                Spacer()
                
                // Subtle chevron to indicate tappability
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.subtitleGray)
                    .opacity(0.8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

// MARK: - Studying Today Section with Subsections
struct StudyingTodaySection: View {
    let notifiedCards: [Flashcard]
    let awaitingCards: [Flashcard]
    @Binding var showAll: Bool
    let onStudyNotified: () -> Void
    let onStudyAwaiting: () -> Void
    let onCardTap: (Flashcard) -> Void
    
    private var totalCards: Int {
        notifiedCards.count + awaitingCards.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main section header
            HStack(spacing: 0) {
                // Colored left border
                Rectangle()
                    .fill(Color.learningBorderAccent)
                    .frame(width: 2)
                
                HStack(spacing: 12) {
                    // Icon with accent color
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.learningAccent)
                        .frame(width: 24, height: 24)
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STUDYING TODAY")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("\(totalCards) cards")
                            .font(.caption)
                            .foregroundColor(.subtitleGray)
                    }
                    
                    Spacer()
                    
                    // View All button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAll.toggle()
                        }
                    }) {
                        Text(showAll ? "Less" : "All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.learningAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.iosLightGray)
            
            // Subsections
            VStack(spacing: 0) {
                // Notified Today subsection
                if !notifiedCards.isEmpty {
                    SubsectionView(
                        title: "📱 Notified Today",
                        cards: notifiedCards,
                        accentColor: .blue,
                        showAll: showAll,
                        onStudy: onStudyNotified,
                        onCardTap: onCardTap
                    )
                    
                    if !awaitingCards.isEmpty {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
                
                // Awaiting Notification subsection
                if !awaitingCards.isEmpty {
                    SubsectionView(
                        title: "⏳ Awaiting Notification",
                        cards: awaitingCards,
                        accentColor: .learningAccent,
                        showAll: showAll,
                        onStudy: onStudyAwaiting,
                        onCardTap: onCardTap
                    )
                }
                
                // Empty state
                if notifiedCards.isEmpty && awaitingCards.isEmpty {
                    HStack {
                        Text("No cards scheduled for study today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
        }
        .background(Color.learningBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Subsection View
struct SubsectionView: View {
    let title: String
    let cards: [Flashcard]
    let accentColor: Color
    let showAll: Bool
    let onStudy: () -> Void
    let onCardTap: (Flashcard) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Subsection header
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("(\(cards.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Study button
                Button(action: onStudy) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text("Study")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // Card previews
            let cardsToShow = showAll ? cards : Array(cards.prefix(2))
            ForEach(Array(cardsToShow.enumerated()), id: \.element) { index, card in
                VStack(spacing: 0) {
                    Button(action: { onCardTap(card) }) {
                        CardPreviewRow(card: card, accentColor: accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.white)
                    
                    // Add subtle divider between cards (except last)
                    if index < cardsToShow.count - 1 {
                        Rectangle()
                            .fill(Color(hex: "#F0F0F0") ?? Color.gray.opacity(0.2))
                            .frame(height: 0.5)
                            .padding(.horizontal, 20)
                    }
                }
            }
            
            // Show "and X more" if not showing all
            if !showAll && cards.count > 2 {
                HStack {
                    Text("and \(cards.count - 2) more...")
                        .font(.caption)
                        .foregroundColor(.subtitleGray)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
    }
}

#Preview {
    ContentView()
}

