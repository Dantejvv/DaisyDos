//
//  Priority.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation
import SwiftUI

/// Priority levels for tasks with visual indicators and accessibility support
/// Follows the roadmap specification for None, Low, Medium, High priority system
enum Priority: String, CaseIterable, Codable, Identifiable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    // MARK: - Visual Indicators

    /// Color representation for each priority level
    var color: Color {
        switch self {
        case .none:
            return Colors.Primary.text.opacity(0.3)
        case .low:
            return Colors.Secondary.blue
        case .medium:
            return Colors.Secondary.teal
        case .high:
            return Colors.Accent.error
        }
    }

    /// SF Symbol for each priority level (none has no symbol)
    var sfSymbol: String? {
        switch self {
        case .none:
            return nil
        case .low:
            return "moon"
        case .medium:
            return "circle"
        case .high:
            return "exclamationmark.triangle"
        }
    }

    /// Filled SF Symbol variant for selected states (none has no symbol)
    var sfSymbolFilled: String? {
        switch self {
        case .none:
            return nil
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
        case .none:
            return "No Priority"
        case .low:
            return "Low Priority"
        case .medium:
            return "Medium Priority"
        case .high:
            return "High Priority"
        }
    }

    /// Short description for tooltips and hints
    var description: String {
        switch self {
        case .none:
            return "No priority set - general task"
        case .low:
            return "Low priority - can be done when time allows"
        case .medium:
            return "Medium priority - should be completed reasonably soon"
        case .high:
            return "High priority - needs immediate attention"
        }
    }

    /// Short name for compact display
    var shortName: String {
        switch self {
        case .none:
            return "None"
        case .low:
            return "Low"
        case .medium:
            return "Med"
        case .high:
            return "High"
        }
    }

    /// Symbol as text for segmented control
    var symbolText: String {
        switch self {
        case .none:
            return "—"  // Em dash
        case .low:
            return "🌙"  // Moon emoji
        case .medium:
            return "⚫"  // Medium black circle
        case .high:
            return "❗"  // Exclamation mark
        }
    }

    // MARK: - Sorting and Filtering

    /// Numeric value for sorting (higher number = higher priority)
    var sortOrder: Int {
        switch self {
        case .none:
            return 0
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        }
    }

    /// All priorities sorted from highest to lowest
    static var sortedByPriority: [Priority] {
        return [.high, .medium, .low, .none]
    }

    /// All priorities sorted from lowest to highest
    static var sortedByPriorityAscending: [Priority] {
        return [.none, .low, .medium, .high]
    }

    // MARK: - Accessibility

    /// VoiceOver label for accessibility
    var accessibilityLabel: String {
        switch self {
        case .none:
            return "No priority task"
        case .low:
            return "Low priority task"
        case .medium:
            return "Medium priority task"
        case .high:
            return "High priority task"
        }
    }

    /// VoiceOver hint for accessibility
    var accessibilityHint: String {
        switch self {
        case .none:
            return "This task has no priority set"
        case .low:
            return "This task has low priority and can be completed when time allows"
        case .medium:
            return "This task has medium priority and should be completed reasonably soon"
        case .high:
            return "This task has high priority and needs immediate attention"
        }
    }

    // MARK: - Default Values

    /// Default priority for new tasks
    static let `default`: Priority = .none
}

// MARK: - Comparable Conformance

extension Priority: Comparable {
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - SwiftUI Integration

extension Priority {

    /// Creates a priority indicator view with icon and color (none priority shows nothing)
    @ViewBuilder
    func indicatorView(filled: Bool = false) -> some View {
        if let symbol = filled ? sfSymbolFilled : sfSymbol {
            Image(systemName: symbol)
                .foregroundColor(color)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint)
        }
    }

    /// Creates a priority badge with background color
    @ViewBuilder
    func badgeView() -> some View {
        HStack(spacing: Spacing.extraSmall) {
            if sfSymbolFilled != nil {
                indicatorView(filled: true)
                    .font(.caption2)
            }

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

extension Priority {

    /// Filters tasks by priority level
    static func filter<T: Collection>(_ items: T, by priority: Priority) -> [T.Element] where T.Element: TaskPriorityProvider {
        return items.filter { $0.priority == priority }
    }

    /// Groups tasks by priority level
    static func group<T: Collection>(_ items: T) -> [Priority: [T.Element]] where T.Element: TaskPriorityProvider {
        return Dictionary(grouping: items) { $0.priority }
    }
}

// MARK: - Task Priority Provider Protocol

/// Protocol for types that have a priority property
protocol TaskPriorityProvider {
    var priority: Priority { get }
}

// MARK: - Preview Helpers

#if DEBUG
struct Priority_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.medium) {
            Text("Priority Indicators")
                .font(.daisyTitle)

            VStack(spacing: Spacing.small) {
                ForEach(Priority.allCases) { priority in
                    HStack {
                        priority.indicatorView()
                        Text(priority.displayName)
                            .font(.daisyBody)
                        Spacer()
                        priority.indicatorView(filled: true)
                    }
                }
            }

            Text("Priority Badges")
                .font(.daisyTitle)
                .padding(.top)

            VStack(spacing: Spacing.small) {
                ForEach(Priority.allCases) { priority in
                    priority.badgeView()
                }
            }
        }
        .padding()
        .background(Colors.Primary.background)
    }
}
#endif