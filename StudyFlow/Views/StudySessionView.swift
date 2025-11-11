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
    @State private var showingEditCard = false
    @State private var editedQuestion = ""
    @State private var editedAnswer = ""
    @State private var editedQuestionPhotos: [String] = []
    @State private var editedAnswerPhotos: [String] = []
    
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
            .sheet(isPresented: $showingEditCard, onDismiss: {
                // Reset edit fields when sheet is dismissed
                editedQuestion = ""
                editedAnswer = ""
            }) {
                editCardSheet
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
                    
                    HStack {
                        HStack(spacing: 8) {
                            if let className = card.lecture?.studyClass?.name {
                                Text(className)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemFill))
                                    .clipShape(Capsule())
                            }
                            
                            if let lectureName = card.lecture?.title {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(lectureName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        // Edit button
                        Button(action: {
                            HapticFeedback.light()
                            showingEditCard = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
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
                            .font(.cardQuestion)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        // Question photos
                        if !card.questionPhotos.isEmpty {
                            PhotoGridView(photoFileNames: card.questionPhotos, columns: 2)
                                .padding(.top, 8)
                        }
                    }
                } else {
                    // Answer side
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text(card.answer)
                            .font(.cardAnswer)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        // Answer photos
                        if !card.answerPhotos.isEmpty {
                            PhotoGridView(photoFileNames: card.answerPhotos, columns: 2)
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
        }
        .rotation3DEffect(
            .degrees(isAnswerVisible ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        // Fix text mirroring by applying counter-rotation to content when flipped
        .scaleEffect(x: isAnswerVisible ? -1 : 1, y: 1)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnswerVisible.toggle()
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Answer Buttons
    private var answerButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // "Need Practice" button
                Button(action: { 
                    HapticFeedback.light()
                    answerCard(correct: false) 
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Need Practice")
                    }
                }
                .buttonStyle(StudyAnswerWrongButtonStyle())
                
                // "Got It" button
                Button(action: { 
                    HapticFeedback.success()
                    answerCard(correct: true) 
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Got It!")
                    }
                }
                .buttonStyle(StudyAnswerCorrectButtonStyle())
            }
        }
        .padding()
    }
    
    // MARK: - Session Complete View
    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Dynamic feedback based on performance
            sessionFeedbackIcon
            
            sessionFeedbackTitle
            
            VStack(spacing: 8) {
                Text("\(correctAnswers) out of \(initialCards.count) correct")
                    .font(.headline)
                
                Text("\(Int(accuracy * 100))% accuracy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            sessionFeedbackMessage
            
            Button("Continue Learning") {
                showingSessionComplete = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .onAppear {
            saveStudySession()
        }
    }
    
    // MARK: - Session Feedback Components
    private var sessionFeedbackIcon: some View {
        Group {
            if accuracy >= 0.8 {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
            } else if accuracy >= 0.6 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            } else if accuracy >= 0.3 {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var sessionFeedbackTitle: some View {
        Group {
            if accuracy >= 0.8 {
                Text("Outstanding!")
                    .font(.title)
                    .fontWeight(.bold)
            } else if accuracy >= 0.6 {
                Text("Great Work!")
                    .font(.title)
                    .fontWeight(.bold)
            } else if accuracy >= 0.3 {
                Text("Keep Going!")
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("Practice Makes Perfect!")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var sessionFeedbackMessage: some View {
        Group {
            if accuracy >= 0.8 {
                Text("You're mastering this material!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if accuracy >= 0.6 {
                Text("Solid progress! Keep studying to master these concepts.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if accuracy >= 0.3 {
                Text("You're learning! Review these cards again to improve.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Every expert was once a beginner. Keep going!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Edit Card Sheet
    private var editCardSheet: some View {
        NavigationView {
            Form {
                Section("Question") {
                    TextEditor(text: $editedQuestion)
                        .frame(minHeight: 80)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Section("Question Photos (Max 5)") {
                    PhotoPicker(photos: $editedQuestionPhotos, title: "Question Photos")
                }
                
                Section("Answer") {
                    TextEditor(text: $editedAnswer)
                        .frame(minHeight: 80)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Section("Answer Photos (Max 5)") {
                    PhotoPicker(photos: $editedAnswerPhotos, title: "Answer Photos")
                }
            }
            .navigationTitle("Edit Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditCard = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEditedCard()
                    }
                    .disabled(editedQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Pre-populate fields when sheet appears
            if let card = currentCard {
                editedQuestion = card.question
                editedAnswer = card.answer
                editedQuestionPhotos = card.questionPhotos
                editedAnswerPhotos = card.answerPhotos
            }
        }
    }
    
    // MARK: - Actions
    private func saveEditedCard() {
        guard let card = currentCard else { return }
        
        // Update the card with edited content
        card.question = editedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        card.answer = editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update photos
        card.questionPhotos = editedQuestionPhotos
        card.answerPhotos = editedAnswerPhotos
        
        // Save the context
        do {
            try modelContext.save()
            HapticFeedback.success()
            showingEditCard = false
        } catch {
            print("Error saving edited card: \(error)")
            HapticFeedback.error()
        }
    }
    
    private func answerCard(correct: Bool) {
        guard let card = currentCard else { return }
        
        // Update card statistics
        card.totalAttempts += 1
        card.lastStudied = Date()
        
        if correct {
            card.correctCount += 1
            correctAnswers += 1
            
            // Check for promotion eligibility using the engine
            if SpacedRepetitionEngine.shouldOfferPromotion(for: card) {
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
        // Use the sophisticated spaced repetition engine
        card.nextScheduledDate = SpacedRepetitionEngine.calculateNextReviewDate(
            for: card,
            wasCorrect: wasCorrect,
            responseTime: nil // Could track response time in future
        )
        
        // Track daily completion for Today tab
        let completion = DailyCardCompletion(
            flashcardID: card.persistentModelID.hashValue.description,
            wasCorrect: wasCorrect
        )
        modelContext.insert(completion)
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
        
        // If this was a notification session, mark the notification as completed
        if sessionMode == .notification {
            let cardIDs = initialCards.map { $0.persistentModelID.hashValue.description }
            NotificationManager.shared.markNotificationAsCompleted(
                cardIDs: cardIDs,
                modelContext: modelContext
            )
        }
        
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