// //
// //  TodayTabBlueprint.swift
// //  StudyFlow - Today Tab Implementation Blueprint
// //
// //  DETAILED PSEUDOCODE & COMMENTS FOR TODAY TAB REDESIGN
// //  Mix of actual Swift code and detailed pseudocode comments
// //

// import SwiftUI
// import SwiftData

// // MAIN TODAY VIEW STRUCTURE
// struct TodayView: View {
//     // Data queries - get all flashcards and classes from SwiftData
//     @Query private var allFlashcards: [Flashcard]
//     @Query private var allClasses: [StudyClass]
    
//     var body: some View {
//         NavigationView {
//             ScrollView {
//                 VStack(spacing: 20) {
                    
//                     // ═══════════════════════════════════════════════════════
//                     // HEADER SECTION - TOP PRIORITY VISUAL ELEMENT
//                     // ═══════════════════════════════════════════════════════
//                     /*
//                     HEADER DESIGN:
//                     ┌─────────────────────────────────────────┐
//                     │ Friday, January 24                      │  <- Large, prominent date
//                     │                                         │
//                     │ ┌─────────────────────────────────────┐ │
//                     │ │  12 cards ready    |    6m estimated │ │  <- Stats card with blue/green colors
//                     │ │                    |                 │ │
//                     │ │ Ready for today's learning! ✨       │ │  <- Motivational message
//                     │ └─────────────────────────────────────┘ │
//                     └─────────────────────────────────────────┘
//                     */
                    
//                     HeaderSection(
//                         currentDate: formatCurrentDate(), // "Friday, January 24"
//                         totalCards: getTodayCards().count,
//                         estimatedMinutes: calculateEstimatedTime(),
//                         motivationalMessage: getMotivationalMessage()
//                     )
                    
//                     // ═══════════════════════════════════════════════════════
//                     // PRIMARY ACTION BUTTONS - MAIN STUDY ENTRY POINTS
//                     // ═══════════════════════════════════════════════════════
//                     /*
//                     BUTTON DESIGN:
//                     ┌─────────────────────────────────────────┐
//                     │ ▶ Start Study Session              BLUE │  <- Main CTA, full width
//                     └─────────────────────────────────────────┘
//                     ┌─────────────────────────────────────────┐
//                     │ ⏰ Quick Session (5 cards)         GRAY │  <- Secondary option
//                     └─────────────────────────────────────────┘
//                     */
                    
//                     PrimaryActionSection(
//                         hasCards: !getTodayCards().isEmpty,
//                         onFullSession: { startStudySession(with: getTodayCards()) },
//                         onQuickSession: { startQuickSession() }
//                     )
                    
//                     // ═══════════════════════════════════════════════════════
//                     // CARD BUCKETS - PRIORITY-BASED ORGANIZATION
//                     // ═══════════════════════════════════════════════════════
                    
//                     if !getTodayCards().isEmpty {
//                         // Show buckets only if we have cards
//                         CardBucketsSection()
//                     } else {
//                         // Show encouraging empty state
//                         EmptyStateSection()
//                     }
//                 }
//                 .padding(.horizontal, 16)
//             }
//             .navigationTitle("Today")
//             .refreshable { refreshData() }
//         }
//     }
    
//     // COMPUTED PROPERTIES FOR DATA FILTERING
//     private func getTodayCards() -> [Flashcard] {
//         // Return all cards that should appear today:
//         // - Overdue cards (1-3 days max)
//         // - Learning cards due today
//         // - Reviewing cards due today  
//         // - Mastered cards due today
//         return allFlashcards.filter { card in
//             card.isActive && (card.isOverdue || card.nextScheduledDate <= Date())
//         }
//     }
    
//     private func getOverdueCards() -> [Flashcard] {
//         // OVERDUE LOGIC: Cards past their review date but not archived
//         // Max 3 days overdue, then they get archived automatically
//         return getTodayCards().filter { $0.isOverdue && $0.daysSinceOverdue <= 3 }
//     }
    
