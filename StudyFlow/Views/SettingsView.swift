//
//  SettingsView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("dailyCardLimit") private var dailyCardLimit: Int = 30
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("quietHoursStart") private var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 23)) ?? Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
    @State private var showingResetConfirmation = false
    @State private var showingResetSuccess = false
    
    var body: some View {
        NavigationStack {
            List {
                // Study Configuration
                Section("Study Settings") {
                    HStack {
                        Text("Daily Card Limit")
                        Spacer()
                        Picker("Daily Limit", selection: $dailyCardLimit) {
                            Text("20").tag(20)
                            Text("30").tag(30)
                            Text("40").tag(40)
                            Text("50").tag(50)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    NavigationLink("Study Modes") {
                        StudyModesSettingsView()
                    }
                }
                
                // Notification Settings
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    
                    if enableNotifications {
                        HStack {
                            Text("Quiet Hours Start")
                            Spacer()
                            DatePicker("", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Quiet Hours End")
                            Spacer()
                            DatePicker("", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        NavigationLink("Advanced Notification Settings") {
                            NotificationSettingsView()
                        }
                    }
                }
                
                // Data Management
                Section("Data") {
                    Button("Export Study Data") {
                        // TODO: Implement export
                    }
                    
                    Button("Import Study Data") {
                        // TODO: Implement import
                    }
                    
                    Button("Reset All Data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your classes, lectures, flashcards, and study progress. This action cannot be undone.")
            }
            .alert("Data Reset Complete", isPresented: $showingResetSuccess) {
                Button("Generate Sample Data") {
                    generateSampleData()
                }
                Button("Start Fresh", role: .cancel) { }
            } message: {
                Text("All data has been cleared. Would you like to generate sample data to get started?")
            }
        }
    }
    
    // MARK: - Data Management Functions
    
    private func resetAllData() {
        do {
            // Delete all study sessions
            let sessionDescriptor = FetchDescriptor<StudySession>()
            let sessions = try modelContext.fetch(sessionDescriptor)
            for session in sessions {
                modelContext.delete(session)
            }
            
            // Delete all flashcards
            let flashcardDescriptor = FetchDescriptor<Flashcard>()
            let flashcards = try modelContext.fetch(flashcardDescriptor)
            for flashcard in flashcards {
                modelContext.delete(flashcard)
            }
            
            // Delete all lectures
            let lectureDescriptor = FetchDescriptor<Lecture>()
            let lectures = try modelContext.fetch(lectureDescriptor)
            for lecture in lectures {
                modelContext.delete(lecture)
            }
            
            // Delete all classes
            let classDescriptor = FetchDescriptor<StudyClass>()
            let classes = try modelContext.fetch(classDescriptor)
            for studyClass in classes {
                modelContext.delete(studyClass)
            }
            
            // Save changes
            try modelContext.save()
            
            // Show success dialog
            showingResetSuccess = true
            
            // Haptic feedback
            HapticFeedback.success()
            
        } catch {
            print("Error resetting data: \(error)")
            // Could show an error alert here
        }
    }
    
    private func generateSampleData() {
        SampleDataGenerator.createSampleData(modelContext: modelContext)
        HapticFeedback.success()
    }
}

struct StudyModesSettingsView: View {
    var body: some View {
        List {
            Section("Study Intensity") {
                SettingRow(
                    title: "Normal Mode",
                    description: "30 cards/day, hourly notifications",
                    isSelected: true
                )
                
                SettingRow(
                    title: "Intensive Mode",
                    description: "50 cards/day, 30-minute intervals",
                    isSelected: false
                )
                
                SettingRow(
                    title: "Exam Mode",
                    description: "Unlimited cards, aggressive scheduling",
                    isSelected: false
                )
            }
            
            Section("Session Preferences") {
                Toggle("Allow Weekend Notifications", isOn: .constant(true))
                Toggle("Smart Timing (Learn Usage Patterns)", isOn: .constant(true))
            }
        }
        .navigationTitle("Study Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        List {
            Section("Frequency") {
                SettingRow(
                    title: "Conservative",
                    description: "Every 2-3 hours",
                    isSelected: false
                )
                
                SettingRow(
                    title: "Moderate",
                    description: "Every hour",
                    isSelected: true
                )
                
                SettingRow(
                    title: "Aggressive",
                    description: "Every 30 minutes",
                    isSelected: false
                )
            }
            
            Section("Content") {
                Toggle("Show Question Previews", isOn: .constant(true))
                Toggle("Include Study Statistics", isOn: .constant(true))
                Toggle("Motivational Messages", isOn: .constant(true))
            }
            
            Section("Integration") {
                Toggle("Respect Focus Modes", isOn: .constant(true))
                Toggle("Adapt to Screen Time", isOn: .constant(false))
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Handle selection
        }
    }
}

#Preview {
    SettingsView()
}