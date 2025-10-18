//
//  Priority.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Unified priority model for both Tasks and Habits
//  Replaces separate Priority and HabitPriority enums
//

import SwiftUI

/// Priority level for tasks and habits
/// Supports visual indicators, colors, and sorting
enum Priority: String, Codable, CaseIterable, Comparable, Sendable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    // MARK: - Display Properties

    var displayColor: Color {
        switch self {
        case .none: return .daisyTextSecondary
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    var sfSymbol: String? {
        switch self {
        case .none: return nil
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark.2"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .none: return "No priority"
        case .low: return "Low priority"
        case .medium: return "Medium priority"
        case .high: return "High priority"
        }
    }

    // MARK: - Visual Indicator

    @ViewBuilder
    func indicatorView() -> some View {
        if let symbol = sfSymbol {
            Image(systemName: symbol)
                .foregroundColor(displayColor)
                .font(.caption)
        }
    }

    // MARK: - Comparable Conformance

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        let order: [Priority] = [.none, .low, .medium, .high]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }

    // MARK: - Display Name

    var displayName: String {
        return rawValue
    }

    // MARK: - Sort Order

    var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case .none: return 0
        }
    }

    // MARK: - Priority Sorting & Grouping Utilities

    /// Sorted priorities from high to low for display purposes
    static let sortedByPriority: [Priority] = [.high, .medium, .low, .none]

    /// Group items by priority level
    static func group<T: PriorityProvider>(_ items: [T]) -> [Priority: [T]] {
        return Dictionary(grouping: items) { $0.priority }
    }
}

// MARK: - PriorityProvider Protocol

/// Protocol for objects that have a priority property
protocol PriorityProvider {
    var priority: Priority { get }
}
