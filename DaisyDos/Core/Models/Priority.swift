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

    /// Default display color (used when AppearanceManager not available)
    var displayColor: Color {
        switch self {
        case .none: return .daisyTextSecondary
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    /// Returns the customized color from AppearanceManager
    func color(from appearanceManager: AppearanceManager) -> Color {
        switch self {
        case .none: return .daisyTextSecondary
        case .low: return appearanceManager.lowPriorityDisplayColor
        case .medium: return appearanceManager.mediumPriorityDisplayColor
        case .high: return appearanceManager.highPriorityDisplayColor
        }
    }

    var sfSymbol: String? {
        switch self {
        case .none: return nil
        case .low: return "triangle"
        case .medium: return "triangle.fill"
        case .high: return "exclamationmark.triangle.fill"
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
    func indicatorView(appearanceManager: AppearanceManager? = nil) -> some View {
        if let symbol = sfSymbol {
            Image(systemName: symbol)
                .foregroundColor(appearanceManager != nil ? color(from: appearanceManager!) : displayColor)
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

    // MARK: - Priority Sorting Utilities

    /// Sorted priorities from high to low for display purposes
    static let sortedByPriority: [Priority] = [.high, .medium, .low, .none]
}
