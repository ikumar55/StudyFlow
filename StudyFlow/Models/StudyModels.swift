//
//  StudyModels.swift
//  StudyFlow
//
//  Created by Idhant Kumar on 8/14/25.
//

import Foundation
import SwiftData

// MARK: - Study Card State Enum
enum StudyCardState: String, CaseIterable, Codable {
    case learning = "learning"     // 🟠 Daily appearance
    case reviewing = "reviewing"   // 🟡 Every 2-3 days
    case mastered = "mastered"     // 🟢 Every 6-7 days
    case inactive = "inactive"     // ⚪ Manual only
    
    var emoji: String {
        switch self {
        case .learning: return "🟠"
        case .reviewing: return "🟡"
        case .mastered: return "🟢"
        case .inactive: return "⚪"
        }
    }
    
    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .reviewing: return "Reviewing"
        case .mastered: return "Mastered"
        case .inactive: return "Inactive"
        }
    }
}

// MARK: - Study Session Type
enum StudySessionType: String, Codable {
    case allCards = "all"
    case learningOnly = "learning"
    case reviewingOnly = "reviewing"
    case custom = "custom"
    case notification = "notification"
    
    var displayName: String {
        switch self {
        case .allCards: return "Study All Cards"
        case .learningOnly: return "Learning Cards Only"
        case .reviewingOnly: return "Review & Mastered"
        case .custom: return "Custom Selection"
        case .notification: return "From Notification"
        }
    }
}

// MARK: - StudyClass Model
@Model
class StudyClass {
    var name: String
    var colorCode: String            // Hex color for visual organization
    var isActive: Bool = true
    var createdDate: Date
    
    @Relationship(deleteRule: .cascade) var lectures: [Lecture] = []
    
    init(name: String, colorCode: String = "#4A90E2") {
        self.name = name
        self.colorCode = colorCode
        self.createdDate = Date()
    }
    
    // Computed properties
    var totalFlashcards: Int {
        lectures.flatMap(\.flashcards).count
    }
    
    var activeFlashcards: Int {
        lectures.flatMap(\.flashcards).filter(\.isActive).count
    }
    
    var learningCards: Int {
        lectures.flatMap(\.flashcards).filter { $0.studyState == .learning && $0.isActive }.count
    }
    
    var reviewingCards: Int {
        lectures.flatMap(\.flashcards).filter { $0.studyState == .reviewing && $0.isActive }.count
    }
    
    var masteredCards: Int {
        lectures.flatMap(\.flashcards).filter { $0.studyState == .mastered && $0.isActive }.count
    }
}

// MARK: - Lecture Model
@Model
class Lecture {
    var title: String
    var lectureDescription: String?
    var createdDate: Date
    
    var studyClass: StudyClass?
    @Relationship(deleteRule: .cascade) var flashcards: [Flashcard] = []
    
    init(title: String, description: String? = nil, studyClass: StudyClass? = nil) {
        self.title = title
        self.lectureDescription = description
        self.createdDate = Date()
        self.studyClass = studyClass
    }
    
    var flashcardCount: Int {
        flashcards.count
    }
    
    var activeFlashcardCount: Int {
        flashcards.filter(\.isActive).count
    }
}

// MARK: - Flashcard Model
@Model
class Flashcard {
    var question: String
    var answer: String
    var studyStateRaw: String = "learning"
    var isActive: Bool = true
    
    // Photo support - using comma-separated strings for SwiftData compatibility
    private var questionPhotosRaw: String = ""
    private var answerPhotosRaw: String = ""
    
    // Computed properties to handle array conversion
    var questionPhotos: [String] {
        get {
            questionPhotosRaw.isEmpty ? [] : questionPhotosRaw.components(separatedBy: ",")
        }
        set {
            questionPhotosRaw = newValue.joined(separator: ",")
        }
    }
    
    var answerPhotos: [String] {
        get {
            answerPhotosRaw.isEmpty ? [] : answerPhotosRaw.components(separatedBy: ",")
        }
        set {
            answerPhotosRaw = newValue.joined(separator: ",")
        }
    }
    
    // Spaced repetition tracking
    var correctCount: Int = 0
    var totalAttempts: Int = 0
    var lastStudied: Date?
    var nextScheduledDate: Date
    var lastPromotionOffered: Date?
    
    // Performance metrics
    var averageResponseTime: TimeInterval = 0
    var createdDate: Date
    
    var lecture: Lecture?
    
    init(question: String, answer: String, lecture: Lecture? = nil) {
        self.question = question
        self.answer = answer
        self.createdDate = Date()
        self.nextScheduledDate = Date() // Due today by default
        self.lecture = lecture
    }
    
    // Computed property to access enum
    var studyState: StudyCardState {
        get { StudyCardState(rawValue: studyStateRaw) ?? .learning }
        set { studyStateRaw = newValue.rawValue }
    }
    
