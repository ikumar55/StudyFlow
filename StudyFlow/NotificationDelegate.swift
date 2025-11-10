//
//  NotificationDelegate.swift
//  StudyFlow
//
//  Created by Assistant on 11/10/25.
//

import Foundation
import UserNotifications
import SwiftUI

/// Handles notification interactions and deep linking
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    @Published var pendingNotificationAction: NotificationAction?
    
    private override init() {
        super.init()
        setupNotificationActions()
    }
    
    // MARK: - Notification Actions Setup
    private func setupNotificationActions() {
        let studyNowAction = UNNotificationAction(
            identifier: "STUDY_NOW",
            title: "Study Now",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 15 min",
            options: []
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: []
        )
        
        let studyCategory = UNNotificationCategory(
            identifier: "STUDY_REMINDER",
            actions: [studyNowAction, remindLaterAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([studyCategory])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let cardIDs = userInfo["cardIDs"] as? [String],
              let notificationType = userInfo["notificationType"] as? String,
              notificationType == "study-reminder" else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "STUDY_NOW", UNNotificationDefaultActionIdentifier:
            // User tapped notification or "Study Now" - launch study session
            DispatchQueue.main.async {
                self.pendingNotificationAction = NotificationAction.studyCards(cardIDs: cardIDs)
            }
            
        case "REMIND_LATER":
            // Reschedule notification for 15 minutes later
            scheduleReminderNotification(for: cardIDs, delay: 15)
            
        case "SKIP":
            // User skipped - do nothing, just mark as handled
            print("NotificationDelegate: User skipped notification")
            
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Reminder Scheduling
    private func scheduleReminderNotification(for cardIDs: [String], delay: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Study Reminder 📚"
        content.body = "Ready to study those \(cardIDs.count) cards?"
        content.sound = .default
        content.categoryIdentifier = "STUDY_REMINDER"
        content.userInfo = [
            "cardIDs": cardIDs,
            "notificationType": "study-reminder"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delay * 60), repeats: false)
        let identifier = "reminder-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationDelegate: Error scheduling reminder: \(error)")
            } else {
                print("NotificationDelegate: Scheduled reminder for \(delay) minutes")
            }
        }
    }
    
    // MARK: - Action Processing
    func processNotificationAction() -> NotificationAction? {
        let action = pendingNotificationAction
        pendingNotificationAction = nil
        return action
    }
}

// MARK: - Notification Action Types
enum NotificationAction {
    case studyCards(cardIDs: [String])
}
