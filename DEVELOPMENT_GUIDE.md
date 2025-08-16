# StudyFlow iOS App - Goal-Based Development Guide

## Project Vision
Transform dead time into productive micro-learning sessions through intelligent spaced repetition flashcards with adaptive notifications.

## Core Philosophy
- **Goals over Implementation**: Focus on what the app achieves, not just how
- **User Value First**: Every feature must solve a real learning problem
- **Iterative Excellence**: Build working features, then enhance
- **Future-Ready**: Architecture that scales from personal use to public release

## Technical Stack Decisions
- **iOS Target**: 17+ (enables latest SwiftUI features)
- **Data Layer**: SwiftData (cleaner code, better SwiftUI integration than Core Data)
- **Architecture**: MVVM with SwiftUI
- **Notification Strategy**: Aggressive personal use (hourly), configurable intensity

---

## UI/Navigation Architecture

### Tab Structure (Final Design)

#### Tab 1: "Today" 📚 - Primary Study Interface
**Purpose**: Immediate, actionable study workspace with intelligent prioritization
**Layout Priority** (top to bottom):
1. **🚨 OVERDUE** - Cards past due date (auto-archived after 3 days to prevent demotivation)
2. **🔔 PENDING NOTIFICATIONS** - Uncompleted notification sessions
3. **🟠 LEARNING TODAY** - Daily drilling cards (aggressive frequency)
4. **🟡 REVIEWING TODAY** - Every 2-3 days rotation
5. **🟢 MASTERED TODAY** - Weekly maintenance (every 6-7 days)
6. **[Study All • X cards • ~Y min]** - Primary action button

#### Tab 2: "Library" 📖 - Content Management
**Purpose**: Hierarchical content organization and bulk operations
**Structure**: Classes → Lectures → Flashcards with visual study state indicators
**Features**: Bulk operations, card state management, content creation/editing

#### Tab 3: "Progress" 📊 - Analytics & Motivation
**Purpose**: Visual feedback loops and learning insights
**Features**: Accuracy trends, streak tracking, achievement system

#### Tab 4: "Settings" ⚙️ - Configuration
**Purpose**: Notification preferences, study intensity, quiet hours
**Features**: Advanced settings for daily card limits (30 default, 50 for finals), notification scheduling

### Study State System

#### Four-Tier Card States:
```swift
enum StudyCardState {
    case learning    // 🟠 Daily appearance, multiple times if <20 total cards
    case reviewing   // 🟡 Every 2-3 days  
    case mastered    // 🟢 Every 6-7 days (maintenance)
    case inactive    // ⚪ Never appears unless manually added
}
```

#### Promotion Rules:
- **Manual Only**: No automatic promotions
- **User Control**: Promote option appears after 5+ correct answers
- **Bulk Operations**: Move entire lectures between states
- **Recommendation System**: Gentle suggestions for optimization

#### Daily Card Distribution:
- **Default Limit**: 30 cards per day (prevents overwhelm)
- **Advanced Setting**: Up to 50 cards (finals mode)
- **Smart Rotation**: If >30 learning cards, rotate based on priority:
  1. Cards not seen in 2+ days
  2. Lower accuracy cards
  3. Recently added cards

---

## Development Phases

### Phase 1: Foundation & Core Study Loop
**Timeline**: Week 1-2  
**Goal**: Create a functional study app that enables the complete Today Tab experience

#### 🎯 Primary Goals

**1. SwiftData Model Foundation** ✅
- **What**: Create StudyClass → Lecture → Flashcard hierarchy with study state system
- **Why**: Enable organized content and intelligent study scheduling
- **Success Metric**: Can create classes with flashcards and assign study states
- **Implementation Strategy**: 
  - ✅ SwiftData models with proper relationships and cascade deletes
  - ✅ Study state enum integration (Learning/Reviewing/Mastered/Inactive)
  - ✅ Computed properties for card counts and next study dates

**2. Today Tab - Core Study Interface** ✅ COMPLETE
- **What**: Implement the prioritized card display with study session flow
- **Why**: Create the primary value - actionable daily study workspace
- **Success Metric**: Complete study sessions with smooth card-to-card flow
- **Implementation Strategy**:
  - ✅ Prioritized card grouping (Overdue → Notifications → Learning → Reviewing → Mastered)
  - ✅ Card presentation with tap-to-flip animation and haptic feedback
  - ✅ Study state promotion options after 5+ correct answers 
  - ✅ Session completion with performance summary

