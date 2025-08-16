//
//  ClassDetailView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct ClassDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let studyClass: StudyClass
    
    @State private var showingAddLecture = false
    @State private var newLectureTitle = ""
    @State private var newLectureDescription = ""
    
    var body: some View {
        List {
            // Class overview section
            Section {
                classOverviewCard
            }
            
            // Lectures section
            Section("Lectures") {
                if studyClass.lectures.isEmpty {
                    emptyLecturesView
                } else {
                    ForEach(studyClass.lectures.sorted { $0.createdDate > $1.createdDate }) { lecture in
                        NavigationLink(destination: LectureDetailView(lecture: lecture)) {
                            LectureRowView(lecture: lecture)
                        }
                    }
                    .onDelete(perform: deleteLectures)
                }
            }
        }
        .navigationTitle(studyClass.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Lecture") {
                    showingAddLecture = true
                }
            }
        }
        .sheet(isPresented: $showingAddLecture) {
            addLectureSheet
        }
    }
    
    // MARK: - Class Overview Card
    private var classOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Class header - clean and simple
            VStack(alignment: .leading, spacing: 8) {
                Text(studyClass.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(studyClass.activeFlashcards) active cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Study progress in a clean horizontal layout
            if studyClass.activeFlashcards > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Study Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 20) {
                        StudyStatItem(emoji: "🟠", label: "Learning", count: studyClass.learningCards)
                        StudyStatItem(emoji: "🟡", label: "Reviewing", count: studyClass.reviewingCards)
                        StudyStatItem(emoji: "🟢", label: "Mastered", count: studyClass.masteredCards)
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State
    private var emptyLecturesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("No lectures yet")
                .font(.headline)
            
            Text("Add your first lecture to start creating flashcards")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Lecture") {
                showingAddLecture = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Add Lecture Sheet
    private var addLectureSheet: some View {
        NavigationStack {
            Form {
                Section("Lecture Details") {
                    TextField("Lecture Title", text: $newLectureTitle)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (Optional)", text: $newLectureDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("New Lecture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetForm()
                        showingAddLecture = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addLecture()
                    }
                    .disabled(newLectureTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addLecture() {
        let lecture = Lecture(
            title: newLectureTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: newLectureDescription.isEmpty ? nil : newLectureDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            studyClass: studyClass
        )
        
        modelContext.insert(lecture)
        try? modelContext.save()
        
        resetForm()
        showingAddLecture = false
    }
    
    private func resetForm() {
        newLectureTitle = ""
        newLectureDescription = ""
    }
    
    private func deleteLectures(offsets: IndexSet) {
        withAnimation {
            let sortedLectures = studyClass.lectures.sorted { $0.createdDate > $1.createdDate }
            for index in offsets {
                modelContext.delete(sortedLectures[index])
            }
        }
    }
}

// MARK: - Lecture Row View
struct LectureRowView: View {
    let lecture: Lecture
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lecture.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(lecture.flashcardCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemFill))
                    .clipShape(Capsule())
            }
            
            if let description = lecture.lectureDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Simple study state breakdown for this lecture
            if lecture.flashcardCount > 0 {
                HStack(spacing: 12) {
                    let learningCount = lecture.flashcards.filter { $0.studyState == .learning && $0.isActive }.count
                    let reviewingCount = lecture.flashcards.filter { $0.studyState == .reviewing && $0.isActive }.count
                    let masteredCount = lecture.flashcards.filter { $0.studyState == .mastered && $0.isActive }.count
                    
                    if learningCount > 0 {
                        Text("🟠 \(learningCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if reviewingCount > 0 {
                        Text("🟡 \(reviewingCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if masteredCount > 0 {
                        Text("🟢 \(masteredCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Views
struct StudyStatItem: View {
    let emoji: String
    let label: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct StudyStateBadge: View {
    let state: StudyCardState
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Text(state.emoji)
                .font(.caption2)
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.systemFill))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ClassDetailView(studyClass: StudyClass(name: "Neural Networks"))
    }
}