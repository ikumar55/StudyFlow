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
            
            notificationCenter.add(request) { [weak self] error in
                if let error = error {
                    print("NotificationManager: Error scheduling notification: \(error)")
                } else {
                    print("NotificationManager: Scheduled notification for \(notificationTime)")
                    
                    // Create PendingNotification record on main thread
                    let cardIDs = cardsForNotification.map { $0.persistentModelID.hashValue.description }
                    DispatchQueue.main.async {
                        if let modelContext = self?.modelContext {
                            self?.createPendingNotificationRecord(
                                identifier: identifier,
                                cardIDs: cardIDs,
                                scheduledDate: notificationTime,
                                modelContext: modelContext
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Card Selection Logic
    private func getCardsForNotifications(modelContext: ModelContext) -> [Flashcard] {
        let preferences = getNotificationPreferences()
        
        // Get all active cards
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate<Flashcard> { card in
                card.isActive
            }
        )
        
        do {
            let allCards = try modelContext.fetch(descriptor)
            
            // Apply class filter if specified
            let filteredCards = applyClassFilter(cards: allCards, preferences: preferences)
            
            // Get today's cards with smart prioritization
            return getSmartPrioritizedCards(from: filteredCards, preferences: preferences)
        } catch {
            print("NotificationManager: Error fetching cards: \(error)")
            return []
        }
    }
    
    private func applyClassFilter(cards: [Flashcard], preferences: NotificationPreferences) -> [Flashcard] {
        guard let priorityClassID = preferences.priorityClassID else {
            return cards // No filter applied
        }
        
        return cards.filter { card in
            card.lecture?.studyClass?.persistentModelID.hashValue.description == priorityClassID
        }
    }
    
    private func getSmartPrioritizedCards(from cards: [Flashcard], preferences: NotificationPreferences) -> [Flashcard] {
        // Separate cards by study state
        let learningCards = cards.filter { $0.studyState == .learning }
        let reviewingCards = cards.filter { $0.studyState == .reviewing }
        let masteredCards = cards.filter { $0.studyState == .mastered }
        
        // Calculate how many cards we can fit in today's notification window
        let maxCardsForToday = calculateMaxCardsForToday(preferences: preferences)
        
        // Smart allocation based on priority: Learning > Reviewing > Mastered
        var selectedCards: [Flashcard] = []
        var remainingSlots = maxCardsForToday
        
        // Priority 1: Learning cards (most important)
        let learningAllocation = min(learningCards.count, Int(Double(remainingSlots) * 0.6)) // 60% for learning
        selectedCards.append(contentsOf: Array(learningCards.shuffled().prefix(learningAllocation)))
        remainingSlots -= learningAllocation
        
        // Priority 2: Reviewing cards
        let reviewingAllocation = min(reviewingCards.count, Int(Double(remainingSlots) * 0.7)) // 70% of remaining
        selectedCards.append(contentsOf: Array(reviewingCards.shuffled().prefix(reviewingAllocation)))
        remainingSlots -= reviewingAllocation
        
        // Priority 3: Mastered cards (fill remaining slots)
        let masteredAllocation = min(masteredCards.count, remainingSlots)
        selectedCards.append(contentsOf: Array(masteredCards.shuffled().prefix(masteredAllocation)))
        
        return selectedCards.shuffled() // Shuffle final selection for variety
    }
    
    private func calculateMaxCardsForToday(preferences: NotificationPreferences) -> Int {
        // Calculate total notification slots available today
        let notificationTimes = calculateNotificationTimes(preferences: preferences, from: Date())
        let totalSlots = notificationTimes.count * preferences.maxCardsPerNotification
        
        return totalSlots
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
            let firstCard = cards[0]
            content.title = "Study Time! 📚"
            content.body = "Card 1 of \(cards.count): \(firstCard.question)"
            content.subtitle = firstCard.lecture?.studyClass?.name ?? "StudyFlow"
        }
        
        content.sound = preferences.soundEnabled ? .default : nil
        content.badge = NSNumber(value: cards.count)
        
        // Add user info for deep linking
        content.userInfo = [
            "cardIDs": cards.map { $0.persistentModelID.hashValue.description },
            "notificationType": "study-reminder",
            "totalCards": cards.count,
            "currentCard": 1
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
    
    private func createPendingNotificationRecord(
        identifier: String,
        cardIDs: [String],
        scheduledDate: Date,
        modelContext: ModelContext
    ) {
        let pendingNotification = PendingNotification(
            notificationID: identifier,
            cardIDs: cardIDs,
            scheduledDate: scheduledDate
        )
        
        modelContext.insert(pendingNotification)
        
        do {
            try modelContext.save()
        } catch {
            print("NotificationManager: Error saving pending notification: \(error)")
        }
    }
    
    // MARK: - Notification Status Updates
    func markNotificationAsSent(identifier: String, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PendingNotification>(
            predicate: #Predicate<PendingNotification> { notification in
                notification.notificationID == identifier
            }
        )
        
        do {
            let notifications = try modelContext.fetch(descriptor)
            if let notification = notifications.first {
                notification.sentDate = Date()
                try modelContext.save()
            }
        } catch {
            print("NotificationManager: Error updating notification status: \(error)")
        }
    }
    
    func markNotificationAsCompleted(cardIDs: [String], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PendingNotification>()
        
        do {
            let notifications = try modelContext.fetch(descriptor)
            let matchingNotifications = notifications.filter { notification in
                Set(notification.cardIDs) == Set(cardIDs) && notification.completedDate == nil
            }
            
            for notification in matchingNotifications {
                notification.completedDate = Date()
            }
            
            try modelContext.save()
        } catch {
            print("NotificationManager: Error marking notification as completed: \(error)")
        }
    }
    
    // MARK: - Testing & Debug
    func scheduleTestNotificationWithCards(modelContext: ModelContext) {
        let cards = getCardsForNotifications(modelContext: modelContext)
        guard !cards.isEmpty else {
            print("NotificationManager: No cards available for test notification")
            return
        }
        
        let testCards = Array(cards.prefix(3))
        let preferences = getNotificationPreferences()
        let content = createNotificationContent(for: testCards, preferences: preferences)
        
        // Schedule for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-study-notification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Error scheduling test notification: \(error)")
            } else {
                print("NotificationManager: Test notification scheduled for 5 seconds")
            }
        }
    }
    
    // MARK: - Preferences
    private func getNotificationPreferences() -> NotificationPreferences {
        return NotificationPreferencesManager.shared.preferences
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
    let allowCardRepetition: Bool // Whether same card can appear multiple times per day
    let priorityClassID: String? // ID of class to prioritize (nil = all classes)
    
    init(
        isEnabled: Bool = true,
        intervalMinutes: Int = 90, // Every 1.5 hours by default
        maxNotificationsPerDay: Int = 8,
        maxCardsPerNotification: Int = 3,
        startHour: Int = 9, // 9 AM
        endHour: Int = 21, // 9 PM
        soundEnabled: Bool = true,
        weekendsEnabled: Bool = true,
        allowCardRepetition: Bool = true,
        priorityClassID: String? = nil
    ) {
        self.isEnabled = isEnabled
        self.intervalMinutes = intervalMinutes
        self.maxNotificationsPerDay = maxNotificationsPerDay
        self.maxCardsPerNotification = maxCardsPerNotification
        self.startHour = startHour
        self.endHour = endHour
        self.soundEnabled = soundEnabled
        self.weekendsEnabled = weekendsEnabled
        self.allowCardRepetition = allowCardRepetition
        self.priorityClassID = priorityClassID
    }
}