//     private func getLearningCards() -> [Flashcard] {
//         // LEARNING CARDS: New cards or cards being actively learned
//         // State = .learning, due today, not overdue
//         return getTodayCards().filter { 
//             $0.studyState == .learning && !$0.isOverdue 
//         }
//     }
    
//     private func getReviewingCards() -> [Flashcard] {
//         // REVIEWING CARDS: In spaced repetition cycle
//         // State = .reviewing, due today, not overdue
//         return getTodayCards().filter { 
//             $0.studyState == .reviewing && !$0.isOverdue 
//         }
//     }
    
//     private func getMasteredCards() -> [Flashcard] {
//         // MASTERED CARDS: Maintenance schedule
//         // State = .mastered, due today, not overdue
//         return getTodayCards().filter { 
//             $0.studyState == .mastered && !$0.isOverdue 
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // HEADER SECTION COMPONENT
// // ═══════════════════════════════════════════════════════
// struct HeaderSection: View {
//     let currentDate: String
//     let totalCards: Int
//     let estimatedMinutes: Int
//     let motivationalMessage: String
    
//     var body: some View {
//         VStack(spacing: 12) {
//             // DATE DISPLAY - Left aligned, prominent
//             HStack {
//                 Text(currentDate) // "Friday, January 24"
//                     .font(.title2)
//                     .fontWeight(.semibold)
//                 Spacer()
//             }
            
//             // STATS CARD - Key information at a glance
//             /*
//             STATS CARD LAYOUT:
//             ┌─────────────────────────────────────────┐
//             │ 12          |                     6m    │  <- Large numbers, color coded
//             │ cards ready |                estimated  │  <- Descriptive text
//             │ ────────────────────────────────────── │  <- Divider line
//             │ Ready for today's learning session! ✨  │  <- Motivational message
//             └─────────────────────────────────────────┘
//             */
//             VStack(spacing: 8) {
//                 HStack {
//                     // Cards count - Blue color for engagement
//                     VStack(alignment: .leading) {
//                         Text("\(totalCards)")
//                             .font(.title)
//                             .fontWeight(.bold)
//                             .foregroundColor(.blue)
//                         Text("cards ready")
//                             .font(.caption)
//                             .foregroundColor(.secondary)
//                     }
                    
//                     Spacer()
                    
//                     // Time estimate - Green color for positive association
//                     VStack(alignment: .trailing) {
//                         Text("\(estimatedMinutes)m")
//                             .font(.title2)
//                             .fontWeight(.semibold)
//                             .foregroundColor(.green)
//                         Text("estimated")
//                             .font(.caption)
//                             .foregroundColor(.secondary)
//                     }
//                 }
                
//                 Divider()
                
//                 // Motivational message
//                 HStack {
//                     Text(motivationalMessage)
//                         .font(.subheadline)
//                     Spacer()
//                 }
//             }
//             .padding(16)
//             .background(Color(.systemGray6))
//             .cornerRadius(12)
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // PRIMARY ACTION BUTTONS SECTION
// // ═══════════════════════════════════════════════════════
// struct PrimaryActionSection: View {
//     let hasCards: Bool
//     let onFullSession: () -> Void
//     let onQuickSession: () -> Void
    
//     var body: some View {
//         VStack(spacing: 12) {
//             // MAIN STUDY BUTTON - Primary call to action
//             Button(action: onFullSession) {
//                 HStack {
//                     Image(systemName: "play.circle.fill")
//                         .font(.title2)
//                     Text("Start Study Session")
//                         .font(.headline)
//                         .fontWeight(.semibold)
//                     Spacer()
//                 }
//                 .foregroundColor(.white)
//                 .padding(16)
//                 .background(hasCards ? Color.blue : Color.gray)
//                 .cornerRadius(12)
//             }
//             .disabled(!hasCards)
            
