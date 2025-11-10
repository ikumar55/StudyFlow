//
//  Color+StudyFlow.swift
//  StudyFlow
//
//  Created by Assistant on 8/14/25.
//

import SwiftUI

extension Color {
    // MARK: - iOS Native Colors
    static let iosLightGray = Color(hex: "#F6F6F6") ?? Color(.systemGray6)
    static let iosLightGray2 = Color(hex: "#F2F2F7") ?? Color(.systemGray6)
    
    // MARK: - Subtle Section Background Colors
    static let overdueBackground = Color(hex: "#FEF7F7") ?? Color.red.opacity(0.05)
    static let learningBackground = Color(hex: "#FFF9E6") ?? Color.orange.opacity(0.05)
    static let reviewingBackground = Color(hex: "#F0F8FF") ?? Color.blue.opacity(0.05)
    static let masteredBackground = Color.white // Keep mastered as pure white
    
    // MARK: - Section Accent Colors (for borders)
    static let overdueAccent = Color(hex: "#FF3B30") ?? Color.red
    static let learningBorderAccent = Color(hex: "#FF9500") ?? Color.orange
    static let reviewingBorderAccent = Color(hex: "#007AFF") ?? Color.blue
    static let masteredBorderAccent = Color.green
    
    // MARK: - Typography Colors
    static let subtitleGray = Color(hex: "#8E8E93") ?? Color.secondary
    
    // MARK: - Study State Colors (iOS Native with White Backgrounds)
    static let learningTint = Color.white
    static let reviewingTint = Color.white
    static let masteredTint = Color.white
    static let inactiveTint = Color.white
    
    // MARK: - Priority Indicators (Updated for iOS Native)
    static let overdueWarning = Color.red
    static let notificationBlue = Color.blue
    
    // MARK: - Study State Accent Colors (iOS Native)
    static let learningAccent = Color.orange
    static let reviewingAccent = Color.blue  // Changed from yellow for better iOS feel
    static let masteredAccent = Color.green
    static let inactiveAccent = Color.gray
    
    // MARK: - Hex Color Initializer
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Study State Color Helper
extension StudyCardState {
    var tintColor: Color {
        switch self {
        case .learning: return .learningTint
        case .reviewing: return .reviewingTint
        case .mastered: return .masteredTint
        case .inactive: return .inactiveTint
        }
    }
    
    var accentColor: Color {
        switch self {
        case .learning: return .learningAccent
        case .reviewing: return .reviewingAccent
        case .mastered: return .masteredAccent
        case .inactive: return .inactiveAccent
        }
    }
}
