# StudyFlow - Technical Implementation Documentation

## Project Overview
StudyFlow is an iOS app built with SwiftUI and SwiftData that implements intelligent spaced repetition learning through aggressive but respectful notifications and micro-learning sessions.

**Target**: iOS 17+ | **Architecture**: MVVM + SwiftData | **Language**: Swift 5.9+

---

## 🏗️ Architecture Overview

### Data Layer (SwiftData)
- **Core Models**: `StudyClass` → `Lecture` → `Flashcard` hierarchy
- **Session Tracking**: `StudySession` for analytics and progress
- **Enum Handling**: Custom solution for SwiftData enum compatibility

### View Layer (SwiftUI)
- **Tab-Based Navigation**: 4 primary tabs (Today, Library, Progress, Settings)
- **Priority-Based UI**: Today tab shows intelligent card prioritization
- **State Management**: Environment objects and SwiftData queries

### Business Logic
- **Spaced Repetition**: Custom algorithm with user-controlled intensity
- **Study States**: Four-tier system (Learning → Reviewing → Mastered → Inactive)
- **Daily Scheduling**: Smart card selection with configurable limits

---

## 📊 Data Models & Architecture

### SwiftData Model Structure

```swift
@Model class StudyClass {
    var name: String                    // "Neural Networks"
    var colorCode: String              // "#4A90E2" for visual organization
    var isActive: Bool = true          // Can disable entire classes
    var createdDate: Date
    @Relationship(deleteRule: .cascade) var lectures: [Lecture] = []
}

@Model class Lecture {
    var title: String                  // "Introduction to Neural Networks"
    var lectureDescription: String?    // Optional detailed description
    var createdDate: Date
    var studyClass: StudyClass?        // Parent relationship
    @Relationship(deleteRule: .cascade) var flashcards: [Flashcard] = []
}

@Model class Flashcard {
    var question: String               // "What is backpropagation?"
    var answer: String                // Detailed explanation
    var studyStateRaw: String = "learning"  // See enum handling below
    var isActive: Bool = true          // User can disable specific cards
    
    // Spaced repetition tracking
    var correctCount: Int = 0          // Consecutive correct answers
    var totalAttempts: Int = 0         // For accuracy calculation
    var lastStudied: Date?             // When last reviewed
    var nextScheduledDate: Date        // When due for next review
    var lastPromotionOffered: Date?    // Track promotion UX
    
    // Performance metrics
    var averageResponseTime: TimeInterval = 0
    var createdDate: Date
    var lecture: Lecture?              // Parent relationship
}
```

### 🔧 Critical Implementation: SwiftData Enum Compatibility

**Problem**: SwiftData cannot directly store complex enums with computed properties.

**Solution**: Store raw String values with computed property wrappers.

```swift
// In @Model class:
var studyStateRaw: String = "learning"  // Stored in database

// Computed property for type-safe access:
var studyState: StudyCardState {
    get { StudyCardState(rawValue: studyStateRaw) ?? .learning }
    set { studyStateRaw = newValue.rawValue }
}
```

**Why This Works**:
- ✅ SwiftData handles String primitives perfectly
- ✅ Views still use type-safe enum API: `card.studyState = .reviewing`
- ✅ Database stores simple strings: `"learning"`, `"reviewing"`, etc.
- ✅ Automatic fallback to `.learning` if data corruption occurs

### Study State System

```swift
enum StudyCardState: String, CaseIterable, Codable {
    case learning = "learning"     // 🟠 Appears daily, aggressive drilling
    case reviewing = "reviewing"   // 🟡 Every 2-3 days, spaced intervals
    case mastered = "mastered"     // 🟢 Every 6-7 days, maintenance
    case inactive = "inactive"     // ⚪ User disabled, never appears
}
```

**State Transition Logic**:
- **Manual Only**: No automatic promotions
- **User Triggered**: Promotion option appears after 5+ correct answers
- **Bulk Operations**: Can move entire lectures between states
- **Smart Defaults**: New cards start as `learning`

---

## 🎯 Today Tab - Priority Intelligence

### Card Prioritization Algorithm

The Today tab implements intelligent card prioritization based on urgency and learning science:

```swift
// Priority Order (top to bottom):
1. 🚨 OVERDUE - Past nextScheduledDate (1-3 days, then archived)
2. 🔔 PENDING NOTIFICATIONS - Uncompleted notification sessions  
3. 🟠 LEARNING TODAY - Daily drilling cards (aggressive frequency)
4. 🟡 REVIEWING TODAY - Every 2-3 days rotation
5. 🟢 MASTERED TODAY - Weekly maintenance (6-7 days)
```

### Daily Card Selection Logic