//             // QUICK SESSION BUTTON - Time-constrained option
//             Button(action: onQuickSession) {
//                 HStack {
//                     Image(systemName: "clock")
//                     Text("Quick Session (5 cards)")
//                         .fontWeight(.medium)
//                     Spacer()
//                 }
//                 .foregroundColor(hasCards ? .blue : .gray)
//                 .padding(12)
//                 .background(Color(.systemGray6))
//                 .cornerRadius(10)
//             }
//             .disabled(!hasCards)
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // CARD BUCKETS SECTION - MAIN CONTENT ORGANIZATION
// // ═══════════════════════════════════════════════════════
// struct CardBucketsSection: View {
//     /*
//     BUCKET PRIORITY ORDER & VISUAL HIERARCHY:
    
//     1. OVERDUE BUCKET (🔴 RED - HIGHEST PRIORITY)
//        - Most urgent, attention-grabbing styling
//        - Cards 1-3 days past due date
//        - Warning triangle icon
    
//     2. LEARNING BUCKET (🟠 ORANGE - DAILY PRACTICE)
//        - New cards or cards being learned
//        - Brain icon for learning association
//        - Daily appearance priority
    
//     3. REVIEWING BUCKET (🟡 YELLOW - SPACED REPETITION)
//        - Cards in maintenance cycle
//        - Repeat icon for spaced repetition
//        - Every 2-3 days appearance
    
//     4. MASTERED BUCKET (🟢 GREEN - MAINTENANCE)
//        - Well-learned cards
//        - Checkmark seal icon for mastery
//        - Weekly maintenance schedule
//     */
    
//     var body: some View {
//         VStack(spacing: 16) {
//             // Section header
//             HStack {
//                 Text("Study Priorities")
//                     .font(.title3)
//                     .fontWeight(.semibold)
//                 Spacer()
//             }
            
//             // BUCKETS - Show only non-empty buckets
//             // Each bucket follows same structure but different colors/priorities
            
//             ForEach(BucketType.allCases, id: \.self) { bucketType in
//                 let cards = getCardsForBucket(bucketType)
//                 if !cards.isEmpty {
//                     CardBucketView(
//                         bucketType: bucketType,
//                         cards: cards,
//                         onStudyBucket: { startBucketSession(bucketType) },
//                         onStudyCard: { card in startSingleCardSession(card) }
//                     )
//                 }
//             }
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // INDIVIDUAL BUCKET COMPONENT
// // ═══════════════════════════════════════════════════════
// struct CardBucketView: View {
//     let bucketType: BucketType
//     let cards: [Flashcard]
//     let onStudyBucket: () -> Void
//     let onStudyCard: (Flashcard) -> Void
    
//     /*
//     BUCKET LAYOUT DESIGN:
//     ┌─────────────────────────────────────────────────────┐
//     │ 🔴 Overdue                              5           │  <- Header with icon, title, count
//     │    Cards past their review date        cards       │
//     │                                                     │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │ ● What is the capital of France?           →    │ │  <- Card preview 1
//     │ │   History Class • 89% accuracy                  │ │
//     │ └─────────────────────────────────────────────────┘ │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │ ● How do you conjugate "ser" in Spanish?   →    │ │  <- Card preview 2
//     │ │   Spanish 101 • Overdue                        │ │
//     │ └─────────────────────────────────────────────────┘ │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │ ● Define photosynthesis                    →    │ │  <- Card preview 3
//     │ │   Biology • 76% accuracy                       │ │
//     │ └─────────────────────────────────────────────────┘ │
//     │                                                     │
//     │ + 2 more cards                        View All     │  <- Show more indicator
//     │                                                     │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │         ▶ Study Overdue                         │ │  <- Study bucket button
//     │ └─────────────────────────────────────────────────┘ │
//     └─────────────────────────────────────────────────────┘
//     */
    
//     var body: some View {
//         VStack(spacing: 12) {
//             // BUCKET HEADER
//             HStack {
//                 // Icon with bucket color
//                 Image(systemName: bucketType.iconName)
//                     .foregroundColor(bucketType.color)
//                     .font(.title3)
                
