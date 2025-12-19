//
//  Colors.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

/// Centralized color system for VitaLens following the Vital Earth theme
/// All colors support light and dark modes using semantic color names
struct Colors {
    
    // MARK: - Primary Colors
    static let primary = Color(light: "#3A5A40", dark: "#A3B18A")
    static let secondary = Color(light: "#588157", dark: "#7F9C88")
    static let accent = Color(light: "#E9C46A", dark: "#F4D35E")
    
    // MARK: - Background Colors
    static let background = Color(light: "#FAFDF8", dark: "#0F1A14")
    static let surface = Color(light: "#FFFFFF", dark: "#1C2B22")
    
    // MARK: - Text Colors
    static let textPrimary = Color(light: "#1F2933", dark: "#F1F5F9")
    static let textSecondary = Color(light: "#4B5563", dark: "#9CA3AF")
    
    // MARK: - Semantic Colors
    static let success = Color(light: "#2F855A", dark: "#68D391")
    static let warning = Color(light: "#D97706", dark: "#FBBF24")
    static let error = Color(light: "#DC2626", dark: "#F87171")
}

// MARK: - Color Extension for Hex Support
extension Color {
    /// Initialize color from hex string with light and dark mode support
    /// - Parameters:
    ///   - light: Hex color string for light mode (e.g., "#3A5A40")
    ///   - dark: Hex color string for dark mode (e.g., "#A3B18A")
    init(light: String, dark: String) {
        self.init(
            UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor(hex: dark) ?? UIColor.systemBackground
                default:
                    return UIColor(hex: light) ?? UIColor.systemBackground
                }
            }
        )
    }
    
    /// Initialize color from hex string
    /// - Parameter hex: Hex color string (e.g., "#3A5A40" or "3A5A40")
    init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension for Hex Support
extension UIColor {
    /// Initialize UIColor from hex string
    /// - Parameter hex: Hex color string (e.g., "#3A5A40" or "3A5A40")
    convenience init?(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
