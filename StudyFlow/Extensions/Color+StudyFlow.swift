//
//  Color+StudyFlow.swift
//  StudyFlow
//
//  Created by Assistant on 8/14/25.
//

import SwiftUI

extension Color {
    // MARK: - Study State Colors (Subtle Tints)
    static let learningTint = Color(hex: "#FF8C42")?.opacity(0.3) ?? Color.orange.opacity(0.3)
    static let reviewingTint = Color(hex: "#FFC947")?.opacity(0.3) ?? Color.yellow.opacity(0.3)
    static let masteredTint = Color(hex: "#4CAF50")?.opacity(0.3) ?? Color.green.opacity(0.3)
    static let inactiveTint = Color(hex: "#E0E0E0") ?? Color.gray.opacity(0.3)
    
    // MARK: - Priority Indicators
    static let overdueWarning = Color(hex: "#FF5722")?.opacity(0.8) ?? Color.red.opacity(0.8)
    static let notificationBlue = Color(hex: "#2196F3")?.opacity(0.6) ?? Color.blue.opacity(0.6)
    
    // MARK: - Study State Accent Colors (Full Opacity)
    static let learningAccent = Color(hex: "#FF8C42") ?? Color.orange
    static let reviewingAccent = Color(hex: "#FFC947") ?? Color.yellow
    static let masteredAccent = Color(hex: "#4CAF50") ?? Color.green
    static let inactiveAccent = Color(hex: "#9E9E9E") ?? Color.gray
    
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