**3. Library Tab - Content Management** ✅ COMPLETE
- **What**: Hierarchical content creation and study state management
- **Why**: Enable rapid flashcard creation and organization
- **Success Metric**: Add 50+ flashcards efficiently with proper state assignments
- **Implementation Strategy**:
  - ✅ Classes → Lectures → Flashcards navigation with visual state indicators
  - ✅ Bulk operations for promoting/demoting card states
  - ✅ Quick-add workflows with smart defaults (new cards start as Learning)
  - ✅ Edit/delete operations with proper relationship handling

**4. Study Session Engine** ✅ COMPLETE
- **What**: Seamless study flow with multiple session modes
- **Why**: Support different study strategies (all cards, learning only, custom selection)
- **Success Metric**: Support 30+ card sessions without performance issues
- **Implementation Strategy**:
  - ✅ Session preview with estimated time and card breakdown
  - ✅ Study mode selection (All Cards, Learning Only, Reviewing Only, Custom)
  - ✅ Progress tracking with real-time accuracy calculation
  - ✅ Proper state persistence across app backgrounding

#### 🔧 Technical Foundations
- ✅ SwiftUI with MVVM architecture and SwiftData
- ✅ Custom color system with subtle tints for study states
- ✅ Gesture handling for card interactions
- ✅ Background-safe data operations

---

### Phase 2: Intelligent Scheduling & Daily Logic
**Timeline**: Week 2-3  
**Goal**: Implement the smart daily card distribution and aggressive spaced repetition system

#### 🎯 Primary Goals

**1. Aggressive Spaced Repetition System**
- **What**: Daily appearance logic based on study states with user-controlled intensity
- **Why**: Maximum learning retention through aggressive but organized repetition
- **Success Metric**: Learning cards appear daily, reviewing every 2-3 days, mastered weekly
- **Implementation Strategy**:
  - Daily card selection algorithm respecting 30/50 card limits
  - Smart rotation for >30 learning cards (prioritize unseen, low accuracy, new)
  - Study state-based scheduling (Learning: daily, Reviewing: 2-3 days, Mastered: 6-7 days)
  - Overdue detection with 3-day archive system

**2. Today Tab Intelligence**
- **What**: Dynamic card prioritization and grouping with visual hierarchy
- **Why**: Create actionable daily workspace that prevents overwhelm
- **Success Metric**: Users can immediately identify what needs attention first
- **Implementation Strategy**:
  - Real-time card categorization and counting
  - Visual priority indicators with color-coded states
  - Estimated session time calculations
  - Pending notification tracking and integration

**3. Advanced Study Session Modes**
- **What**: Seamless session customization without UI clutter
- **Why**: Support different learning scenarios (cramming, maintenance, targeted practice)
- **Success Metric**: Users naturally choose appropriate modes for their needs
- **Implementation Strategy**:
  - Session mode picker with clear descriptions
  - Smart defaults based on current card distribution
  - Mode-specific card filtering and selection
  - Session analytics tied to study modes

**4. Settings & Configuration Foundation**
- **What**: User control over daily limits and notification preferences
- **Why**: Support personal use intensity while preparing for broader configurability
- **Success Metric**: Easy transition between normal (30 cards) and intensive (50 cards) study periods
- **Implementation Strategy**:
  - Advanced settings section with daily card limits
  - Notification scheduling preferences (quiet hours, days off)
  - Study intensity presets (Normal, Intensive, Exam Mode)
  - Weekend/weekday schedule differentiation

#### 🔧 Technical Enhancements
- Background card calculation and caching
- Date-based query optimization for large card sets
- User preference persistence with Settings bundle integration
- Performance monitoring for 50+ card daily sessions

---

### Phase 3: Intelligent Notification System
**Timeline**: Week 3-4  
**Goal**: Create aggressive but respectful notification system that transforms dead time into study time

#### 🎯 Primary Goals

**1. Aggressive Personal Notification Strategy**
- **What**: Hourly study notifications with intelligent card batching
- **Why**: Maximize daily study touchpoints for accelerated learning
- **Success Metric**: 15-20 daily notifications with 80%+ completion rate
- **Implementation Strategy**:
  - Single card notifications when <20 total learning cards
  - 2-3 card batches when 20-100 cards in rotation
  - 5-8 card sessions when >100 cards (finals mode)
  - Minimum 30-minute intervals between notifications