//                 // Title and description
//                 VStack(alignment: .leading, spacing: 2) {
//                     Text(bucketType.title)
//                         .font(.headline)
//                         .fontWeight(.semibold)
//                     Text(bucketType.description)
//                         .font(.caption)
//                         .foregroundColor(.secondary)
//                 }
                
//                 Spacer()
                
//                 // Card count
//                 VStack(alignment: .trailing) {
//                     Text("\(cards.count)")
//                         .font(.title2)
//                         .fontWeight(.bold)
//                         .foregroundColor(bucketType.color)
//                     Text("cards")
//                         .font(.caption)
//                         .foregroundColor(.secondary)
//                 }
//             }
            
//             // CARD PREVIEWS (Show first 3 cards)
//             let previewCards = Array(cards.prefix(3))
//             VStack(spacing: 8) {
//                 ForEach(previewCards, id: \.id) { card in
//                     CardPreviewRow(
//                         card: card,
//                         bucketColor: bucketType.color,
//                         onTap: { onStudyCard(card) }
//                     )
//                 }
                
//                 // "View All" option if more than 3 cards
//                 if cards.count > 3 {
//                     HStack {
//                         Text("+ \(cards.count - 3) more cards")
//                             .font(.caption)
//                             .foregroundColor(.secondary)
//                         Spacer()
//                         Button("View All") {
//                             // PSEUDOCODE: Navigate to full bucket view
//                             // This would show a modal/sheet with all cards in the bucket
//                             // Each card still tappable for individual study
//                         }
//                         .font(.caption)
//                         .foregroundColor(.blue)
//                     }
//                     .padding(.horizontal, 12)
//                 }
//             }
            
//             // STUDY BUCKET BUTTON
//             Button(action: onStudyBucket) {
//                 HStack {
//                     Image(systemName: "play.fill")
//                     Text("Study \(bucketType.title)")
//                         .fontWeight(.medium)
//                     Spacer()
//                 }
//                 .foregroundColor(.white)
//                 .padding(12)
//                 .background(bucketType.color)
//                 .cornerRadius(8)
//             }
//         }
//         .padding(16)
//         .background(Color(.systemBackground))
//         .overlay(
//             RoundedRectangle(cornerRadius: 12)
//                 .stroke(bucketType.color.opacity(0.3), lineWidth: 1)
//         )
//         .cornerRadius(12)
//     }
// }

// // ═══════════════════════════════════════════════════════
// // CARD PREVIEW ROW COMPONENT
// // ═══════════════════════════════════════════════════════
// struct CardPreviewRow: View {
//     let card: Flashcard
//     let bucketColor: Color
//     let onTap: () -> Void
    
//     /*
//     CARD PREVIEW LAYOUT:
//     ┌─────────────────────────────────────────────────────┐
//     │ ● What is the capital of France?               →    │
//     │   History Class • 89% accuracy                      │
//     └─────────────────────────────────────────────────────┘
    
//     ELEMENTS:
//     - Colored dot (● indicates study state/bucket)
//     - Question text (truncated to 2 lines max)
//     - Class name with colored badge
//     - Performance metric (accuracy % or "Not studied")
//     - Overdue indicator if applicable
//     - Chevron arrow indicating tappability
//     */
    
//     var body: some View {
//         Button(action: onTap) {
//             HStack(spacing: 12) {
//                 // Study state indicator dot
//                 Circle()
//                     .fill(bucketColor)
//                     .frame(width: 8, height: 8)
                
//                 VStack(alignment: .leading, spacing: 4) {
//                     // Question text (truncated)
//                     Text(card.question)
//                         .font(.subheadline)
//                         .fontWeight(.medium)
//                         .lineLimit(2)
//                         .multilineTextAlignment(.leading)
                    
