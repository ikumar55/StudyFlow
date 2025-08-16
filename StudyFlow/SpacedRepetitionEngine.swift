//
//  SpacedRepetitionEngine.swift
//  StudyFlow
//
//  Created by Assistant on 8/14/25.
//

import Foundation

/// Advanced spaced repetition algorithm based on SM-2 with StudyFlow customizations
class SpacedRepetitionEngine {
    
    /// Calculate the next review date for a flashcard based on performance
    static func calculateNextReviewDate(
        for card: Flashcard,
        wasCorrect: Bool,
        responseTime: TimeInterval? = nil
    ) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // If answer was wrong, schedule for review soon
        if !wasCorrect {
            return scheduleIncorrectAnswer(card: card, from: now)
        }
        
        // Calculate interval based on study state and performance
        let interval = calculateInterval(for: card, responseTime: responseTime)
        
        return calendar.date(byAdding: .day, value: interval, to: now) ?? now
    }
    
    /// Schedule card after incorrect answer
    private static func scheduleIncorrectAnswer(card: Flashcard, from date: Date) -> Date {
        let calendar = Calendar.current
        
        // Reset consecutive correct count
        card.correctCount = 0
        
        // Schedule based on study state
        switch card.studyState {
        case .learning:
            // Review again in 10 minutes to 4 hours
            let minutes = min(10 + (card.totalAttempts * 5), 240)
            return calendar.date(byAdding: .minute, value: minutes, to: date) ?? date
            
        case .reviewing:
            // Back to learning state, review tomorrow
            card.studyState = .learning
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
            
        case .mastered:
            // Back to reviewing state, review in 2 days
            card.studyState = .reviewing
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
            
        case .inactive:
            // Shouldn't happen, but default to tomorrow
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
    }
    
    /// Calculate interval in days for correct answer
    private static func calculateInterval(for card: Flashcard, responseTime: TimeInterval?) -> Int {
        let baseInterval = getBaseInterval(for: card.studyState)
        let performanceMultiplier = calculatePerformanceMultiplier(for: card, responseTime: responseTime)
        
        let adjustedInterval = Double(baseInterval) * performanceMultiplier
        
        // Apply bounds based on study state
        let bounds = getIntervalBounds(for: card.studyState)
        let clampedInterval = max(bounds.min, min(bounds.max, Int(adjustedInterval.rounded())))
        
        return clampedInterval
    }
    
    /// Get base interval for study state
    private static func getBaseInterval(for state: StudyCardState) -> Int {
        switch state {
        case .learning:
            return 1 // Daily by default
        case .reviewing:
            return 3 // Every 3 days by default
        case .mastered:
            return 7 // Weekly by default
        case .inactive:
            return 1 // Shouldn't be scheduled, but default to daily
        }
    }
    
    /// Calculate performance multiplier based on accuracy and response time
    private static func calculatePerformanceMultiplier(for card: Flashcard, responseTime: TimeInterval?) -> Double {
        var multiplier = 1.0
        
        // Accuracy-based adjustment
        let accuracy = card.accuracy
        if accuracy >= 0.9 {
            multiplier *= 1.5 // Excellent performance - longer intervals
        } else if accuracy >= 0.8 {
            multiplier *= 1.2 // Good performance - slightly longer
        } else if accuracy >= 0.6 {
            multiplier *= 1.0 // Average performance - standard interval
        } else {
            multiplier *= 0.8 // Poor performance - shorter intervals
        }
        
        // Consecutive correct answers boost
        let consecutiveBonus = min(Double(card.correctCount) * 0.1, 0.5)
        multiplier += consecutiveBonus
        
        // Response time adjustment (if provided)
        if let responseTime = responseTime, responseTime > 0 {
            let averageTime = card.averageResponseTime > 0 ? card.averageResponseTime : 5.0
            
            if responseTime < averageTime * 0.7 {
                multiplier *= 1.1 // Quick response - slightly longer interval
            } else if responseTime > averageTime * 1.5 {
                multiplier *= 0.9 // Slow response - slightly shorter interval
            }
        }
        
        return multiplier
    }
    
    /// Get interval bounds for study state
    private static func getIntervalBounds(for state: StudyCardState) -> (min: Int, max: Int) {
        switch state {
        case .learning:
            return (min: 1, max: 3) // 1-3 days
        case .reviewing:
            return (min: 2, max: 14) // 2-14 days
        case .mastered:
            return (min: 7, max: 90) // 1 week to 3 months
        case .inactive:
            return (min: 1, max: 1) // Always 1 day (shouldn't be used)
        }
    }
    
    /// Update card's average response time
    static func updateAverageResponseTime(for card: Flashcard, newResponseTime: TimeInterval) {
        if card.averageResponseTime == 0 {
            card.averageResponseTime = newResponseTime
        } else {
            // Exponential moving average with alpha = 0.3
            card.averageResponseTime = card.averageResponseTime * 0.7 + newResponseTime * 0.3
        }
    }
    
    /// Determine if a card should be promoted to the next study state
    static func shouldOfferPromotion(for card: Flashcard) -> Bool {
        // Must have at least 5 consecutive correct answers
        guard card.correctCount >= 5 else { return false }
        
        // Must have good accuracy (80%+)
        guard card.accuracy >= 0.8 else { return false }
        
        // Don't offer promotion too frequently
        if let lastOffered = card.lastPromotionOffered {
            let daysSinceLastOffer = Calendar.current.dateComponents([.day], from: lastOffered, to: Date()).day ?? 0
            guard daysSinceLastOffer >= 3 else { return false }
        }
        
        // Can't promote beyond mastered
        guard card.studyState != .mastered else { return false }
        
        return true
    }
    
    /// Get the next study state for promotion
    static func getNextStudyState(for currentState: StudyCardState) -> StudyCardState? {
        switch currentState {
        case .learning:
            return .reviewing
        case .reviewing:
            return .mastered
        case .mastered, .inactive:
            return nil
        }
    }
}

