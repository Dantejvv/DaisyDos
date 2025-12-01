//
//  InputValidation.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

/// Input validation utilities and constants for consistent form behavior across the app
/// Provides centralized character limits, validation logic, and color feedback
struct InputValidation {

    // MARK: - Character Limits

    /// Standard character limits used across tasks and habits
    struct CharacterLimits {
        /// Maximum characters for titles (both tasks and habits)
        static let title: Int = 50

        /// Maximum characters for tag names
        static let tagName: Int = 20

        /// Maximum characters for skip reasons
        static let skipReason: Int = 100
    }

    // MARK: - Color Thresholds

    /// Color transition thresholds for character count feedback
    struct ColorThresholds {
        /// Percentage at which text turns yellow (approaching limit)
        static let warning: Double = 0.6

        /// Percentage at which text turns orange (near limit)
        static let caution: Double = 0.8

        /// Percentage at which text turns red (at/over limit)
        static let danger: Double = 1.0
    }

    // MARK: - Character Count Color Utility

    /// Returns appropriate color for character count feedback
    /// - Parameters:
    ///   - currentCount: Current number of characters
    ///   - maxLength: Maximum allowed characters
    /// - Returns: Color based on percentage of limit reached
    static func characterCountColor(currentCount: Int, maxLength: Int) -> Color {
        let percentage = Double(currentCount) / Double(maxLength)

        switch percentage {
        case ColorThresholds.danger...:
            return .daisyError
        case ColorThresholds.caution..<ColorThresholds.danger:
            return .orange
        case ColorThresholds.warning..<ColorThresholds.caution:
            return .yellow
        default:
            return .daisyTextSecondary
        }
    }

    /// Returns appropriate color for character count feedback with exact threshold checking
    /// - Parameters:
    ///   - currentCount: Current number of characters
    ///   - maxLength: Maximum allowed characters
    /// - Returns: Color based on character count thresholds
    static func characterCountColorExact(currentCount: Int, maxLength: Int) -> Color {
        return currentCount > maxLength ? .daisyError :
               currentCount > Int(Double(maxLength) * ColorThresholds.caution) ? .orange :
               currentCount > Int(Double(maxLength) * ColorThresholds.warning) ? .yellow :
               .daisyTextSecondary
    }

    // MARK: - Validation Utilities

    /// Enforces character limit by truncating text if needed
    /// - Parameters:
    ///   - text: Current text value
    ///   - newValue: New text value being entered
    ///   - maxLength: Maximum allowed characters
    /// - Returns: Truncated text if over limit, otherwise new value
    static func enforceCharacterLimit(_ text: inout String, newValue: String, maxLength: Int) {
        if newValue.count > maxLength {
            text = String(newValue.prefix(maxLength))
        } else {
            text = newValue
        }
    }

    /// Checks if text is within character limit
    /// - Parameters:
    ///   - text: Text to validate
    ///   - maxLength: Maximum allowed characters
    /// - Returns: True if within limit, false otherwise
    static func isWithinLimit(_ text: String, maxLength: Int) -> Bool {
        return text.count <= maxLength
    }

    /// Checks if trimmed text is empty
    /// - Parameter text: Text to validate
    /// - Returns: True if empty after trimming whitespace, false otherwise
    static func isEmpty(_ text: String) -> Bool {
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Checks if text exceeds warning threshold
    /// - Parameters:
    ///   - text: Text to check
    ///   - maxLength: Maximum allowed characters
    /// - Returns: True if approaching limit (60%+), false otherwise
    static func isApproachingLimit(_ text: String, maxLength: Int) -> Bool {
        return Double(text.count) / Double(maxLength) >= ColorThresholds.warning
    }

    /// Checks if text exceeds caution threshold
    /// - Parameters:
    ///   - text: Text to check
    ///   - maxLength: Maximum allowed characters
    /// - Returns: True if near limit (80%+), false otherwise
    static func isNearLimit(_ text: String, maxLength: Int) -> Bool {
        return Double(text.count) / Double(maxLength) >= ColorThresholds.caution
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies character count color feedback to text
    /// - Parameters:
    ///   - currentCount: Current character count
    ///   - maxLength: Maximum allowed characters
    /// - Returns: View with appropriate foreground color
    func characterCountColor(currentCount: Int, maxLength: Int) -> some View {
        self.foregroundColor(InputValidation.characterCountColor(currentCount: currentCount, maxLength: maxLength))
    }
}