//                     // Metadata row
//                     HStack(spacing: 8) {
//                         // Class name badge
//                         Text(getClassName(for: card))
//                             .font(.caption)
//                             .foregroundColor(.blue)
//                             .padding(.horizontal, 6)
//                             .padding(.vertical, 2)
//                             .background(Color.blue.opacity(0.1))
//                             .cornerRadius(4)
                        
//                         // Performance metric
//                         Text(getPerformanceText(for: card))
//                             .font(.caption)
//                             .foregroundColor(.secondary)
                        
//                         // Overdue indicator
//                         if card.isOverdue {
//                             Text("Overdue")
//                                 .font(.caption)
//                                 .foregroundColor(.red)
//                                 .fontWeight(.medium)
//                         }
//                     }
//                 }
                
//                 Spacer()
                
//                 // Tap indicator
//                 Image(systemName: "chevron.right")
//                     .font(.caption)
//                     .foregroundColor(.secondary)
//             }
//             .padding(12)
//             .background(Color(.systemGray6))
//             .cornerRadius(8)
//         }
//         .buttonStyle(PlainButtonStyle())
//     }
    
//     // HELPER FUNCTIONS
//     private func getClassName(for card: Flashcard) -> String {
//         return card.lecture?.studyClass?.name ?? "Unknown Class"
//     }
    
//     private func getPerformanceText(for card: Flashcard) -> String {
//         if card.totalAttempts > 0 {
//             return String(format: "%.0f%% accuracy", card.accuracy * 100)
//         } else {
//             return "Not studied yet"
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // EMPTY STATE COMPONENT
// // ═══════════════════════════════════════════════════════
// struct EmptyStateSection: View {
//     /*
//     EMPTY STATE DESIGN - ENCOURAGING AND ACTIONABLE:
    
//     ┌─────────────────────────────────────────────────────┐
//     │                      ✅                             │  <- Large celebratory icon
//     │                                                     │
//     │                All Caught Up!                      │  <- Positive headline
//     │                                                     │
//     │  You've completed all your scheduled study          │  <- Encouraging message
//     │  sessions for today. Great work maintaining         │
//     │  your study streak!                                 │
//     │                                                     │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │ + Create New Cards                      BLUE    │ │  <- Primary action
//     │ └─────────────────────────────────────────────────┘ │
//     │ ┌─────────────────────────────────────────────────┐ │
//     │ │ 💡 Try Sample Flashcards               GRAY    │ │  <- Secondary action
//     │ └─────────────────────────────────────────────────┘ │
//     └─────────────────────────────────────────────────────┘
//     */
    
//     var body: some View {
//         VStack(spacing: 20) {
//             // Celebration section
//             VStack(spacing: 12) {
//                 Image(systemName: "checkmark.circle.fill")
//                     .font(.system(size: 60))
//                     .foregroundColor(.green)
                
//                 Text("All Caught Up!")
//                     .font(.title2)
//                     .fontWeight(.bold)
                
//                 Text("You've completed all your scheduled study sessions for today. Great work maintaining your study streak!")
//                     .font(.body)
//                     .foregroundColor(.secondary)
//                     .multilineTextAlignment(.center)
//             }
//             .padding(.vertical, 20)
            
//             // Action buttons
//             VStack(spacing: 12) {
//                 // Primary: Create new content
//                 Button(action: {
//                     // PSEUDOCODE: Navigate to card creation
//                     // Could go to Classes tab > Select class > Create cards
//                     // Or open a quick card creation modal
//                 }) {
//                     HStack {
//                         Image(systemName: "plus.circle.fill")
//                         Text("Create New Cards")
//                             .fontWeight(.semibold)
//                     }
//                     .foregroundColor(.white)
//                     .padding(16)
//                     .frame(maxWidth: .infinity)
//                     .background(Color.blue)
//                     .cornerRadius(12)
//                 }
                
