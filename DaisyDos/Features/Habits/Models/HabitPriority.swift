//
//  HabitPriority.swift
//  DaisyDos
//
//  Created by Claude Code on 10/1/25.
//

import Foundation
import SwiftUI

/// Priority levels for habits with visual indicators and accessibility support
/// Adapted from task priorities but with habit-specific semantics and symbols
enum HabitPriority: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    // MARK: - Visual Indicators

    /// Color representation for each priority level
    var color: Color {
        switch self {
        case .low:
            return Colors.Secondary.blue
        case .medium:
            return Colors.Secondary.teal
        case .high:
            return Colors.Accent.error
        }
    }

    /// SF Symbol for each priority level (habit-specific symbols)
    var sfSymbol: String {
        switch self {
        case .low:
            return "moon"
        case .medium:
            return "circle"
        case .high:
            return "exclamationmark.triangle"
        }
    }

    /// Filled SF Symbol variant for selected states
    var sfSymbolFilled: String {
        switch self {
        case .low:
            return "moon.fill"
        case .medium:
            return "circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        }
    }

    // MARK: - Display Properties

    /// User-friendly display name
    var displayName: String {
        switch self {
        case .low:
            return "Aspirational Habit"
        case .medium:
            return "Regular Habit"
        case .high:
            return "Core Habit"
        }
    }

    /// Short description for tooltips and hints
    var description: String {
        switch self {
        case .low:
            return "Aspirational habit - nice to have, bonus activity"
        case .medium:
            return "Regular habit - standard daily routine"
        case .high:
            return "Core habit - essential daily practice, non-negotiable"
        }
    }

    /// Short name for compact display
    var shortName: String {
        switch self {
        case .low:
            return "Aspirational"
        case .medium:
            return "Regular"
        case .high:
            return "Core"
        }
    }

    /// Symbol as text for segmented control
    var symbolText: String {
        switch self {
        case .low:
            return "🌙"  // Moon emoji
        case .medium:
            return "⚫"  // Medium black circle
        case .high:
            return "💎"  // Diamond emoji
        }
    }

    // MARK: - Sorting and Filtering

    /// Numeric value for sorting (higher number = higher priority)
    var sortOrder: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        }
    }

    /// All priorities sorted from highest to lowest
    static var sortedByPriority: [HabitPriority] {
        return [.high, .medium, .low]
    }

    /// All priorities sorted from lowest to highest
    static var sortedByPriorityAscending: [HabitPriority] {
        return [.low, .medium, .high]
    }

    // MARK: - Accessibility

    /// VoiceOver label for accessibility
    var accessibilityLabel: String {
        switch self {
        case .low:
            return "Aspirational habit"
        case .medium:
            return "Regular habit"
        case .high:
            return "Core habit"
        }
    }

    /// VoiceOver hint for accessibility
    var accessibilityHint: String {
        switch self {
        case .low:
            return "This is an aspirational habit - nice to have when you have extra time"
        case .medium:
            return "This is a regular habit - part of your standard daily routine"
        case .high:
            return "This is a core habit - an essential daily practice that's non-negotiable"
        }
    }

    // MARK: - Default Values

    /// Default priority for new habits
    static let `default`: HabitPriority = .medium
}

// MARK: - Comparable Conformance

extension HabitPriority: Comparable {
    static func < (lhs: HabitPriority, rhs: HabitPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - SwiftUI Integration

extension HabitPriority {

    /// Creates a priority indicator view with icon and color
    @ViewBuilder
    func indicatorView(filled: Bool = false) -> some View {
        Image(systemName: filled ? sfSymbolFilled : sfSymbol)
            .foregroundColor(color)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
    }

    /// Creates a priority badge with background color
    @ViewBuilder
    func badgeView() -> some View {
        HStack(spacing: Spacing.extraSmall) {
            indicatorView(filled: true)
                .font(.caption2)

            Text(rawValue)
                .font(.daisyCaption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.extraSmall)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Filtering Helpers

extension HabitPriority {

    /// Filters habits by priority level
    static func filter<T: Collection>(_ items: T, by priority: HabitPriority) -> [T.Element] where T.Element: HabitPriorityProvider {
        return items.filter { $0.priority == priority }
    }

    /// Groups habits by priority level
    static func group<T: Collection>(_ items: T) -> [HabitPriority: [T.Element]] where T.Element: HabitPriorityProvider {
        return Dictionary(grouping: items) { $0.priority }
    }
}

// MARK: - Habit Priority Provider Protocol

/// Protocol for types that have a habit priority property
protocol HabitPriorityProvider {
    var priority: HabitPriority { get }
}

// MARK: - Preview Helpers

#if DEBUG
struct HabitPriority_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.medium) {
            Text("Habit Priority Indicators")
                .font(.daisyTitle)

            VStack(spacing: Spacing.small) {
                ForEach(HabitPriority.allCases) { priority in
                    HStack {
                        priority.indicatorView()
                        Text(priority.displayName)
                            .font(.daisyBody)
                        Spacer()
                        priority.indicatorView(filled: true)
                    }
                }
            }

            Text("Habit Priority Badges")
                .font(.daisyTitle)
                .padding(.top)

            VStack(spacing: Spacing.small) {
                ForEach(HabitPriority.allCases) { priority in
                    priority.badgeView()
                }
            }
        }
        .padding()
        .background(Colors.Primary.background)
    }
}
#endif