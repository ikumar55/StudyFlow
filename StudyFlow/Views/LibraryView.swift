//
//  LibraryView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var studyClasses: [StudyClass]
    
    var body: some View {
        NavigationStack {
            VStack {
                if studyClasses.isEmpty {
                    emptyStateView
                } else {
                    classListView
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Class", action: addSampleClass)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Study Classes")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first class to start adding flashcards")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Class", action: addSampleClass)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var classListView: some View {
        List {
            ForEach(studyClasses) { studyClass in
                NavigationLink(destination: ClassDetailView(studyClass: studyClass)) {
                    ClassRowView(studyClass: studyClass)
                }
            }
            .onDelete(perform: deleteClasses)
        }
    }
    
    private func addSampleClass() {
        // Add a sample class with some sample data
        let sampleClass = StudyClass(name: "Neural Networks", colorCode: "#4A90E2")
        modelContext.insert(sampleClass)
        
        // Add a sample lecture
        let sampleLecture = Lecture(title: "Introduction to Neural Networks", studyClass: sampleClass)
        modelContext.insert(sampleLecture)
        
        // Add sample flashcards
        let questions = [
            ("What is a neural network?", "A computational model inspired by biological neural networks, consisting of interconnected nodes (neurons) that process information."),
            ("What is backpropagation?", "An algorithm for training neural networks by calculating gradients and propagating errors backward through the network."),
            ("What is an activation function?", "A mathematical function that determines the output of a neural network node, introducing non-linearity to the model.")
        ]
        
        for (question, answer) in questions {
            let flashcard = Flashcard(question: question, answer: answer, lecture: sampleLecture)
            modelContext.insert(flashcard)
        }
        
        try? modelContext.save()
    }
    
    private func deleteClasses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(studyClasses[index])
            }
        }
    }
}

struct ClassRowView: View {
    let studyClass: StudyClass
    
    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(Color(hex: studyClass.colorCode) ?? .blue)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(studyClass.name)
                    .font(.headline)
                
                Text("\(studyClass.activeFlashcards) active cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    Label("\(studyClass.learningCards)", systemImage: "circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Label("\(studyClass.reviewingCards)", systemImage: "circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Label("\(studyClass.masteredCards)", systemImage: "circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Helper extension for hex color
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LibraryView()
}