**2. Rich Notification Content & Actions**
- **What**: Actionable notifications with study previews and quick responses
- **Why**: Reduce friction from notification tap to study completion
- **Success Metric**: Sub-2-second tap-to-study flow
- **Implementation Strategy**:
  - Rich content showing question previews or card counts
  - Interactive actions (Study Now, Remind in 5 min, Add to Today, Skip)
  - Deep linking directly to specific card sets
  - Notification queue management for missed sessions

**3. Configurable Scheduling Intelligence**
- **What**: User-controlled notification timing with smart defaults
- **Why**: Respect personal schedules while maintaining learning momentum
- **Success Metric**: Zero complaints about intrusive timing, maintained study frequency
- **Implementation Strategy**:
  - Quiet hours configuration (default: 11 PM - 9 AM)
  - Day-specific scheduling (option to disable weekends)
  - Focus Mode integration (respect Do Not Disturb)
  - Usage pattern learning for optimal timing suggestions

**4. Notification-to-Today Tab Integration**
- **What**: Seamless connection between notifications and Today Tab pending queue
- **Why**: Enable flexible study timing without losing notification value
- **Success Metric**: Users can defer notifications and complete them later without penalty
- **Implementation Strategy**:
  - Pending notification queue visible in Today Tab
  - Visual indicators for notification-originated vs algorithm-selected cards
  - Automatic queue management (remove after completion, expire after 24 hours)
  - Engagement tracking for notification effectiveness

#### 🔧 Technical Requirements
- UserNotifications framework with rich content and actions
- Background notification scheduling with proper permission handling
- Deep linking architecture for direct card access
- Notification analytics and engagement tracking

---

### Phase 4: Progress & Motivation System
**Timeline**: Week 4-5  
**Goal**: Create compelling feedback loops that encourage consistent study habits

#### 🎯 Primary Goals

**1. Visual Progress Dashboard**
- **What**: Beautiful charts and metrics showing learning progress
- **Why**: Provide motivation and insight into learning patterns
- **Success Metric**: User checks progress daily and feels motivated to continue
- **Implementation Strategy**:
  - Swift Charts for accuracy trends and study streaks
  - GitHub-style contribution calendar
  - Card mastery progression visualization

**2. Achievement & Streak System**
- **What**: Recognition for consistency, milestones, and learning achievements
- **Why**: Gamify the learning process to build sustainable habits
- **Success Metric**: 70% of users maintain 7+ day streaks
- **Implementation Strategy**:
  - Streak tracking (daily study, perfect accuracy, etc.)
  - Milestone celebrations (10 cards mastered, 30-day streak)
  - Visual rewards and encouraging messaging

**3. Personalized Insights**
- **What**: AI-driven recommendations for study optimization
- **Why**: Help users understand their learning patterns and improve efficiency
- **Success Metric**: Users act on 50%+ of provided insights
- **Implementation Strategy**:
  - Optimal study time detection
  - Session length recommendations
  - Content difficulty balancing suggestions

#### 🔧 Technical Additions
- Swift Charts integration
- Analytics data processing
- Personalization algorithms
- Achievement system architecture

---

### Phase 5: Polish & Advanced Features
**Timeline**: Week 5-6  
**Goal**: Transform from personal tool to potential public release with professional quality

#### 🎯 Primary Goals

**1. Advanced Study Modes**
- **What**: Specialized study modes for different learning scenarios
- **Why**: Accommodate various learning styles and urgency levels
- **Success Metric**: Users actively choose different modes based on their needs
- **Implementation Strategy**:
  - Cramming mode for exams (higher frequency)
  - Weakness mode (focus on struggling cards)
  - Mixed vs. single-subject sessions

**2. Data Management & Export**
- **What**: Backup, restore, and export capabilities
- **Why**: Protect user investment in content creation
- **Success Metric**: Users feel confident their data is safe
- **Implementation Strategy**:
  - JSON export/import
  - Automatic local backups
  - Data integrity validation

**3. Accessibility & Polish**
- **What**: Professional-grade accessibility and user experience
- **Why**: Prepare for broader audience and inclusive design
- **Success Metric**: App passes accessibility audit and feels production-ready
- **Implementation Strategy**:
  - VoiceOver optimization
  - Dynamic Type support
  - High contrast and motor accessibility
  - Comprehensive error handling

#### 🔧 Quality Assurance
- Comprehensive testing suite
- Performance optimization
- Memory leak prevention
- App Store preparation

---

## Data Architecture (SwiftData Models)

