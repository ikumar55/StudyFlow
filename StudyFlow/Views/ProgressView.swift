//
//  ProgressView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFlashcards: [Flashcard]
    @Query private var studySessions: [StudySession]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Today's stats
                    todayStatsSection
                    
                    // Study state breakdown
                    studyStateSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
    
    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(title: "Cards Studied", value: "\(todayCompletedCards)", color: .blue)
                StatCard(title: "Accuracy", value: "\(Int(todayAccuracy * 100))%", color: .green)
                StatCard(title: "Study Time", value: "\(Int(todayStudyTime))m", color: .orange)
            }
        }
    }
    
    private var studyStateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study States")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StudyStateRow(state: .learning, count: learningCount, total: totalActive)
                StudyStateRow(state: .reviewing, count: reviewingCount, total: totalActive)
                StudyStateRow(state: .mastered, count: masteredCount, total: totalActive)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.semibold)
            
            if recentSessions.isEmpty {
                Text("No recent study sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentSessions.prefix(5), id: \.startDate) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalActive: Int {
        allFlashcards.filter(\.isActive).count
    }
    
    private var learningCount: Int {
        allFlashcards.filter { $0.isActive && $0.studyState == .learning }.count
    }
    
    private var reviewingCount: Int {
        allFlashcards.filter { $0.isActive && $0.studyState == .reviewing }.count
    }
    
    private var masteredCount: Int {
        allFlashcards.filter { $0.isActive && $0.studyState == .mastered }.count
    }
    
    private var todayCompletedCards: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allFlashcards.filter { card in
            guard let lastStudied = card.lastStudied else { return false }
            return Calendar.current.isDate(lastStudied, inSameDayAs: today)
        }.count
    }
    
    private var todayAccuracy: Double {
        let todaySessions = studySessions.filter { session in
            Calendar.current.isDateInToday(session.startDate)
        }
        
        guard !todaySessions.isEmpty else { return 0 }
        
        let totalCards = todaySessions.reduce(0) { $0 + $1.totalCards }
        let totalCorrect = todaySessions.reduce(0) { $0 + $1.correctAnswers }
        
        return totalCards > 0 ? Double(totalCorrect) / Double(totalCards) : 0
    }
    
    private var todayStudyTime: TimeInterval {
        let todaySessions = studySessions.filter { session in
            Calendar.current.isDateInToday(session.startDate) && session.isCompleted
        }
        
        return todaySessions.reduce(0) { $0 + $1.duration } / 60 // Convert to minutes
    }
    
    private var recentSessions: [StudySession] {
        studySessions
            .filter(\.isCompleted)
            .sorted { $0.startDate > $1.startDate }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct StudyStateRow: View {
    let state: StudyCardState
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        HStack {
            Text(state.emoji)
            
            Text(state.displayName)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("(\(Int(percentage * 100))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SessionRow: View {
    let session: StudySession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionType.displayName)
                    .font(.subheadline)
                
                Text(session.startDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.correctAnswers)/\(session.totalCards)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(session.accuracy >= 0.8 ? .green : session.accuracy >= 0.6 ? .orange : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProgressDashboardView()
}