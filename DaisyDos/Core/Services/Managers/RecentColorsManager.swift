//
//  RecentColorsManager.swift
//  DaisyDos
//
//  Created by Claude Code on 11/26/25.
//

import Foundation

/// Manages recently used colors for quick access
/// Tracks last 5 colors per category (accent, high priority, medium priority, low priority)
@Observable
class RecentColorsManager {

    // MARK: - Color Categories

    enum ColorCategory: String {
        case accent = "recentAccentColors"
        case highPriority = "recentHighPriorityColors"
        case mediumPriority = "recentMediumPriorityColors"
        case lowPriority = "recentLowPriorityColors"
    }

    // MARK: - Constants

    private static let maxRecentColors = 5

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Records a color as recently used for a specific category
    /// - Parameters:
    ///   - color: The color option to record
    ///   - category: The category this color belongs to
    func recordColor(_ color: AppearanceManager.AccentColorOption, for category: ColorCategory) {
        var recent = getRecentColors(for: category)

        // Remove if already exists (will be re-added at front)
        recent.removeAll { $0 == color.rawValue }

        // Add to front
        recent.insert(color.rawValue, at: 0)

        // Limit to max count
        if recent.count > Self.maxRecentColors {
            recent = Array(recent.prefix(Self.maxRecentColors))
        }

        // Save
        UserDefaults.standard.set(recent, forKey: category.rawValue)
    }

    /// Gets recent colors for a specific category
    /// - Parameter category: The category to get colors for
    /// - Returns: Array of recently used color options (up to 5)
    func getRecentColors(for category: ColorCategory) -> [String] {
        UserDefaults.standard.stringArray(forKey: category.rawValue) ?? []
    }

    /// Gets recent colors as AccentColorOption enum values
    /// - Parameter category: The category to get colors for
    /// - Returns: Array of AccentColorOption values
    func getRecentColorOptions(for category: ColorCategory) -> [AppearanceManager.AccentColorOption] {
        getRecentColors(for: category).compactMap { rawValue in
            AppearanceManager.AccentColorOption(rawValue: rawValue)
        }
    }

    /// Clears all recent colors for a specific category
    /// - Parameter category: The category to clear
    func clearRecentColors(for category: ColorCategory) {
        UserDefaults.standard.removeObject(forKey: category.rawValue)
    }

    /// Clears all recent colors for all categories
    func clearAllRecentColors() {
        ColorCategory.allCases.forEach { category in
            clearRecentColors(for: category)
        }
    }
}

// MARK: - ColorCategory Extensions

extension RecentColorsManager.ColorCategory: CaseIterable {}
