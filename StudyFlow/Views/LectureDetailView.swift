//
//  LectureDetailView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct LectureDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let lecture: Lecture
    
    @State private var showingAddFlashcard = false
    @State private var showingBulkOperations = false
    @State private var selectedCards: Set<Flashcard> = []
    @State private var isSelectionMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Lecture overview
            lectureOverviewSection
            
            // Flashcards list
            flashcardsList
        }
        .navigationTitle(lecture.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !lecture.flashcards.isEmpty {
                    Button(isSelectionMode ? "Done" : "Select") {
                        withAnimation {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedCards.removeAll()
                            }
                        }
                    }
                }
                
                Button("Add Card") {
                    showingAddFlashcard = true
                }
            }
        }
        .sheet(isPresented: $showingAddFlashcard) {
            AddFlashcardView(lecture: lecture)
        }
        .sheet(isPresented: $showingBulkOperations) {
            BulkOperationsView(
                selectedCards: Array(selectedCards),
                onComplete: {
                    selectedCards.removeAll()
                    isSelectionMode = false
                }
            )
        }
    }
    
    // MARK: - Lecture Overview
    private var lectureOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = lecture.lectureDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Statistics
            HStack(spacing: 16) {
                StatPill(title: "Total", value: "\(lecture.flashcardCount)", color: .blue)
                StatPill(title: "Active", value: "\(lecture.activeFlashcardCount)", color: .green)
                
                let learningCount = lecture.flashcards.filter { $0.studyState == .learning && $0.isActive }.count
                let reviewingCount = lecture.flashcards.filter { $0.studyState == .reviewing && $0.isActive }.count
                let masteredCount = lecture.flashcards.filter { $0.studyState == .mastered && $0.isActive }.count
                
                if learningCount > 0 {
                    StatPill(title: "Learning", value: "\(learningCount)", color: .orange)
                }
                if reviewingCount > 0 {
                    StatPill(title: "Reviewing", value: "\(reviewingCount)", color: .yellow)
                }
                if masteredCount > 0 {
                    StatPill(title: "Mastered", value: "\(masteredCount)", color: .green)
                }
                
                Spacer()
            }
            
            // Bulk operations button
            if isSelectionMode && !selectedCards.isEmpty {
                Button("Edit \(selectedCards.count) Cards") {
                    showingBulkOperations = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Flashcards List
    private var flashcardsList: some View {
        Group {
            if lecture.flashcards.isEmpty {
                emptyFlashcardsView
            } else {
                List {
                    ForEach(lecture.flashcards.sorted { $0.createdDate > $1.createdDate }) { flashcard in
                        FlashcardRowView(
                            flashcard: flashcard,
                            isSelected: selectedCards.contains(flashcard),
                            isSelectionMode: isSelectionMode,
                            onToggleSelection: {
                                toggleSelection(for: flashcard)
                            }
                        )
                    }
                    .onDelete(perform: deleteFlashcards)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyFlashcardsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Flashcards")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first flashcard to start studying")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Flashcard") {
                showingAddFlashcard = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    private func toggleSelection(for flashcard: Flashcard) {
        if selectedCards.contains(flashcard) {
            selectedCards.remove(flashcard)
        } else {
            selectedCards.insert(flashcard)
        }
    }
    
    private func deleteFlashcards(offsets: IndexSet) {
        withAnimation {
            let sortedFlashcards = lecture.flashcards.sorted { $0.createdDate > $1.createdDate }
            for index in offsets {
                modelContext.delete(sortedFlashcards[index])
            }
        }
    }
}

// MARK: - Flashcard Row View
struct FlashcardRowView: View {
    let flashcard: Flashcard
    let isSelected: Bool
    let isSelectionMode: Bool
    let onToggleSelection: () -> Void
    
    @State private var showingEditFlashcard = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Study state indicator
            Text(flashcard.studyState.emoji)
                .font(.caption)
            
            // Card content
            VStack(alignment: .leading, spacing: 6) {
                Text(flashcard.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(flashcard.answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Performance indicators
                HStack(spacing: 8) {
                    if flashcard.totalAttempts > 0 {
                        Text("\(Int(flashcard.accuracy * 100))% accuracy")
                            .font(.caption2)
                            .foregroundColor(flashcard.accuracy >= 0.8 ? .green : flashcard.accuracy >= 0.6 ? .orange : .red)
                    }
                    
                    if flashcard.correctCount > 0 {
                        Text("\(flashcard.correctCount) correct")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if flashcard.canBePromoted {
                        Text("Can promote")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Context menu button
            if !isSelectionMode {
                Menu {
                    Button("Edit") {
                        showingEditFlashcard = true
                    }
                    
                    Menu("Change State") {
                        ForEach(StudyCardState.allCases, id: \.self) { state in
                            if state != flashcard.studyState {
                                Button("\(state.emoji) \(state.displayName)") {
                                    flashcard.studyState = state
                                    try? flashcard.lecture?.studyClass?.modelContext?.save()
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        // TODO: Add confirmation
                        flashcard.lecture?.studyClass?.modelContext?.delete(flashcard)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            }
        }
        .sheet(isPresented: $showingEditFlashcard) {
            EditFlashcardView(flashcard: flashcard)
        }
    }
}

// MARK: - Add Flashcard View
struct AddFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let lecture: Lecture
    
    @State private var question = ""
    @State private var answer = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Flashcard Content") {
                    TextField("Question", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Answer", text: $answer, axis: .vertical)
                        .lineLimit(3...8)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Text("Cards start in Learning state and will appear daily until promoted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFlashcard()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addFlashcard() {
        let flashcard = Flashcard(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
            lecture: lecture
        )
        
        modelContext.insert(flashcard)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Edit Flashcard View
struct EditFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let flashcard: Flashcard
    
    @State private var question: String
    @State private var answer: String
    @State private var studyState: StudyCardState
    
    init(flashcard: Flashcard) {
        self.flashcard = flashcard
        self._question = State(initialValue: flashcard.question)
        self._answer = State(initialValue: flashcard.answer)
        self._studyState = State(initialValue: flashcard.studyState)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Question", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("Answer", text: $answer, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section("Study State") {
                    Picker("State", selection: $studyState) {
                        ForEach(StudyCardState.allCases, id: \.self) { state in
                            HStack {
                                Text(state.emoji)
                                Text(state.displayName)
                            }
                            .tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if flashcard.totalAttempts > 0 {
                    Section("Performance") {
                        HStack {
                            Text("Accuracy")
                            Spacer()
                            Text("\(Int(flashcard.accuracy * 100))%")
                        }
                        
                        HStack {
                            Text("Correct Answers")
                            Spacer()
                            Text("\(flashcard.correctCount)")
                        }
                        
                        HStack {
                            Text("Total Attempts")
                            Spacer()
                            Text("\(flashcard.totalAttempts)")
                        }
                    }
                }
            }
            .navigationTitle("Edit Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        flashcard.question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        flashcard.answer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        flashcard.studyState = studyState
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Bulk Operations View
struct BulkOperationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedCards: [Flashcard]
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Change Study State") {
                    ForEach(StudyCardState.allCases, id: \.self) { state in
                        Button(action: { changeAllCardsTo(state) }) {
                            HStack {
                                Text(state.emoji)
                                Text("Move all to \(state.displayName)")
                                Spacer()
                                Text("\(selectedCards.count) cards")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Reset Progress", role: .destructive) {
                        resetProgress()
                    }
                    
                    Button("Delete Cards", role: .destructive) {
                        deleteCards()
                    }
                }
            }
            .navigationTitle("Edit \(selectedCards.count) Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func changeAllCardsTo(_ state: StudyCardState) {
        for card in selectedCards {
            card.studyState = state
        }
        try? modelContext.save()
        onComplete()
        dismiss()
    }
    
    private func resetProgress() {
        for card in selectedCards {
            card.correctCount = 0
            card.totalAttempts = 0
            card.lastStudied = nil
            card.nextScheduledDate = Date()
            card.studyState = .learning
        }
        try? modelContext.save()
        onComplete()
        dismiss()
    }
    
    private func deleteCards() {
        for card in selectedCards {
            modelContext.delete(card)
        }
        try? modelContext.save()
        onComplete()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        LectureDetailView(lecture: Lecture(title: "Introduction to Neural Networks"))
    }
}