### Core Entity Relationships
```swift
@Model class StudyClass {
    var name: String
    var colorCode: String            // Hex color for visual organization
    var isActive: Bool = true
    var createdDate: Date
    @Relationship(deleteRule: .cascade) var lectures: [Lecture] = []
    
    // Computed properties
    var totalFlashcards: Int { lectures.flatMap(\.flashcards).count }
    var activeFlashcards: Int { lectures.flatMap(\.flashcards).filter(\.isActive).count }
}

@Model class Lecture {
    var title: String
    var description: String?
    var createdDate: Date
    var studyClass: StudyClass?
    @Relationship(deleteRule: .cascade) var flashcards: [Flashcard] = []
    
    var flashcardCount: Int { flashcards.count }
}

@Model class Flashcard {
    var question: String
    var answer: String
    var studyState: StudyCardState = .learning
    var isActive: Bool = true
    
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
}

enum StudyCardState: String, CaseIterable, Codable {
    case learning = "learning"     // 🟠 Daily appearance
    case reviewing = "reviewing"   // 🟡 Every 2-3 days
    case mastered = "mastered"     // 🟢 Every 6-7 days
    case inactive = "inactive"     // ⚪ Manual only
}
```

### Study Session Tracking
```swift
@Model class StudySession {
    var startDate: Date
    var completedDate: Date?
    var sessionType: StudySessionType
    var totalCards: Int
    var correctAnswers: Int
    var cardResults: [CardResult] = []
    
    var accuracy: Double { 
        totalCards > 0 ? Double(correctAnswers) / Double(totalCards) : 0 
    }
    var duration: TimeInterval {
        guard let completed = completedDate else { return 0 }
        return completed.timeIntervalSince(startDate)
    }
}

enum StudySessionType: String, Codable {
    case allCards = "all"
    case learningOnly = "learning"
    case reviewingOnly = "reviewing"
    case custom = "custom"
    case notification = "notification"
}
```

## Visual Design System

### Color Palette (Subtle Tints)
```swift
extension Color {
    static let learningTint = Color(hex: "#FF8C42").opacity(0.3)      // Soft orange
    static let reviewingTint = Color(hex: "#FFC947").opacity(0.3)     // Warm yellow
    static let masteredTint = Color(hex: "#4CAF50").opacity(0.3)      // Soft green
    static let inactiveTint = Color(hex: "#E0E0E0")                   // Light gray
    
    static let overdueWarning = Color(hex: "#FF5722").opacity(0.8)    // Red warning
    static let notificationBlue = Color(hex: "#2196F3").opacity(0.6)  // Blue highlight
}
```

### Typography & Spacing
- **Primary Font**: SF Pro (system font with Dynamic Type support)
- **Card Questions**: Title 2, semibold
- **Card Answers**: Body, regular
- **Spacing**: 8pt base unit with 16pt/24pt/32pt multiples
- **Touch Targets**: Minimum 44pt for accessibility

## Architecture Principles

### 🏗️ Core Patterns
- **MVVM with SwiftUI**: Clean separation with ViewModels managing business logic
- **Protocol-Oriented Design**: Testable interfaces for data access and business logic
- **Repository Pattern**: Abstract SwiftData access through protocols
- **Dependency Injection**: Enable testing and modularity

### 📱 Technical Stack
- **UI**: SwiftUI with custom components and animations
- **Data**: SwiftData with background context handling
- **Notifications**: UserNotifications with rich content and deep linking
- **Analytics**: Local-first tracking with privacy focus
- **Testing**: Unit tests for algorithms, UI tests for critical flows

### 🔄 Development Workflow
1. **Goal Definition**: What user value does this create?
2. **Success Metrics**: How do we know it works?
3. **MVP Implementation**: Simplest version that works
4. **Personal Testing**: Does it solve the actual problem?
5. **Iteration**: Enhance based on real usage patterns

---

## Implementation Guidelines

