//
//  NotificationManager.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import Foundation
import UserNotifications
import SwiftData

/// Manages all notification scheduling, content creation, and deep linking for StudyFlow
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?
    
    // Notification identifiers
    private let studyNotificationIdentifier = "com.studyflow.study-reminder"
    
    private init() {}
    
    // MARK: - Initialization
    func initializeNotificationScheduling(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Clear any existing notifications and reschedule
        clearAllNotifications()
        scheduleNextNotifications()
    }
    
    // MARK: - Notification Scheduling
    func scheduleNextNotifications() {
        guard let modelContext = modelContext else {
            print("NotificationManager: ModelContext not available")
            return
        }
        
        // Get user preferences (for now, use defaults)
        let preferences = getNotificationPreferences()
        
        // Get cards available for notifications
        let availableCards = getCardsForNotifications(modelContext: modelContext)
        
        guard !availableCards.isEmpty else {
            print("NotificationManager: No cards available for notifications")
            return
        }
        
        // Schedule notifications based on preferences
        scheduleNotificationsForToday(cards: availableCards, preferences: preferences)
    }
    
    private func scheduleNotificationsForToday(cards: [Flashcard], preferences: NotificationPreferences) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate notification times for today
        let notificationTimes = calculateNotificationTimes(preferences: preferences, from: now)
        
        for (index, notificationTime) in notificationTimes.enumerated() {
            // Skip times that have already passed
            guard notificationTime > now else { continue }
            
            // Select cards for this notification
            let batchSize = calculateBatchSize(for: cards.count, preferences: preferences)
            let cardsForNotification = selectCardsForNotification(
                from: cards, 
                batchSize: batchSize, 
                notificationIndex: index
            )
            
            guard !cardsForNotification.isEmpty else { continue }
            
            // Create and schedule notification
            let content = createNotificationContent(for: cardsForNotification, preferences: preferences)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.hour, .minute], from: notificationTime),
                repeats: false
            )
            
            let identifier = "\(studyNotificationIdentifier)-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("NotificationManager: Error scheduling notification: \(error)")
                } else {
                    print("NotificationManager: Scheduled notification for \(notificationTime)")
                }
            }
        }
    }
    
    // MARK: - Card Selection Logic
    private func getCardsForNotifications(modelContext: ModelContext) -> [Flashcard] {
        // Get today's cards using the existing spaced repetition engine
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                card.isActive
            }
        )
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            return SpacedRepetitionEngine.getTodaysCards(from: allCards, maxLimit: 50)
        } catch {
            print("NotificationManager: Error fetching cards: \(error)")
            return []
        }
    }
    
    private func selectCardsForNotification(from cards: [Flashcard], batchSize: Int, notificationIndex: Int) -> [Flashcard] {
        // Rotate through cards to ensure variety across notifications
        let startIndex = (notificationIndex * batchSize) % cards.count
        let endIndex = min(startIndex + batchSize, cards.count)
        
        if endIndex <= cards.count {
            return Array(cards[startIndex..<endIndex])
        } else {
            // Wrap around if needed
            let firstPart = Array(cards[startIndex..<cards.count])
            let secondPart = Array(cards[0..<(batchSize - firstPart.count)])
            return firstPart + secondPart
        }
    }
    
    // MARK: - Notification Content Creation
    private func createNotificationContent(for cards: [Flashcard], preferences: NotificationPreferences) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        if cards.count == 1 {
            let card = cards[0]
            content.title = "Study Time! 📚"
            content.body = card.question
            content.subtitle = card.lecture?.studyClass?.name ?? "StudyFlow"
        } else {
            content.title = "Study Time! 📚"
            content.body = "\(cards.count) cards ready to review"
            
            // Show preview of first card
            if let firstCard = cards.first {
                content.subtitle = firstCard.question
            }
        }
        
        content.sound = preferences.soundEnabled ? .default : nil
        content.badge = NSNumber(value: cards.count)
        
        // Add user info for deep linking
        content.userInfo = [
            "cardIDs": cards.map { $0.persistentModelID.hashValue.description },
            "notificationType": "study-reminder"
        ]
        
        // Add interactive actions
        content.categoryIdentifier = "STUDY_REMINDER"
        
        return content
    }
    
    // MARK: - Notification Timing Calculation
    private func calculateNotificationTimes(preferences: NotificationPreferences, from startDate: Date) -> [Date] {
        let calendar = Calendar.current
        var notificationTimes: [Date] = []
        
        // Start from the next hour to avoid immediate notifications
        guard let startHour = calendar.date(byAdding: .hour, value: 1, to: startDate) else {
            return []
        }
        
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startDate
        
        var currentTime = startHour
        
        while currentTime < endOfDay && notificationTimes.count < preferences.maxNotificationsPerDay {
            let hour = calendar.component(.hour, from: currentTime)
            
            // Check if time is within allowed hours (avoid quiet hours)
            if hour >= preferences.startHour && hour < preferences.endHour {
                notificationTimes.append(currentTime)
            }
            
            // Move to next notification time based on frequency
            currentTime = calendar.date(byAdding: .minute, value: preferences.intervalMinutes, to: currentTime) ?? currentTime
        }
        
        return notificationTimes
    }
    
    private func calculateBatchSize(for totalCards: Int, preferences: NotificationPreferences) -> Int {
        // Use the algorithm from the development guide
        switch totalCards {
        case 0..<20:
            return 1 // Single card notifications
        case 20..<100:
            return min(preferences.maxCardsPerNotification, 3) // Small batches (2-3 cards)
        default:
            return min(preferences.maxCardsPerNotification, 5) // Larger sessions for finals mode
        }
    }
    
    // MARK: - Notification Management
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func clearNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    // MARK: - Preferences
    private func getNotificationPreferences() -> NotificationPreferences {
        // For now, return default preferences
        // TODO: Load from UserDefaults or Settings
        return NotificationPreferences()
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences {
    let isEnabled: Bool
    let intervalMinutes: Int // How often to send notifications
    let maxNotificationsPerDay: Int
    let maxCardsPerNotification: Int
    let startHour: Int // Earliest hour to send notifications (24-hour format)
    let endHour: Int // Latest hour to send notifications (24-hour format)
    let soundEnabled: Bool
    let weekendsEnabled: Bool
    
    init(
        isEnabled: Bool = true,
        intervalMinutes: Int = 90, // Every 1.5 hours by default
        maxNotificationsPerDay: Int = 8,
        maxCardsPerNotification: Int = 3,
        startHour: Int = 9, // 9 AM
        endHour: Int = 21, // 9 PM
        soundEnabled: Bool = true,
        weekendsEnabled: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.intervalMinutes = intervalMinutes
        self.maxNotificationsPerDay = maxNotificationsPerDay
        self.maxCardsPerNotification = maxCardsPerNotification
        self.startHour = startHour
        self.endHour = endHour
        self.soundEnabled = soundEnabled
        self.weekendsEnabled = weekendsEnabled
    }
}
