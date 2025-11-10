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
    @StateObject private var preferencesManager = NotificationPreferencesManager.shared
    
    @AppStorage("dailyCardLimit") private var dailyCardLimit: Int = 30
    @State private var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 23)) ?? Date()
    @State private var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
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
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { preferencesManager.isEnabled },
                        set: { preferencesManager.isEnabled = $0 }
                    ))
                    
                    if preferencesManager.isEnabled {
                        HStack {
                            Text("Quiet Hours Start")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { 
                                    Calendar.current.date(from: DateComponents(hour: preferencesManager.startHour)) ?? Date()
                                },
                                set: { date in
                                    let hour = Calendar.current.component(.hour, from: date)
                                    preferencesManager.startHour = hour
                                }
                            ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("Quiet Hours End")
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { 
                                    Calendar.current.date(from: DateComponents(hour: preferencesManager.endHour)) ?? Date()
                                },
                                set: { date in
                                    let hour = Calendar.current.component(.hour, from: date)
                                    preferencesManager.endHour = hour
                                }
                            ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        NavigationLink("Advanced Notification Settings") {
                            NotificationSettingsView(preferencesManager: preferencesManager)
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
    @StateObject private var preferencesManager = NotificationPreferencesManager.shared
    
    var body: some View {
        List {
            Section("Study Intensity") {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    SettingRow(
                        title: mode.displayName,
                        description: mode.description,
                        isSelected: preferencesManager.studyMode == mode,
                        onTap: {
                            preferencesManager.studyMode = mode
                            HapticFeedback.light()
                        }
                    )
                }
            }
            
            Section("Session Preferences") {
                Toggle("Allow Weekend Notifications", isOn: Binding(
                    get: { preferencesManager.weekendsEnabled },
                    set: { preferencesManager.weekendsEnabled = $0 }
                ))
                
                Toggle("Allow Card Repetition", isOn: Binding(
                    get: { preferencesManager.allowCardRepetition },
                    set: { preferencesManager.allowCardRepetition = $0 }
                ))
            }
        }
        .navigationTitle("Study Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var preferencesManager: NotificationPreferencesManager
    @Query private var studyClasses: [StudyClass]
    
    var body: some View {
        List {
            Section("Frequency") {
                ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                    SettingRow(
                        title: frequency.displayName,
                        description: frequency.description,
                        isSelected: preferencesManager.notificationFrequency == frequency,
                        onTap: {
                            preferencesManager.notificationFrequency = frequency
                            HapticFeedback.light()
                        }
                    )
                }
            }
            
            Section("Cards Per Notification") {
                HStack {
                    Text("Max Cards")
                    Spacer()
                    Picker("Max Cards", selection: Binding(
                        get: { preferencesManager.maxCardsPerNotification },
                        set: { preferencesManager.maxCardsPerNotification = $0 }
                    )) {
                        ForEach(1...5, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Priority Class") {
                Button(action: {
                    preferencesManager.priorityClassID = nil
                    HapticFeedback.light()
                }) {
                    HStack {
                        Text("All Classes")
                        Spacer()
                        if preferencesManager.priorityClassID == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                ForEach(studyClasses) { studyClass in
                    Button(action: {
                        let classID = studyClass.persistentModelID.hashValue.description
                        preferencesManager.priorityClassID = classID
                        HapticFeedback.light()
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: studyClass.colorCode) ?? .blue)
                                .frame(width: 12, height: 12)
                            
                            Text(studyClass.name)
                            
                            Spacer()
                            
                            if preferencesManager.priorityClassID == studyClass.persistentModelID.hashValue.description {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section("Test Notifications") {
                Button("Send Test Notification") {
                    sendTestNotification()
                }
                .foregroundColor(.blue)
                
                Button("Test with Study Cards") {
                    testNotificationWithCards()
                }
                .foregroundColor(.green)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "StudyFlow Test 📚"
        content.body = "This is a test notification to verify your settings are working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    HapticFeedback.success()
                } else {
                    HapticFeedback.error()
                }
            }
        }
    }
    
    private func testNotificationWithCards() {
        NotificationManager.shared.scheduleTestNotificationWithCards(modelContext: modelContext)
        HapticFeedback.success()
    }
}

struct SettingRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    init(title: String, description: String, isSelected: Bool, onTap: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
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
            onTap?()
        }
    }
}

#Preview {
    SettingsView()
}