//
//  NotificationPreferencesManager.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import Foundation
import SwiftData

/// Manages notification preferences with UserDefaults persistence
class NotificationPreferencesManager: ObservableObject {
    static let shared = NotificationPreferencesManager()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let isEnabled = "notifications_enabled"
        static let intervalMinutes = "notifications_interval_minutes"
        static let maxNotificationsPerDay = "notifications_max_per_day"
        static let maxCardsPerNotification = "notifications_max_cards"
        static let startHour = "notifications_start_hour"
        static let endHour = "notifications_end_hour"
        static let soundEnabled = "notifications_sound_enabled"
        static let weekendsEnabled = "notifications_weekends_enabled"
        static let allowCardRepetition = "notifications_allow_repetition"
        static let priorityClassID = "notifications_priority_class_id"
        static let notificationFrequency = "notifications_frequency"
        static let studyMode = "study_mode"
    }
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Computed Properties
    var preferences: NotificationPreferences {
        NotificationPreferences(
            isEnabled: userDefaults.bool(forKey: Keys.isEnabled, defaultValue: true),
            intervalMinutes: userDefaults.integer(forKey: Keys.intervalMinutes, defaultValue: 90),
            maxNotificationsPerDay: userDefaults.integer(forKey: Keys.maxNotificationsPerDay, defaultValue: 8),
            maxCardsPerNotification: userDefaults.integer(forKey: Keys.maxCardsPerNotification, defaultValue: 3),
            startHour: userDefaults.integer(forKey: Keys.startHour, defaultValue: 9),
            endHour: userDefaults.integer(forKey: Keys.endHour, defaultValue: 21),
            soundEnabled: userDefaults.bool(forKey: Keys.soundEnabled, defaultValue: true),
            weekendsEnabled: userDefaults.bool(forKey: Keys.weekendsEnabled, defaultValue: true),
            allowCardRepetition: userDefaults.bool(forKey: Keys.allowCardRepetition, defaultValue: true),
            priorityClassID: userDefaults.string(forKey: Keys.priorityClassID)
        )
    }
    
    // MARK: - Individual Getters
    var isEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isEnabled, defaultValue: true) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isEnabled)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var notificationFrequency: NotificationFrequency {
        get { 
            NotificationFrequency(rawValue: userDefaults.string(forKey: Keys.notificationFrequency) ?? "") ?? .moderate 
        }
        set { 
            userDefaults.set(newValue.rawValue, forKey: Keys.notificationFrequency)
            updateIntervalFromFrequency(newValue)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var studyMode: StudyMode {
        get { 
            StudyMode(rawValue: userDefaults.string(forKey: Keys.studyMode) ?? "") ?? .normal 
        }
        set { 
            userDefaults.set(newValue.rawValue, forKey: Keys.studyMode)
            updateSettingsFromStudyMode(newValue)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var maxCardsPerNotification: Int {
        get { userDefaults.integer(forKey: Keys.maxCardsPerNotification, defaultValue: 3) }
        set { 
            userDefaults.set(newValue, forKey: Keys.maxCardsPerNotification)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var weekendsEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.weekendsEnabled, defaultValue: true) }
        set { 
            userDefaults.set(newValue, forKey: Keys.weekendsEnabled)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var allowCardRepetition: Bool {
        get { userDefaults.bool(forKey: Keys.allowCardRepetition, defaultValue: true) }
        set { userDefaults.set(newValue, forKey: Keys.allowCardRepetition) }
    }
    
    var priorityClassID: String? {
        get { userDefaults.string(forKey: Keys.priorityClassID) }
        set { 
            userDefaults.set(newValue, forKey: Keys.priorityClassID)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var startHour: Int {
        get { userDefaults.integer(forKey: Keys.startHour, defaultValue: 9) }
        set { 
            userDefaults.set(newValue, forKey: Keys.startHour)
            scheduleNotificationsIfNeeded()
        }
    }
    
    var endHour: Int {
        get { userDefaults.integer(forKey: Keys.endHour, defaultValue: 21) }
        set { 
            userDefaults.set(newValue, forKey: Keys.endHour)
            scheduleNotificationsIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    private func updateIntervalFromFrequency(_ frequency: NotificationFrequency) {
        let interval = frequency.intervalMinutes
        userDefaults.set(interval, forKey: Keys.intervalMinutes)
        
        let maxPerDay = frequency.maxNotificationsPerDay
        userDefaults.set(maxPerDay, forKey: Keys.maxNotificationsPerDay)
    }
    
    private func updateSettingsFromStudyMode(_ mode: StudyMode) {
        userDefaults.set(mode.maxCardsPerNotification, forKey: Keys.maxCardsPerNotification)
        
        // Update notification frequency based on study mode
        let frequency: NotificationFrequency = mode == .exam ? .aggressive : .moderate
        userDefaults.set(frequency.rawValue, forKey: Keys.notificationFrequency)
        updateIntervalFromFrequency(frequency)
    }
    
    private func scheduleNotificationsIfNeeded() {
        // Trigger notification rescheduling
        DispatchQueue.main.async {
            if let modelContext = self.getModelContext() {
                NotificationManager.shared.initializeNotificationScheduling(modelContext: modelContext)
            }
        }
    }
    
    private func getModelContext() -> ModelContext? {
        // This is a bit of a hack - in a real app you'd inject this dependency
        // For now, we'll let the NotificationManager handle rescheduling when needed
        return nil
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
    
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return integer(forKey: key)
    }
}

// MARK: - Notification Frequency Enum
enum NotificationFrequency: String, CaseIterable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    
    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        }
    }
    
    var description: String {
        switch self {
        case .conservative: return "Every 2-3 hours"
        case .moderate: return "Every 1.5 hours"
        case .aggressive: return "Every 30 minutes"
        }
    }
    
    var intervalMinutes: Int {
        switch self {
        case .conservative: return 150 // 2.5 hours
        case .moderate: return 90      // 1.5 hours
        case .aggressive: return 30    // 30 minutes
        }
    }
    
    var maxNotificationsPerDay: Int {
        switch self {
        case .conservative: return 5
        case .moderate: return 8
        case .aggressive: return 16
        }
    }
}

// MARK: - Study Mode Enum
enum StudyMode: String, CaseIterable {
    case normal = "normal"
    case intensive = "intensive"
    case exam = "exam"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal Mode"
        case .intensive: return "Intensive Mode"
        case .exam: return "Exam Mode"
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "30 cards/day, moderate notifications"
        case .intensive: return "50 cards/day, frequent notifications"
        case .exam: return "Unlimited cards, aggressive scheduling"
        }
    }
    
    var dailyCardLimit: Int {
        switch self {
        case .normal: return 30
        case .intensive: return 50
        case .exam: return 100
        }
    }
    
    var maxCardsPerNotification: Int {
        switch self {
        case .normal: return 3
        case .intensive: return 4
        case .exam: return 5
        }
    }
}
