//
//  StudySessionView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let initialCards: [Flashcard]
    let sessionMode: StudySessionType
    
    @State private var currentCardIndex = 0
    @State private var isAnswerVisible = false
    @State private var correctAnswers = 0
    @State private var sessionStartTime = Date()
    @State private var showingPromotionAlert = false
    @State private var cardToPromote: Flashcard?
    @State private var showingSessionComplete = false
    
    private var currentCard: Flashcard? {
        guard currentCardIndex < initialCards.count else { return nil }
        return initialCards[currentCardIndex]
    }
    
    private var progress: Double {
        guard !initialCards.isEmpty else { return 0 }
        return Double(currentCardIndex) / Double(initialCards.count)
    }
    
    private var accuracy: Double {
        guard currentCardIndex > 0 else { return 0 }
        return Double(correctAnswers) / Double(currentCardIndex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    sessionProgressHeader
                    
                    // Main card area
                    if let card = currentCard {
                        cardDisplayArea(for: card)
                    } else {
                        sessionCompleteView
                    }
                    
                    // Action buttons
                    if currentCard != nil && isAnswerVisible {
                        answerButtons
                    }
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        dismiss()
                    }
                }
            }
            .alert("Promote Card?", isPresented: $showingPromotionAlert, presenting: cardToPromote) { card in
                Button("Keep Learning") { }
                Button("Promote to Reviewing") {
                    promoteCard(card, to: .reviewing)
                }
                if card.studyState == .reviewing {
                    Button("Promote to Mastered") {
                        promoteCard(card, to: .mastered)
                    }
                }
            } message: { card in
                Text("You've answered this card correctly \(card.correctCount) times. Would you like to move it to less frequent review?")
            }
            .fullScreenCover(isPresented: $showingSessionComplete) {
                SessionCompleteView(
                    totalCards: initialCards.count,
                    correctAnswers: correctAnswers,
                    accuracy: accuracy,
                    duration: Date().timeIntervalSince(sessionStartTime),
                    onDismiss: { dismiss() }
                )
            }
        }
    }
    
    // MARK: - Session Progress Header
    private var sessionProgressHeader: some View {
        VStack(spacing: 12) {
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Card \(currentCardIndex + 1) of \(initialCards.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(accuracy * 100))% correct")
                        .font(.subheadline)
                        .foregroundColor(accuracy >= 0.8 ? .green : accuracy >= 0.6 ? .orange : .red)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Card Display Area
    private func cardDisplayArea(for card: Flashcard) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Card content
            VStack(spacing: 20) {
                // Study state indicator
                HStack {
                    Text(card.studyState.emoji)
                    Text(card.studyState.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
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
                
                // Question/Answer card
                flashcardView(for: card)
                
                // Tap instruction
                if !isAnswerVisible {
                    Text("Tap card to reveal answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: isAnswerVisible)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Flashcard View with Flip Animation
    private func flashcardView(for card: Flashcard) -> some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Card content
            VStack(spacing: 16) {
                if !isAnswerVisible {
                    // Question side
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text(card.question)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                } else {
                    // Answer side
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text(card.answer)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
        }
        .rotation3DEffect(
            .degrees(isAnswerVisible ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture {
            if !isAnswerVisible {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnswerVisible = true
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - Answer Buttons
    private var answerButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // "Need Practice" button
                Button(action: { answerCard(correct: false) }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Need Practice")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // "Got It" button
                Button(action: { answerCard(correct: true) }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Got It!")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Optional: Mark as difficult button
            Button("Mark as Difficult") {
                // TODO: Implement difficulty marking
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Session Complete View
    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("\(correctAnswers) out of \(initialCards.count) correct")
                    .font(.headline)
                
                Text("\(Int(accuracy * 100))% accuracy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("View Results") {
                showingSessionComplete = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .onAppear {
            saveStudySession()
        }
    }
    
    // MARK: - Actions
    private func answerCard(correct: Bool) {
        guard let card = currentCard else { return }
        
        // Update card statistics
        card.totalAttempts += 1
        card.lastStudied = Date()
        
        if correct {
            card.correctCount += 1
            correctAnswers += 1
            
            // Check for promotion eligibility
            if card.correctCount >= 5 && card.canBePromoted {
                cardToPromote = card
                showingPromotionAlert = true
            }
        } else {
            // Reset correct count on wrong answer
            card.correctCount = 0
        }
        
        // Update next scheduled date based on performance
        updateCardSchedule(card, wasCorrect: correct)
        
        // Save changes
        try? modelContext.save()
        
        // Move to next card
        moveToNextCard()
    }
    
    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardIndex += 1
            isAnswerVisible = false
        }
        
        // Check if session is complete
        if currentCardIndex >= initialCards.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingSessionComplete = true
            }
        }
    }
    
    private func updateCardSchedule(_ card: Flashcard, wasCorrect: Bool) {
        let calendar = Calendar.current
        
        if !wasCorrect {
            // Wrong answer: review again today or tomorrow
            card.nextScheduledDate = calendar.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            return
        }
        
        // Correct answer: calculate next review based on study state
        let daysToAdd: Int
        switch card.studyState {
        case .learning:
            daysToAdd = min(card.correctCount, 3) // 1, 2, 3 days max for learning
        case .reviewing:
            daysToAdd = min(card.correctCount * 2, 14) // 2, 4, 6, 8... up to 14 days
        case .mastered:
            daysToAdd = min(card.correctCount * 7, 90) // Weekly intervals, up to 90 days
        case .inactive:
            daysToAdd = 1 // Shouldn't happen, but default to tomorrow
        }
        
        card.nextScheduledDate = calendar.date(byAdding: .day, value: daysToAdd, to: Date()) ?? Date()
    }
    
    private func promoteCard(_ card: Flashcard, to newState: StudyCardState) {
        card.studyState = newState
        card.lastPromotionOffered = Date()
        
        // Reset correct count to start fresh in new state
        card.correctCount = 0
        
        // Update schedule for new state
        updateCardSchedule(card, wasCorrect: true)
        
        try? modelContext.save()
    }
    
    private func saveStudySession() {
        let session = StudySession(sessionType: sessionMode, totalCards: initialCards.count)
        session.correctAnswers = correctAnswers
        session.completedDate = Date()
        
        modelContext.insert(session)
        try? modelContext.save()
    }
}

// MARK: - Session Complete View
struct SessionCompleteView: View {
    let totalCards: Int
    let correctAnswers: Int
    let accuracy: Double
    let duration: TimeInterval
    let onDismiss: () -> Void
    
    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration icon
                Image(systemName: accuracy >= 0.8 ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(accuracy >= 0.8 ? .yellow : .green)
                
                // Results
                VStack(spacing: 16) {
                    Text("Great Work!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        StatRow(title: "Cards Studied", value: "\(totalCards)")
                        StatRow(title: "Correct Answers", value: "\(correctAnswers)")
                        StatRow(title: "Accuracy", value: "\(Int(accuracy * 100))%")
                        StatRow(title: "Study Time", value: formattedDuration)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Motivational message
                Text(motivationalMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Continue Learning") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    
                    Button("View Progress") {
                        // TODO: Navigate to progress tab
                        onDismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var motivationalMessage: String {
        switch accuracy {
        case 0.9...:
            return "Outstanding! You're mastering this material."
        case 0.8..<0.9:
            return "Excellent work! You're making great progress."
        case 0.7..<0.8:
            return "Good job! Keep practicing to improve."
        case 0.5..<0.7:
            return "You're learning! Review the challenging cards."
        default:
            return "Every expert was once a beginner. Keep going!"
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}



#Preview {
    StudySessionView(
        initialCards: [],
        sessionMode: .allCards
    )
}