    // Computed properties
    var accuracy: Double {
        totalAttempts > 0 ? Double(correctCount) / Double(totalAttempts) : 0
    }
    
    var isOverdue: Bool {
        nextScheduledDate < Date()
    }
    
    var daysSinceLastStudy: Int {
        guard let lastStudied else { return Int.max }
        return Calendar.current.dateComponents([.day], from: lastStudied, to: Date()).day ?? 0
    }
    
    var canBePromoted: Bool {
        correctCount >= 5 && studyState != .mastered
    }
    
    var overdueStatus: OverdueStatus {
        let daysOverdue = daysSinceOverdue
        if daysOverdue <= 0 { return .notOverdue }
        if daysOverdue == 1 { return .overdue1Day }
        if daysOverdue == 2 { return .overdue2Days }
        if daysOverdue >= 3 { return .overdue3PlusDays }
        return .notOverdue
    }
    
    // Photo management helpers
    var hasQuestionPhotos: Bool {
        !questionPhotos.isEmpty
    }
    
    var hasAnswerPhotos: Bool {
        !answerPhotos.isEmpty
    }
    
    var totalPhotoCount: Int {
        questionPhotos.count + answerPhotos.count
    }
    
    private var daysSinceOverdue: Int {
        let calendar = Calendar.current
        let now = Date()
        guard nextScheduledDate < now else { return 0 }
        return calendar.dateComponents([.day], from: nextScheduledDate, to: now).day ?? 0
    }
}

// MARK: - Overdue Status
enum OverdueStatus {
    case notOverdue
    case overdue1Day
    case overdue2Days
    case overdue3PlusDays
    
    var warningLevel: Int {
        switch self {
        case .notOverdue: return 0
        case .overdue1Day: return 1
        case .overdue2Days: return 2
        case .overdue3PlusDays: return 3
        }
    }
}

// MARK: - Study Session Model
@Model
class StudySession {
    var startDate: Date
    var completedDate: Date?
    var sessionTypeRaw: String
    var totalCards: Int
    var correctAnswers: Int
    
    init(sessionType: StudySessionType, totalCards: Int) {
        self.startDate = Date()
        self.sessionTypeRaw = sessionType.rawValue
        self.totalCards = totalCards
        self.correctAnswers = 0
    }
    
    // Computed property to access enum
    var sessionType: StudySessionType {
        get { StudySessionType(rawValue: sessionTypeRaw) ?? .allCards }
        set { sessionTypeRaw = newValue.rawValue }
    }
    
    var accuracy: Double {
        totalCards > 0 ? Double(correctAnswers) / Double(totalCards) : 0
    }
    
    var duration: TimeInterval {
        guard let completed = completedDate else { return 0 }
        return completed.timeIntervalSince(startDate)
    }
    
    var isCompleted: Bool {
        completedDate != nil
    }
}

// MARK: - Daily Card Completion Model
@Model
class DailyCardCompletion {
    var flashcardID: String // Store flashcard ID to reference
    var completedDate: Date
    var wasCorrect: Bool
    var studyDate: Date // The date this completion belongs to (for daily grouping)
    
    init(flashcardID: String, wasCorrect: Bool, studyDate: Date = Date()) {
        self.flashcardID = flashcardID
        self.wasCorrect = wasCorrect
        self.completedDate = Date()
        self.studyDate = Calendar.current.startOfDay(for: studyDate)
    }
    
    var accuracy: Double {
        wasCorrect ? 1.0 : 0.0
    }
}

// MARK: - Pending Notification Model
@Model
class PendingNotification {
    var notificationID: String
    private var cardIDsRaw: String // Comma-separated card IDs
    var scheduledDate: Date
    
    // Computed property to handle array conversion
    var cardIDs: [String] {
        get {
            cardIDsRaw.isEmpty ? [] : cardIDsRaw.components(separatedBy: ",")
        }
        set {
            cardIDsRaw = newValue.joined(separator: ",")
        }
    }
    var sentDate: Date?
    var completedDate: Date? // When user studied these cards
    var wasSkipped: Bool = false
    var studyDate: Date // The date this notification belongs to (for daily grouping)
    
    init(notificationID: String, cardIDs: [String], scheduledDate: Date, studyDate: Date = Date()) {
        self.notificationID = notificationID
        self.cardIDsRaw = cardIDs.joined(separator: ",")
        self.scheduledDate = scheduledDate
        self.studyDate = Calendar.current.startOfDay(for: studyDate)
    }
    
    var isPending: Bool {
        sentDate != nil && completedDate == nil && !wasSkipped
    }
    
    var isOverdue: Bool {
        guard let sent = sentDate else { return false }
        let calendar = Calendar.current
        return !calendar.isDateInToday(sent) && completedDate == nil && !wasSkipped
    }
}