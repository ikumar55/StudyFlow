//
//  SettingsView.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyCardLimit") private var dailyCardLimit: Int = 30
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("quietHoursStart") private var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 23)) ?? Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    
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
                        // TODO: Implement reset with confirmation
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
        }
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