```swift
func getTodaysCards(maxLimit: Int = 30) -> [Flashcard] {
    // 1. Always include overdue (up to 3 days old)
    let overdueCards = getOverdueCards(maxDays: 3)
    
    // 2. Include pending notifications (uncompleted sessions)
    let pendingNotifications = getPendingNotificationCards()
    
    // 3. Smart learning card rotation if >30 total
    let learningCards = getLearningCards()
    let availableSlots = maxLimit - overdueCards.count - pendingNotifications.count
    let selectedLearning = selectLearningCards(from: learningCards, limit: availableSlots)
    
    // 4. Add reviewing/mastered cards that are due today
    let reviewingCards = getReviewingCardsDueToday()
    let masteredCards = getMasteredCardsDueToday()
    
    return overdueCards + pendingNotifications + selectedLearning + reviewingCards + masteredCards
}
```

### Learning Card Rotation Strategy

When user has >30 learning cards, rotation prioritizes:
1. **Cards not studied in 2+ days** (prevent forgetting)
2. **Cards with accuracy < 70%** (struggling cards need attention)  
3. **Recently added cards** (within 7 days)
4. **Random selection** from remaining pool

---

## 📱 UI Architecture & Navigation

### Tab Structure Design Rationale

**Today Tab (Primary)**: Action-oriented workspace, not organizational view
- **Philosophy**: Show what needs attention NOW, not everything available
- **Visual Hierarchy**: Priority sections with clear color coding
- **Actions**: Prominent study buttons with time estimates

**Library Tab (Secondary)**: Content management and organization  
- **Philosophy**: CRUD operations, hierarchical browsing
- **Features**: Class creation, lecture organization, flashcard management
- **Bulk Operations**: Efficient state management for multiple cards

**Progress Tab**: Analytics and motivation
- **Philosophy**: Feedback loops to encourage consistency
- **Metrics**: Daily stats, accuracy trends, state distribution
- **Motivation**: Achievement tracking, streak visualization

**Settings Tab**: Configuration without complexity
- **Philosophy**: Smart defaults, easy customization for power users
- **Key Settings**: Daily card limits (30/50), notification scheduling
- **Advanced**: Study intensity modes, quiet hours

### Color System Implementation

```swift
extension Color {
    // Study state colors (subtle tints for UI comfort)
    static let learningTint = Color(hex: "#FF8C42").opacity(0.3)    // Soft orange
    static let reviewingTint = Color(hex: "#FFC947").opacity(0.3)   // Warm yellow  
    static let masteredTint = Color(hex: "#4CAF50").opacity(0.3)    // Soft green
    static let inactiveTint = Color(hex: "#E0E0E0")                 // Light gray
    
    // Priority indicators
    static let overdueWarning = Color(hex: "#FF5722").opacity(0.8)  // Red warning
    static let notificationBlue = Color(hex: "#2196F3").opacity(0.6) // Blue highlight
}
```

**Design Philosophy**:
- **Subtle, not aggressive**: 30% opacity prevents visual fatigue
- **Meaningful associations**: Orange=active learning, Green=mastered
- **Accessibility**: High contrast ratios, Dynamic Type support
- **Consistency**: Same colors across all views

---

## 🔄 Study Session Flow (Planned)

### Session Configuration Types

```swift
enum StudySessionMode {
    case allCards           // All cards from Today tab
    case learningOnly       // Focus on learning state cards
    case reviewingOnly      // Review established knowledge  
    case custom([Flashcard]) // User-selected cards
    case notification([Flashcard]) // From notification tap
}
```

### Session State Management

**Critical Requirements**:
- **Persistence**: Session state survives app backgrounding
- **Progress Tracking**: Real-time accuracy calculation
- **Interruption Handling**: Graceful pause/resume
- **Performance Updates**: Immediate spaced repetition recalculation

---

## 🔔 Notification Strategy (Planned Implementation)

### Adaptive Frequency Algorithm

```swift
func calculateBatchSize(for cardCount: Int) -> Int {
    switch cardCount {
    case 0..<20: return 1           // Single card notifications
    case 20..<100: return 2...3     // Small batches (2-3 cards)
    default: return 5...8           // Larger sessions for finals mode
    }
}
```

### Notification Intelligence Features

**Smart Timing**:
- **Usage Pattern Learning**: Identify most responsive times
- **Focus Mode Integration**: Respect Do Not Disturb settings
- **Quiet Hours**: Configurable sleep/work hour blocking

**Rich Content**:
- **Question Previews**: Show actual card content
- **Quick Actions**: Study Now, Remind Later, Skip, Add to Queue
- **Deep Linking**: Direct navigation to specific card sets

---

## 🛠️ Development Patterns & Best Practices

### SwiftData Query Patterns

