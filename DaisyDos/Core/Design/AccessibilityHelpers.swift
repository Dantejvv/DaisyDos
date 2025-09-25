//
//  AccessibilityHelpers.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import UIKit

/// Accessibility helpers and constants for DaisyDos
/// Ensures WCAG AA compliance and excellent VoiceOver experience
/// All touch targets meet minimum 44pt requirement with 48pt recommended
struct AccessibilityHelpers {

    // MARK: - Touch Target Constants

    /// Touch target dimensions following iOS Human Interface Guidelines
    enum TouchTarget {
        /// Absolute minimum touch target size per iOS HIG
        static let minimum: CGSize = CGSize(width: 44, height: 44)

        /// Recommended comfortable touch target size
        static let recommended: CGSize = CGSize(width: 48, height: 48)

        /// Large touch target for accessibility
        static let large: CGSize = CGSize(width: 56, height: 56)

        /// Extra large touch target for users with motor difficulties
        static let extraLarge: CGSize = CGSize(width: 64, height: 64)

        /// Validates that a size meets minimum requirements
        static func meetsMinimum(_ size: CGSize) -> Bool {
            return size.width >= minimum.width && size.height >= minimum.height
        }

        /// Suggests appropriate touch target size for element type
        static func suggestedSize(for elementType: ElementType) -> CGSize {
            switch elementType {
            case .button:
                return recommended
            case .smallControl:
                return minimum
            case .primaryAction:
                return large
            case .accessibilityTarget:
                return extraLarge
            }
        }

        enum ElementType {
            case button
            case smallControl
            case primaryAction
            case accessibilityTarget
        }
    }

    // MARK: - Contrast Requirements

    /// WCAG contrast ratio requirements and validation
    enum Contrast {
        /// WCAG AA contrast ratios
        static let normalTextMinimum: Double = 4.5
        static let largeTextMinimum: Double = 3.0
        static let uiComponentMinimum: Double = 3.0
        static let graphicalObjectMinimum: Double = 3.0

        /// WCAG AAA contrast ratios (enhanced)
        static let normalTextEnhanced: Double = 7.0
        static let largeTextEnhanced: Double = 4.5

        /// Large text size thresholds
        static let largeTextPointSize: CGFloat = 18  // 18pt regular or 14pt bold
        static let largeBoldTextPointSize: CGFloat = 14

        /// Validates contrast ratio for text
        static func validateTextContrast(
            ratio: Double,
            fontSize: CGFloat,
            fontWeight: Font.Weight = .regular,
            standard: Standard = .aa
        ) -> Bool {
            let isLargeText = isLargeTextSize(fontSize: fontSize, fontWeight: fontWeight)
            let requiredRatio = textRequiredRatio(isLarge: isLargeText, standard: standard)
            return ratio >= requiredRatio
        }

        /// Determines if text qualifies as "large text" for contrast purposes
        static func isLargeTextSize(fontSize: CGFloat, fontWeight: Font.Weight) -> Bool {
            if fontWeight == .bold || fontWeight == .black || fontWeight == .heavy {
                return fontSize >= largeBoldTextPointSize
            } else {
                return fontSize >= largeTextPointSize
            }
        }

        /// Gets required contrast ratio for text
        static func textRequiredRatio(isLarge: Bool, standard: Standard) -> Double {
            switch (isLarge, standard) {
            case (true, .aa):
                return largeTextMinimum
            case (true, .aaa):
                return largeTextEnhanced
            case (false, .aa):
                return normalTextMinimum
            case (false, .aaa):
                return normalTextEnhanced
            }
        }

        enum Standard {
            case aa   // WCAG AA (minimum)
            case aaa  // WCAG AAA (enhanced)
        }
    }

    // MARK: - VoiceOver Support

    /// VoiceOver navigation and announcement helpers
    enum VoiceOver {

        /// Common accessibility traits for different UI elements
        enum Traits {
            static let button: AccessibilityTraits = .isButton
            static let link: AccessibilityTraits = .isLink
            static let header: AccessibilityTraits = .isHeader
            static let staticText: AccessibilityTraits = .isStaticText
            static let image: AccessibilityTraits = .isImage
            static let searchField: AccessibilityTraits = .isSearchField
            static let selected: AccessibilityTraits = .isSelected
            static let disabled: AccessibilityTraits = [.isButton, .allowsDirectInteraction]
        }