//                 // Secondary: Try sample content
//                 Button(action: {
//                     // PSEUDOCODE: Load sample flashcards
//                     // Create a set of demo cards across different subjects
//                     // Add them to the user's library for immediate study
//                 }) {
//                     HStack {
//                         Image(systemName: "lightbulb")
//                         Text("Try Sample Flashcards")
//                             .fontWeight(.medium)
//                     }
//                     .foregroundColor(.blue)
//                     .padding(12)
//                     .frame(maxWidth: .infinity)
//                     .background(Color(.systemGray6))
//                     .cornerRadius(10)
//                 }
//             }
//         }
//         .padding(24)
//         .background(Color(.systemBackground))
//         .cornerRadius(16)
//         .overlay(
//             RoundedRectangle(cornerRadius: 16)
//                 .stroke(Color(.systemGray4), lineWidth: 1)
//         )
//     }
// }

// // ═══════════════════════════════════════════════════════
// // SUPPORTING TYPES AND ENUMS
// // ═══════════════════════════════════════════════════════

// enum BucketType: String, CaseIterable {
//     case overdue = "overdue"
//     case learning = "learning"
//     case reviewing = "reviewing"
//     case mastered = "mastered"
    
//     var title: String {
//         switch self {
//         case .overdue: return "Overdue"
//         case .learning: return "Learning"
//         case .reviewing: return "Reviewing"
//         case .mastered: return "Mastered"
//         }
//     }
    
//     var description: String {
//         switch self {
//         case .overdue: return "Cards past their review date"
//         case .learning: return "New cards and active learning"
//         case .reviewing: return "Cards in spaced repetition"
//         case .mastered: return "Well-learned maintenance cards"
//         }
//     }
    
//     var color: Color {
//         switch self {
//         case .overdue: return .red
//         case .learning: return .orange
//         case .reviewing: return .yellow
//         case .mastered: return .green
//         }
//     }
    
//     var iconName: String {
//         switch self {
//         case .overdue: return "exclamationmark.triangle.fill"
//         case .learning: return "brain"
//         case .reviewing: return "repeat"
//         case .mastered: return "checkmark.seal.fill"
//         }
//     }
// }

// // ═══════════════════════════════════════════════════════
// // PSEUDOCODE FOR KEY FUNCTIONS
// // ═══════════════════════════════════════════════════════

// extension TodayView {
    
//     // NAVIGATION FUNCTIONS - PSEUDOCODE
    
//     private func startStudySession(with cards: [Flashcard]) {
//         /*
//         PSEUDOCODE: Start comprehensive study session
        
//         1. Create StudySession object with:
//            - sessionType: .allCards
//            - totalCards: cards.count
//            - startDate: Date()
        
//         2. Navigate to StudySessionView with:
//            - cards: sorted by priority (overdue first, then by next scheduled date)
//            - showProgress: true
//            - allowSkip: true
        
//         3. Track session metrics:
//            - Cards studied
//            - Correct/incorrect answers
//            - Time per card
//            - Session completion rate
//         */
//     }
    
//     private func startQuickSession() {
//         /*
//         PSEUDOCODE: Start time-limited session
        
//         1. Select 5 cards randomly from available cards:
//            - Prioritize overdue cards (always include if available)
//            - Mix of learning/reviewing for variety
//            - Shuffle for random experience
        
//         2. Create StudySession with sessionType: .custom
        
//         3. Navigate to StudySessionView with quick session flag
//         */
//     }
    
//     private func startBucketSession(_ bucketType: BucketType) {
//         /*
//         PSEUDOCODE: Study specific bucket only
        
//         1. Get all cards for the specific bucket
//         2. Sort by priority within bucket:
//            - Overdue: by days overdue (most overdue first)
//            - Learning: by creation date (oldest first)
//            - Reviewing: by last studied date
//            - Mastered: by next scheduled date
        
//         3. Create focused study session for that bucket type
//         */
//     }
    
//     private func startSingleCardSession(_ card: Flashcard) {
//         /*
//         PSEUDOCODE: Study individual card
        
//         1. Create minimal study session with single card
//         2. Navigate to study view in "single card mode"
//         3. After completion, return to Today tab with updated state
//         4. Refresh buckets to reflect new card state
//         */
//     }
    