// MARK: - Daily Card Selection Logic
extension SpacedRepetitionEngine {
    
    /// Get today's cards with intelligent prioritization
    static func getTodaysCards(
        from allCards: [Flashcard],
        maxLimit: Int = 30,
        prioritizeOverdue: Bool = true
    ) -> [Flashcard] {
        
        let activeCards = allCards.filter { $0.isActive }
        
        // 1. Overdue cards (highest priority)
        let overdueCards = getOverdueCards(from: activeCards, maxDays: 3)
        
        // 2. Cards due today
        let dueToday = getCardsDueToday(from: activeCards)
        
        // 3. Learning cards (appear daily)
        let learningCards = getLearningCards(from: activeCards)
        
        // Combine and prioritize
        var selectedCards: [Flashcard] = []
        
        // Always include overdue (up to half the limit)
        let maxOverdue = min(overdueCards.count, maxLimit / 2)
        selectedCards.append(contentsOf: Array(overdueCards.prefix(maxOverdue)))
        
        // Add due cards
        let remainingSlots = maxLimit - selectedCards.count
        let dueTodayFiltered = dueToday.filter { !selectedCards.contains($0) }
        selectedCards.append(contentsOf: Array(dueTodayFiltered.prefix(remainingSlots)))
        
        // Fill remaining slots with learning cards
        let finalRemainingSlots = maxLimit - selectedCards.count
        if finalRemainingSlots > 0 {
            let learningFiltered = learningCards.filter { !selectedCards.contains($0) }
            let selectedLearning = selectLearningCards(from: learningFiltered, limit: finalRemainingSlots)
            selectedCards.append(contentsOf: selectedLearning)
        }
        
        return selectedCards
    }
    
    private static func getOverdueCards(from cards: [Flashcard], maxDays: Int) -> [Flashcard] {
        let calendar = Calendar.current
        let now = Date()
        
        return cards.filter { card in
            guard card.nextScheduledDate < now else { return false }
            let daysOverdue = calendar.dateComponents([.day], from: card.nextScheduledDate, to: now).day ?? 0
            return daysOverdue <= maxDays
        }
        .sorted { $0.nextScheduledDate < $1.nextScheduledDate }
    }
    
    private static func getCardsDueToday(from cards: [Flashcard]) -> [Flashcard] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return cards.filter { card in
            let cardDate = calendar.startOfDay(for: card.nextScheduledDate)
            return cardDate <= today && card.studyState != .learning
        }
        .sorted { $0.nextScheduledDate < $1.nextScheduledDate }
    }
    
    private static func getLearningCards(from cards: [Flashcard]) -> [Flashcard] {
        return cards.filter { $0.studyState == .learning }
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    private static func selectLearningCards(from cards: [Flashcard], limit: Int) -> [Flashcard] {
        guard cards.count > limit else { return cards }
        
        // Priority order for learning card rotation:
        // 1. Cards not studied in 2+ days
        // 2. Cards with accuracy < 70%
        // 3. Recently added cards (within 7 days)
        // 4. Random selection from remaining
        
        let unseen = cards.filter { $0.daysSinceLastStudy >= 2 }
        let struggling = cards.filter { $0.accuracy < 0.7 }
        let recent = cards.filter { 
            $0.createdDate.timeIntervalSinceNow > -7 * 24 * 3600 
        }
        
        // Combine with priority weighting
        var prioritizedCards: [Flashcard] = []
        prioritizedCards.append(contentsOf: unseen)
        prioritizedCards.append(contentsOf: struggling.filter { !prioritizedCards.contains($0) })
        prioritizedCards.append(contentsOf: recent.filter { !prioritizedCards.contains($0) })
        
        // Fill remaining with random selection
        let remaining = cards.filter { !prioritizedCards.contains($0) }.shuffled()
        prioritizedCards.append(contentsOf: remaining)
        
        return Array(prioritizedCards.prefix(limit))
    }
}