        /// Accessibility action types for complex interactions
        enum Actions {
            static let activate = AccessibilityActionKind.default
            static let escape = AccessibilityActionKind.escape
            // Note: delete, increment, decrement may not be available on all platforms
        }

        /// Creates descriptive accessibility label
        static func createLabel(
            primary: String,
            secondary: String? = nil,
            context: String? = nil
        ) -> String {
            var components = [primary]

            if let secondary = secondary {
                components.append(secondary)
            }

            if let context = context {
                components.append(context)
            }

            return components.joined(separator: ", ")
        }

        /// Creates accessibility hint for actions
        static func createHint(action: String, result: String? = nil) -> String {
            if let result = result {
                return "\(action). \(result)"
            } else {
                return action
            }
        }

        /// Creates accessibility value for controls
        static func createValue(
            current: String,
            total: String? = nil,
            unit: String? = nil
        ) -> String {
            var value = current

            if let unit = unit {
                value += " \(unit)"
            }

            if let total = total {
                value += " of \(total)"
                if let unit = unit {
                    value += " \(unit)"
                }
            }

            return value
        }
    }

    // MARK: - Dynamic Type Support

    /// Dynamic Type scaling and validation
    enum DynamicType {

        /// All supported Dynamic Type categories
        static let allCategories: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge,
            .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge,
            .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]