//     // DATA HELPER FUNCTIONS - PSEUDOCODE
    
//     private func formatCurrentDate() -> String {
//         /*
//         FORMAT: "EEEE, MMMM d" 
//         EXAMPLES: "Friday, January 24", "Monday, March 15"
//         */
//         let formatter = DateFormatter()
//         formatter.dateFormat = "EEEE, MMMM d"
//         return formatter.string(from: Date())
//     }
    
//     private func calculateEstimatedTime() -> Int {
//         /*
//         ESTIMATION LOGIC:
//         - 30 seconds per card on average
//         - Factor in card difficulty (learning cards take longer)
//         - Cap display at 30 minutes for UI purposes
//         - Round to nearest minute
//         */
//         let totalCards = getTodayCards().count
//         let baseTime = totalCards * 30 // 30 seconds per card
//         let learningBonus = getLearningCards().count * 15 // Extra time for learning cards
//         let totalSeconds = baseTime + learningBonus
//         return min(totalSeconds / 60, 30) // Cap at 30 minutes display
//     }
    
//     private func getMotivationalMessage() -> String {
//         /*
//         DYNAMIC MESSAGING BASED ON STUDY STATE:
        
//         1. No cards: "You're all caught up! 🎉"
//         2. Has overdue: "Let's tackle those overdue cards! 💪"
//         3. Only learning: "Time to learn something new! 📚"
//         4. Mixed cards: "Ready for today's learning session! ✨"
//         5. Many cards: "You've got this! Let's study! 🚀"
//         */
        
//         let todayCards = getTodayCards()
//         let overdueCount = getOverdueCards().count
        
//         if todayCards.isEmpty {
//             return "You're all caught up! 🎉"
//         } else if overdueCount > 0 {
//             return "Let's tackle those overdue cards! 💪"
//         } else if todayCards.count > 20 {
//             return "You've got this! Let's study! 🚀"
//         } else {
//             return "Ready for today's learning session! ✨"
//         }
//     }
    
//     private func refreshData() {
//         /*
//         PSEUDOCODE: Refresh all data and buckets
        
//         1. Re-query SwiftData for latest flashcard states
//         2. Recalculate all bucket contents
//         3. Update motivational message
//         4. Refresh estimated time
//         5. Trigger UI refresh
//         */
//     }
// }

// // ═══════════════════════════════════════════════════════
// // TECHNICAL NOTES FOR IMPLEMENTATION
// // ═══════════════════════════════════════════════════════

// /*
// SWIFTUI PERFORMANCE CONSIDERATIONS:

// 1. Use @Query for reactive data fetching from SwiftData
// 2. Computed properties for filtering should be efficient
// 3. Consider @State for UI-only state (like refresh triggers)
// 4. Use LazyVStack if card lists become very long

// NAVIGATION INTEGRATION:

// 1. Today tab should integrate with existing navigation stack
// 2. Study sessions should return to Today tab after completion
// 3. Card creation should update Today tab state automatically
// 4. Consider using @EnvironmentObject for shared study state

// DATA SYNCHRONIZATION:

// 1. Today tab should reflect real-time changes from other tabs
// 2. SwiftData queries should update automatically
// 3. Consider background refresh for overdue calculations
// 4. Handle edge cases (deleted cards, changed study states)

// ACCESSIBILITY:

// 1. All buttons should have clear accessibility labels
// 2. Card counts should be announced properly
// 3. Color-coding should have text alternatives
// 4. Support Dynamic Type for text scaling

// TESTING SCENARIOS:

// 1. Empty state (no cards)
// 2. Only overdue cards
// 3. Mixed bucket states
// 4. Large numbers of cards (performance)
// 5. Network connectivity issues (if applicable)

// ERROR HANDLING:

// 1. Graceful degradation if data unavailable
// 2. Fallback UI states
// 3. User feedback for failed operations
// 4. Recovery from corrupt study data
// */