### Daily Card Selection Algorithm
```swift
func getTodaysCards(maxLimit: Int = 30) -> [Flashcard] {
    // 1. Priority: Overdue cards (up to 3 days, then archived)
    let overdueCards = getOverdueCards(maxDays: 3)
    
    // 2. Pending notifications (uncompleted notification sessions)
    let pendingNotifications = getPendingNotificationCards()
    
    // 3. Learning cards (daily appearance)
    let learningCards = getLearningCards()
    let availableLearning = min(learningCards.count, maxLimit - overdueCards.count - pendingNotifications.count)
    let selectedLearning = selectLearningCards(from: learningCards, limit: availableLearning)
    
    // 4. Reviewing cards (every 2-3 days)
    let reviewingCards = getReviewingCardsDueToday()
    
    // 5. Mastered cards (every 6-7 days)
    let masteredCards = getMasteredCardsDueToday()
    
    return overdueCards + pendingNotifications + selectedLearning + reviewingCards + masteredCards
}

func selectLearningCards(from cards: [Flashcard], limit: Int) -> [Flashcard] {
    // Priority order for learning card rotation:
    // 1. Cards not studied in 2+ days
    // 2. Cards with accuracy < 70%
    // 3. Recently added cards (within 7 days)
    // 4. Random selection from remaining
    
    if cards.count <= limit { return cards }
    
    let unseen = cards.filter { $0.daysSinceLastStudy >= 2 }
    let struggling = cards.filter { $0.accuracy < 0.7 }
    let recent = cards.filter { $0.createdDate.timeIntervalSinceNow > -7*24*3600 }
    let random = cards.shuffled()
    
    return Array(Set(unseen + struggling + recent + random).prefix(limit))
}
```

### Study Session Flow Logic
```swift
enum StudySessionMode {
    case allCards           // All cards from Today tab
    case learningOnly       // Only learning state cards
    case reviewingOnly      // Only reviewing + mastered cards
    case custom([Flashcard]) // User-selected cards
    case notification([Flashcard]) // From notification tap
}

struct SessionConfiguration {
    let mode: StudySessionMode
    let estimatedDuration: TimeInterval
    let cardCount: Int
    let breakdown: [StudyCardState: Int]
    
    var description: String {
        switch mode {
        case .allCards: return "Study all cards from today"
        case .learningOnly: return "Focus on learning cards"
        case .reviewingOnly: return "Review established knowledge"
        case .custom: return "Custom selection"
        case .notification: return "From notification"
        }
    }
}
```

### Notification Strategy Implementation
```swift
func scheduleNextNotification() {
    let learningCardCount = countActiveCards(in: .learning)
    let batchSize = calculateBatchSize(for: learningCardCount)
    let cards = selectCardsForNotification(count: batchSize)
    
    let notificationContent = createNotificationContent(for: cards)
    let trigger = createNotificationTrigger(basedOn: userPreferences)
    
    scheduleNotification(content: notificationContent, trigger: trigger)
}

func calculateBatchSize(for cardCount: Int) -> Int {
    switch cardCount {
    case 0..<20: return 1           // Single card notifications
    case 20..<100: return 2...3     // Small batches
    default: return 5...8           // Larger sessions for finals mode
    }
}
```

## Success Criteria

### 📊 Personal Use Validation (Phase-by-Phase)
**Phase 1**: Complete 10+ study sessions with 50+ flashcards across 3+ classes
**Phase 2**: Maintain daily study routine with proper state transitions for 2+ weeks  
**Phase 3**: Respond to 80%+ of notifications with seamless app experience
**Phase 4**: Use progress insights to optimize study habits and maintain motivation
**Phase 5**: Feel confident recommending app to other students

### 🚀 Technical Performance Targets
- **Load Times**: Today tab renders in <1 second with 100+ cards
- **Study Flow**: Card transitions under 200ms with smooth animations
- **Data Integrity**: Zero card loss or corruption across app updates
- **Battery Impact**: Minimal background usage (<2% daily battery drain)
- **Accessibility**: Full VoiceOver compatibility and Dynamic Type support

### 💡 Learning Effectiveness Goals
- **Retention**: 80%+ accuracy on cards after 1 week in "mastered" state
- **Habit Formation**: 14+ consecutive days of study activity
- **Content Mastery**: Cards naturally progress through study states based on performance
- **Time Efficiency**: Average 2-3 minutes per 5-card study session

---

## Implementation Flexibility & Adaptation

This guide focuses on **goals and outcomes** rather than rigid technical specifications. Key principles:

**Adapt Based on Learning**: If a technical approach isn't working, pivot while maintaining the goal
**Personal Usage Drives Decisions**: Real usage patterns will reveal what actually matters
**Iterative Refinement**: Each phase builds working value, enabling immediate personal use
**Future-Proofing**: Architecture decisions consider both current needs and eventual broader release

The ultimate goal: Create an app that genuinely transforms dead time into accelerated learning through intelligent spaced repetition, aggressive but respectful notifications, and delightful user experience.