        /// Standard size categories (non-accessibility)
        static let standardCategories: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge,
            .extraExtraLarge, .extraExtraExtraLarge
        ]

        /// Accessibility size categories
        static let accessibilityCategories: [UIContentSizeCategory] = [
            .accessibilityMedium, .accessibilityLarge,
            .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]

        /// Current Dynamic Type settings
        static var current: UIContentSizeCategory {
            UIApplication.shared.preferredContentSizeCategory
        }

        /// Checks if current setting is an accessibility size
        static var isAccessibilitySize: Bool {
            current.isAccessibilityCategory
        }

        /// Gets scaling factor for current Dynamic Type setting
        static var scalingFactor: CGFloat {
            switch current {
            case .extraSmall:
                return 0.8
            case .small:
                return 0.9
            case .medium:
                return 1.0
            case .large:
                return 1.0  // Base size
            case .extraLarge:
                return 1.1
            case .extraExtraLarge:
                return 1.2
            case .extraExtraExtraLarge:
                return 1.3
            case .accessibilityMedium:
                return 1.4
            case .accessibilityLarge:
                return 1.5
            case .accessibilityExtraLarge:
                return 1.6
            case .accessibilityExtraExtraLarge:
                return 1.7
            case .accessibilityExtraExtraExtraLarge:
                return 1.8
            default:
                return 1.0
            }
        }

        /// Validates that text scales properly across all sizes
        static func validateScaling(baseSize: CGFloat) -> (isValid: Bool, suggestions: [String]) {
            var suggestions: [String] = []
            let maxSize = baseSize * 1.8  // Maximum accessibility scaling
            let minSize = baseSize * 0.8  // Minimum scaling

            // Check if maximum size is reasonable
            if maxSize > 72 {
                suggestions.append("Consider using a smaller base font size for better accessibility scaling")
            }

            // Check if minimum size is readable
            if minSize < 11 {
                suggestions.append("Base font size may be too small - consider increasing to maintain readability")
            }

            return (suggestions.isEmpty, suggestions)
        }
    }

    // MARK: - Accessibility Preferences

    /// System accessibility preferences and their current state
    enum Preferences {

        /// Motion preferences
        static var prefersReducedMotion: Bool {
            UIAccessibility.isReduceMotionEnabled
        }

        /// Transparency preferences
        static var prefersReducedTransparency: Bool {
            UIAccessibility.isReduceTransparencyEnabled
        }

        /// High contrast preferences
        static var prefersIncreasedContrast: Bool {
            UIAccessibility.isDarkerSystemColorsEnabled
        }

        /// Bold text preference
        static var prefersBoldText: Bool {
            UIAccessibility.isBoldTextEnabled
        }

        /// Button shapes preference (simplified check)
        static var prefersButtonShapes: Bool {
            // Note: isButtonShapesEnabled may not be available on all platforms
            false
        }

        /// On/off labels preference
        static var prefersOnOffSwitchLabels: Bool {
            UIAccessibility.isOnOffSwitchLabelsEnabled
        }

        /// VoiceOver status
        static var isVoiceOverRunning: Bool {
            UIAccessibility.isVoiceOverRunning
        }

        /// Switch Control status
        static var isSwitchControlRunning: Bool {
            UIAccessibility.isSwitchControlRunning
        }

        /// Gets recommended adjustments based on preferences
        static var recommendedAdjustments: [Adjustment] {
            var adjustments: [Adjustment] = []

            if prefersReducedMotion {
                adjustments.append(.reduceAnimations)
            }

            if prefersReducedTransparency {
                adjustments.append(.reduceTransparency)
            }

            if prefersIncreasedContrast {
                adjustments.append(.increaseContrast)
            }

            if prefersBoldText {
                adjustments.append(.useBoldText)
            }

            if prefersButtonShapes {
                adjustments.append(.addButtonShapes)
            }

            if isVoiceOverRunning {
                adjustments.append(.optimizeForVoiceOver)
            }

            return adjustments
        }

        enum Adjustment {
            case reduceAnimations
            case reduceTransparency
            case increaseContrast
            case useBoldText
            case addButtonShapes
            case optimizeForVoiceOver

            var description: String {
                switch self {
                case .reduceAnimations:
                    return "Use reduced motion and simpler animations"
                case .reduceTransparency:
                    return "Use solid backgrounds instead of transparency"
                case .increaseContrast:
                    return "Use higher contrast colors"
                case .useBoldText:
                    return "Use bold font weights"
                case .addButtonShapes:
                    return "Add visual button indicators"
                case .optimizeForVoiceOver:
                    return "Optimize for screen reader navigation"
                }
            }
        }
    }

    // MARK: - Testing Utilities

    /// Utilities for testing accessibility compliance
    enum Testing {

        /// Simulates VoiceOver navigation through a hierarchy
        static func simulateVoiceOverNavigation(elements: [AccessibilityElement]) -> [String] {
            return elements.compactMap { element in
                guard element.isAccessible else { return nil }

                var announcement = element.label

                if !element.value.isEmpty {
                    announcement += ", \(element.value)"
                }

                if !element.hint.isEmpty {
                    announcement += ". \(element.hint)"
                }

                return announcement
            }
        }

        /// Validates accessibility element configuration
        static func validateElement(_ element: AccessibilityElement) -> ValidationResult {
            var issues: [String] = []
            var suggestions: [String] = []

            // Check label
            if element.label.isEmpty {
                issues.append("Missing accessibility label")
                suggestions.append("Add descriptive accessibility label")
            } else if element.label.count > 100 {
                suggestions.append("Consider shortening accessibility label for better VoiceOver experience")
            }

            // Check touch target size
            if !TouchTarget.meetsMinimum(element.frame.size) {
                issues.append("Touch target too small (minimum 44x44pt required)")
                suggestions.append("Increase touch target to at least 44x44pt")
            }

            // Check for actionable elements without hints
            if element.traits.contains(.isButton) && element.hint.isEmpty {
                suggestions.append("Consider adding accessibility hint to describe button action")
            }

            return ValidationResult(
                isValid: issues.isEmpty,
                issues: issues,
                suggestions: suggestions
            )
        }

        struct AccessibilityElement {
            let label: String
            let value: String
            let hint: String
            let traits: AccessibilityTraits
            let frame: CGRect
            let isAccessible: Bool

            init(
                label: String,
                value: String = "",
                hint: String = "",
                traits: AccessibilityTraits = .isStaticText,
                frame: CGRect = CGRect(x: 0, y: 0, width: 48, height: 48),
                isAccessible: Bool = true
            ) {
                self.label = label
                self.value = value
                self.hint = hint
                self.traits = traits
                self.frame = frame
                self.isAccessible = isAccessible
            }
        }

        struct ValidationResult {
            let isValid: Bool
            let issues: [String]
            let suggestions: [String]

            var hasIssues: Bool { !issues.isEmpty }
            var hasSuggestions: Bool { !suggestions.isEmpty }
        }
    }

    // MARK: - Common Patterns

    /// Pre-configured accessibility patterns for common UI elements
    enum Patterns {

        /// Task list item accessibility
        static func taskListItem(
            title: String,
            isCompleted: Bool,
            priority: String? = nil,
            dueDate: String? = nil
        ) -> (label: String, hint: String, traits: AccessibilityTraits) {

            var labelComponents = [title]

            if let priority = priority {
                labelComponents.append("\(priority) priority")
            }

            if let dueDate = dueDate {
                labelComponents.append("due \(dueDate)")
            }

            labelComponents.append(isCompleted ? "completed" : "pending")

            let label = labelComponents.joined(separator: ", ")
            let hint = "Double-tap to toggle completion"
            let traits: AccessibilityTraits = .isButton

            return (label, hint, traits)
        }

        /// Habit tracking item accessibility
        static func habitItem(
            title: String,
            currentStreak: Int,
            isCompletedToday: Bool
        ) -> (label: String, hint: String, traits: AccessibilityTraits) {

            let label = "\(title), current streak \(currentStreak) days, \(isCompletedToday ? "completed today" : "not completed today")"
            let hint = isCompletedToday ? "Double-tap to undo completion" : "Double-tap to mark completed"
            let traits: AccessibilityTraits = .isButton

            return (label, hint, traits)
        }

        /// Form field accessibility
        static func formField(
            label: String,
            value: String,
            isRequired: Bool = false,
            errorMessage: String? = nil
        ) -> (label: String, hint: String, traits: AccessibilityTraits) {

            var labelText = label
            if isRequired {
                labelText += ", required"
            }

            var hint = "Text field"
            if let error = errorMessage {
                hint += ". \(error)"
            }

            let traits: AccessibilityTraits = errorMessage != nil ? [.isStaticText] : .isStaticText

            return (labelText, hint, traits)
        }

        /// Navigation item accessibility
        static func navigationItem(
            title: String,
            badgeCount: Int? = nil
        ) -> (label: String, hint: String, traits: AccessibilityTraits) {

            var label = title
            if let count = badgeCount, count > 0 {
                label += ", \(count) items"
            }

            let hint = "Navigate to \(title.lowercased())"
            let traits: AccessibilityTraits = .isButton

            return (label, hint, traits)
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {

    /// Applies accessibility optimizations based on system preferences
    func accessibilityOptimized() -> some View {
        self.modifier(AccessibilityOptimizationModifier())
    }

    /// Ensures minimum touch target size
    func accessibleTouchTarget(
        size: CGSize = AccessibilityHelpers.TouchTarget.recommended
    ) -> some View {
        self.frame(minWidth: size.width, minHeight: size.height)
    }

    /// Applies accessibility label, hint, and traits in one call
    func accessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isStaticText,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }

    /// Applies task-specific accessibility
    func taskAccessibility(
        title: String,
        isCompleted: Bool,
        priority: String? = nil,
        dueDate: String? = nil
    ) -> some View {
        let pattern = AccessibilityHelpers.Patterns.taskListItem(
            title: title,
            isCompleted: isCompleted,
            priority: priority,
            dueDate: dueDate
        )

        return self.accessibility(
            label: pattern.label,
            hint: pattern.hint,
            traits: pattern.traits
        )
    }

    /// Applies habit-specific accessibility
    func habitAccessibility(
        title: String,
        currentStreak: Int,
        isCompletedToday: Bool
    ) -> some View {
        let pattern = AccessibilityHelpers.Patterns.habitItem(
            title: title,
            currentStreak: currentStreak,
            isCompletedToday: isCompletedToday
        )

        return self.accessibility(
            label: pattern.label,
            hint: pattern.hint,
            traits: pattern.traits
        )
    }
}

// MARK: - Accessibility Optimization Modifier

struct AccessibilityOptimizationModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)  // Limit extreme scaling
            .accessibilityRespondsToUserInteraction()
            .modifier(MotionModifier())
            .modifier(ContrastModifier())
    }
}

struct MotionModifier: ViewModifier {

    func body(content: Content) -> some View {
        if AccessibilityHelpers.Preferences.prefersReducedMotion {
            content.animation(.none, value: UUID())
        } else {
            content
        }
    }
}

struct ContrastModifier: ViewModifier {

    func body(content: Content) -> some View {
        if AccessibilityHelpers.Preferences.prefersIncreasedContrast {
            content.foregroundStyle(.primary)
        } else {
            content
        }
    }
}