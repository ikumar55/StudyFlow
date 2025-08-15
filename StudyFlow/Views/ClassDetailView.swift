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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: studyClass.colorCode) ?? .blue)
                    .frame(width: 12, height: 12)
                
                Text(studyClass.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Statistics
            VStack(spacing: 8) {
                HStack {
                    StatPill(title: "Total Cards", value: "\(studyClass.totalFlashcards)", color: .blue)
                    StatPill(title: "Active", value: "\(studyClass.activeFlashcards)", color: .green)
                    Spacer()
                }
                
                HStack {
                    StatPill(title: "Learning", value: "\(studyClass.learningCards)", color: .orange)
                    StatPill(title: "Reviewing", value: "\(studyClass.reviewingCards)", color: .yellow)
                    StatPill(title: "Mastered", value: "\(studyClass.masteredCards)", color: .green)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            
            // Study state breakdown for this lecture
            if lecture.flashcardCount > 0 {
                HStack(spacing: 8) {
                    let learningCount = lecture.flashcards.filter { $0.studyState == .learning && $0.isActive }.count
                    let reviewingCount = lecture.flashcards.filter { $0.studyState == .reviewing && $0.isActive }.count
                    let masteredCount = lecture.flashcards.filter { $0.studyState == .mastered && $0.isActive }.count
                    
                    if learningCount > 0 {
                        StudyStateBadge(state: .learning, count: learningCount)
                    }
                    if reviewingCount > 0 {
                        StudyStateBadge(state: .reviewing, count: reviewingCount)
                    }
                    if masteredCount > 0 {
                        StudyStateBadge(state: .mastered, count: masteredCount)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Views
struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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