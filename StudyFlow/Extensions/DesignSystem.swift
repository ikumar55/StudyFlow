//
//  DesignSystem.swift
//  StudyFlow
//
//  Created by Assistant on 8/14/25.
//

import SwiftUI

// MARK: - Typography System
extension Font {
    // MARK: - Semantic Font Styles
    static let studyFlowTitle = Font.largeTitle.weight(.bold)
    static let studyFlowHeadline = Font.title2.weight(.semibold)
    static let studyFlowSubheadline = Font.headline.weight(.medium)
    static let studyFlowBody = Font.body
    static let studyFlowCaption = Font.caption
    static let studyFlowSmall = Font.caption2
    
    // MARK: - Card-Specific Fonts
    static let cardQuestion = Font.title2.weight(.semibold)
    static let cardAnswer = Font.body
    static let cardMetadata = Font.caption.weight(.medium)
}

// MARK: - Spacing System
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    // Semantic spacing
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let itemSpacing: CGFloat = 12
}

// MARK: - Corner Radius System
struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let card: CGFloat = 16
    static let button: CGFloat = 12
}

// MARK: - Shadow System
extension View {
    func studyFlowCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func studyFlowButtonShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    func studyFlowSectionShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Button Styles
struct StudyFlowPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.studyFlowSubheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .studyFlowButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StudyFlowSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.studyFlowBody)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StudyFlowDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.studyFlowSubheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.lg)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .studyFlowButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Study Session Answer Button Styles
struct StudyAnswerWrongButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.studyFlowSubheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // Fixed height for consistency
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .studyFlowButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StudyAnswerCorrectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.studyFlowSubheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // Fixed height for consistency
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .studyFlowButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Card Styles
struct StudyFlowCardStyle: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .studyFlowCardShadow()
    }
}

extension View {
    func studyFlowCard(backgroundColor: Color = Color(.systemBackground)) -> some View {
        self.modifier(StudyFlowCardStyle(backgroundColor: backgroundColor))
    }
}

// MARK: - Section Header Style
struct StudyFlowSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.studyFlowHeadline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.studyFlowCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .font(.studyFlowCaption)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Empty State Style
struct StudyFlowEmptyState: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.studyFlowHeadline)
                
                Text(description)
                    .font(.studyFlowBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(StudyFlowPrimaryButtonStyle())
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Loading State
struct StudyFlowLoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.studyFlowBody)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
}

// MARK: - Animation Presets
extension Animation {
    static let studyFlowSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let studyFlowEaseInOut = Animation.easeInOut(duration: 0.3)
    static let studyFlowQuick = Animation.easeInOut(duration: 0.15)
}