```swift
// Efficient queries with proper filtering
@Query(filter: #Predicate<Flashcard> { card in
    card.isActive && card.studyStateRaw == "learning"
}, sort: \Flashcard.createdDate, order: .reverse) 
private var learningCards: [Flashcard]

// Complex filtering with computed properties
private var overdueCards: [Flashcard] {
    allFlashcards.filter { card in
        card.isActive && 
        card.isOverdue && 
        card.overdueStatus.warningLevel <= 3
    }
}
```

### Error Handling Strategy

**Data Integrity**:
- **Enum Fallbacks**: Default to `.learning` if invalid state
- **Relationship Safety**: Cascade deletes prevent orphaned records
- **Date Validation**: Handle edge cases in scheduling calculations

**User Experience**:
- **Graceful Degradation**: App functions even with data issues
- **Recovery Mechanisms**: Clear actions when problems occur
- **Logging**: Comprehensive error tracking for debugging

### Performance Considerations

**Computed Properties**: Expensive calculations cached where possible
**Query Optimization**: Predicates filter at database level
**Memory Management**: Large card sets handled efficiently
**Background Processing**: Scheduling calculations don't block UI

---

## 📁 File Organization

```
StudyFlow/
├── StudyFlowApp.swift              // App entry point, SwiftData setup
├── ContentView.swift               // Legacy wrapper, forwards to MainTabView
├── Models/
│   └── StudyModels.swift           // All SwiftData models and enums
├── Views/
│   ├── MainTabView.swift           // Tab navigation structure
│   ├── TodayView.swift             // Primary study interface
│   ├── LibraryView.swift           // Content management
│   ├── ProgressView.swift          // Analytics and stats
│   └── SettingsView.swift          // Configuration interface
└── Documentation/
    ├── DEVELOPMENT_GUIDE.md        // Goal-based development roadmap
    └── TECHNICAL_DOCUMENTATION.md // This file - implementation details
```

---

## 🚀 Future Implementation Notes

### Phase 2: Study Session Engine (Next)
- **Card Interaction**: Tap-to-flip animations, haptic feedback
- **Response Processing**: Accuracy tracking, state updates
- **Session Analytics**: Performance tracking, time measurement

### Phase 3: Notification System
- **UserNotifications Framework**: Rich content, interactive actions
- **Background Scheduling**: Efficient notification queue management
- **Deep Linking**: Navigation from notification to study session

### Phase 4: Advanced Features
- **Progress Analytics**: Charts, trends, achievement system
- **Data Export**: JSON backup/restore functionality
- **Accessibility Polish**: VoiceOver optimization, motor accessibility

---

## ⚠️ Critical Reminders

### SwiftData Gotchas
1. **Enum Storage**: Always use String raw values with computed property wrappers
2. **Relationship Cascade**: Set `deleteRule: .cascade` to prevent orphaned data
3. **Query Performance**: Use `@Query` with predicates, not computed filtering
4. **Background Context**: Handle model updates safely across contexts

### UI/UX Principles
1. **Priority Over Organization**: Today tab shows urgency, not completeness
2. **Subtle Visual Hierarchy**: Color tints, not bold highlights
3. **Action-Oriented Design**: Prominent buttons for primary workflows
4. **Interruption-Friendly**: Pausable sessions, persistent state

### Performance Targets
- **Today Tab Load**: <1 second with 100+ cards
- **Study Session Flow**: <200ms card transitions
- **Data Integrity**: Zero card loss across app updates
- **Battery Usage**: <2% daily background drain

---

## 📝 Change Log

### v1.0.0 - Foundation (COMPLETE)
- ✅ SwiftData models with enum compatibility solution
- ✅ Four-tab navigation structure with professional design system
- ✅ Today tab with intelligent card prioritization and sophisticated spaced repetition
- ✅ Library tab with comprehensive CRUD operations and color selection
- ✅ Complete study session engine with animations and haptic feedback
- ✅ Advanced spaced repetition algorithm (SM-2 inspired)
- ✅ Progress analytics and session tracking
- ✅ Settings interface with user preferences
- ✅ Comprehensive sample data generation
- ✅ Professional UI/UX with consistent design system
- ✅ Core architectural patterns established

### Phase 1 Status: COMPLETE ✅
All Phase 1 goals from the development guide have been successfully implemented:
- **SwiftData Model Foundation**: Complete with proper enum handling
- **Today Tab - Core Study Interface**: Complete with prioritized display and session integration
- **Library Tab - Content Management**: Complete with hierarchical navigation and bulk operations
- **Study Session Engine**: Complete with card interactions, animations, and state persistence

### Next Release Planning (Phase 2)
- [ ] Intelligent notification system with rich content
- [ ] Background notification scheduling
- [ ] Deep linking from notifications
- [ ] Advanced progress charts and analytics

---

*This documentation should be updated with each major implementation phase to maintain accuracy and usefulness for future development.*