//
//  AppearanceManager.swift
//  DaisyDos
//
//  Created by Claude Code on 11/12/25.
//

import Foundation
import SwiftUI

@Observable
class AppearanceManager {

    // MARK: - Recent Colors Manager

    let recentColorsManager = RecentColorsManager()

    // MARK: - Theme Management

    /// User's preferred color scheme (system, light, or dark)
    var preferredColorScheme: ColorSchemePreference {
        didSet {
            UserDefaults.standard.set(preferredColorScheme.rawValue, forKey: "preferredColorScheme")
        }
    }

    /// User's selected accent color
    var accentColor: AccentColorOption {
        didSet {
            UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor")
            recentColorsManager.recordColor(accentColor, for: .accent)
            // Clear custom color when preset is selected
            clearCustomAccentColor()
        }
    }

    /// User's custom accent color (takes precedence over accentColor if set)
    var customAccentColor: Color? {
        didSet {
            saveCustomAccentColor(customAccentColor)
        }
    }

    // MARK: - Priority Colors

    /// Whether to show priority-based background colors on rows
    var showPriorityBackgrounds: Bool {
        didSet {
            UserDefaults.standard.set(showPriorityBackgrounds, forKey: "showPriorityBackgrounds")
        }
    }

    /// User's selected color for high priority
    var highPriorityColor: AccentColorOption {
        didSet {
            UserDefaults.standard.set(highPriorityColor.rawValue, forKey: "highPriorityColor")
            recentColorsManager.recordColor(highPriorityColor, for: .highPriority)
        }
    }

    /// User's selected color for medium priority
    var mediumPriorityColor: AccentColorOption {
        didSet {
            UserDefaults.standard.set(mediumPriorityColor.rawValue, forKey: "mediumPriorityColor")
            recentColorsManager.recordColor(mediumPriorityColor, for: .mediumPriority)
        }
    }

    /// User's selected color for low priority
    var lowPriorityColor: AccentColorOption {
        didSet {
            UserDefaults.standard.set(lowPriorityColor.rawValue, forKey: "lowPriorityColor")
            recentColorsManager.recordColor(lowPriorityColor, for: .lowPriority)
        }
    }

    // MARK: - Initialization

    init() {
        // Load from UserDefaults
        let schemeRawValue = UserDefaults.standard.string(forKey: "preferredColorScheme") ?? "system"
        self.preferredColorScheme = ColorSchemePreference(rawValue: schemeRawValue) ?? .system

        let colorRawValue = UserDefaults.standard.string(forKey: "accentColor") ?? "blue"
        self.accentColor = AccentColorOption(rawValue: colorRawValue) ?? .blue

        // Load priority background toggle (default to true for existing behavior)
        self.showPriorityBackgrounds = UserDefaults.standard.object(forKey: "showPriorityBackgrounds") as? Bool ?? true

        // Load priority colors
        let highRaw = UserDefaults.standard.string(forKey: "highPriorityColor") ?? "red"
        self.highPriorityColor = AccentColorOption(rawValue: highRaw) ?? .red

        let mediumRaw = UserDefaults.standard.string(forKey: "mediumPriorityColor") ?? "orange"
        self.mediumPriorityColor = AccentColorOption(rawValue: mediumRaw) ?? .orange

        let lowRaw = UserDefaults.standard.string(forKey: "lowPriorityColor") ?? "blue"
        self.lowPriorityColor = AccentColorOption(rawValue: lowRaw) ?? .blue

        // Load custom accent color
        self.customAccentColor = loadCustomAccentColor()
    }

    // MARK: - Types

    enum ColorSchemePreference: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }

        /// Converts to SwiftUI ColorScheme for use in preferredColorScheme modifier
        var swiftUIColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    enum AccentColorOption: String, CaseIterable, Identifiable {
        case none = "none"
        case blue = "blue"
        case purple = "purple"
        case teal = "teal"
        case green = "green"
        case orange = "orange"
        case pink = "pink"
        case red = "red"
        case indigo = "indigo"
        case cyan = "cyan"
        case mint = "mint"
        case yellow = "yellow"
        case brown = "brown"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "None"
            case .blue: return "Blue"
            case .purple: return "Purple"
            case .teal: return "Teal"
            case .green: return "Green"
            case .orange: return "Orange"
            case .pink: return "Pink"
            case .red: return "Red"
            case .indigo: return "Indigo"
            case .cyan: return "Cyan"
            case .mint: return "Mint"
            case .yellow: return "Yellow"
            case .brown: return "Brown"
            }
        }

        /// Returns the SwiftUI Color for this accent
        var color: Color {
            switch self {
            case .none: return .daisyTextSecondary
            case .blue: return Colors.Secondary.blue
            case .purple: return Colors.Secondary.purple
            case .teal: return Colors.Secondary.teal
            case .green: return .green
            case .orange: return Colors.Accent.warning
            case .pink: return .pink
            case .red: return Colors.Accent.error
            case .indigo: return .indigo
            case .cyan: return .cyan
            case .mint: return .mint
            case .yellow: return .yellow
            case .brown: return .brown
            }
        }
    }

    // MARK: - Computed Properties

    /// Returns the current SwiftUI ColorScheme preference
    var currentColorScheme: ColorScheme? {
        preferredColorScheme.swiftUIColorScheme
    }

    /// Returns the current accent Color (custom color if set, otherwise preset)
    var currentAccentColor: Color {
        customAccentColor ?? accentColor.color
    }

    /// Returns the color for high priority
    var highPriorityDisplayColor: Color {
        highPriorityColor.color
    }

    /// Returns the color for medium priority
    var mediumPriorityDisplayColor: Color {
        mediumPriorityColor.color
    }

    /// Returns the color for low priority
    var lowPriorityDisplayColor: Color {
        lowPriorityColor.color
    }

    // MARK: - Custom Color Persistence

    /// UserDefaults keys for custom color storage
    private enum UserDefaultsKeys {
        static let customAccentColorRed = "customAccentColorRed"
        static let customAccentColorGreen = "customAccentColorGreen"
        static let customAccentColorBlue = "customAccentColorBlue"
        static let hasCustomAccentColor = "hasCustomAccentColor"
    }

    /// Saves a custom color to UserDefaults as RGB components
    private func saveCustomAccentColor(_ color: Color?) {
        guard let color = color else {
            // Clear custom color
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCustomAccentColor)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.customAccentColorRed)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.customAccentColorGreen)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.customAccentColorBlue)
            return
        }

        // Extract RGB components from UIColor
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Save components
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCustomAccentColor)
        UserDefaults.standard.set(Double(red), forKey: UserDefaultsKeys.customAccentColorRed)
        UserDefaults.standard.set(Double(green), forKey: UserDefaultsKeys.customAccentColorGreen)
        UserDefaults.standard.set(Double(blue), forKey: UserDefaultsKeys.customAccentColorBlue)
    }

    /// Loads a custom color from UserDefaults RGB components
    private func loadCustomAccentColor() -> Color? {
        guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCustomAccentColor) else {
            return nil
        }

        let red = UserDefaults.standard.double(forKey: UserDefaultsKeys.customAccentColorRed)
        let green = UserDefaults.standard.double(forKey: UserDefaultsKeys.customAccentColorGreen)
        let blue = UserDefaults.standard.double(forKey: UserDefaultsKeys.customAccentColorBlue)

        return Color(red: red, green: green, blue: blue)
    }

    /// Clears the custom accent color
    func clearCustomAccentColor() {
        customAccentColor = nil
    }
}
