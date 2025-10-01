//
//  DesignSystem.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Main design system for DaisyDos application
/// Provides centralized access to all design tokens, constants, and utilities
/// Following Apple's Human Interface Guidelines and WCAG AA accessibility standards
struct DesignSystem {

    // MARK: - Design System Access

    /// Centralized access to spacing constants
    static let spacing = Spacing.self

    /// Centralized access to typography styles
    static let typography = Typography.self

    /// Centralized access to color palette
    static let colors = Colors.self

    /// Centralized access to accessibility helpers
    static let accessibility = AccessibilityHelpers.self

    /// Centralized access to input validation utilities
    static let inputValidation = InputValidation.self

    // MARK: - Design Principles

    /// Design principles that guide all visual decisions in DaisyDos
    enum Principles {

        /// 8pt Grid System
        /// All spacing, sizing, and positioning should follow multiples of 8pt
        /// This ensures consistent visual rhythm and alignment across all platforms
        static let gridUnit: CGFloat = 8

        /// Liquid Glass Aesthetic
        /// Visual design language emphasizing:
        /// - Subtle transparency and blur effects
        /// - Soft shadows and rounded corners
        /// - Gentle gradients and materials
        /// - Smooth animations and transitions
        static let cornerRadius: CGFloat = 16
        static let shadowRadius: CGFloat = 8
        static let blurRadius: CGFloat = 20

        /// 60-30-10 Color Rule
        /// - 60%: Primary/neutral colors (backgrounds, surfaces)
        /// - 30%: Secondary colors (accents, highlights)
        /// - 10%: Accent colors (CTAs, important elements)
        static let primaryColorWeight = 0.6
        static let secondaryColorWeight = 0.3
        static let accentColorWeight = 0.1

        /// Accessibility First
        /// All design decisions prioritize accessibility compliance
        /// - WCAG AA contrast ratios (4.5:1 normal, 3:1 large text)
        /// - 44pt minimum touch targets
        /// - Full Dynamic Type support
        /// - VoiceOver navigation optimization
        static let minimumTouchTarget: CGFloat = 44
        static let recommendedTouchTarget: CGFloat = 48
        static let minimumContrastRatio: Double = 4.5
        static let largeTextContrastRatio: Double = 3.0
    }

    // MARK: - Design Tokens

    /// Common design token values used throughout the application
    enum Tokens {

        /// Animation durations for consistent motion design
        enum Animation {
            static let fast: TimeInterval = 0.2
            static let normal: TimeInterval = 0.3
            static let slow: TimeInterval = 0.5
            static let extraSlow: TimeInterval = 0.8
        }

        /// Opacity values for consistent transparency levels
        enum Opacity {
            static let disabled: Double = 0.3
            static let secondary: Double = 0.6
            static let primary: Double = 0.8
            static let full: Double = 1.0
        }

        /// Border width constants
        enum BorderWidth {
            static let thin: CGFloat = 1
            static let medium: CGFloat = 2
            static let thick: CGFloat = 4
        }

        /// Icon sizes following 8pt grid
        enum IconSize {
            static let small: CGFloat = 16   // 2 × 8pt
            static let medium: CGFloat = 24  // 3 × 8pt
            static let large: CGFloat = 32   // 4 × 8pt
            static let extraLarge: CGFloat = 48 // 6 × 8pt
        }
    }

    // MARK: - Layout Constants

    /// Standard layout values used throughout the application
    enum Layout {

        /// Content margins and padding
        enum ContentPadding {
            static let small = Spacing.small
            static let medium = Spacing.medium
            static let large = Spacing.large
        }

        /// Component heights following 8pt grid
        enum ComponentHeight {
            static let button = Spacing.touchTarget       // 48pt
            static let textField = Spacing.touchTarget    // 48pt
            static let listRow = Spacing.extraLarge      // 64pt
            static let cardMinimum = Spacing.huge        // 80pt
        }

        /// Screen margins for different device classes
        enum ScreenMargin {
            static let compact: CGFloat = 16    // iPhone in portrait
            static let regular: CGFloat = 24    // iPhone in landscape, iPad
            static let large: CGFloat = 32      // iPad in landscape
        }
    }

    // MARK: - Usage Guidelines

    /// Guidelines for implementing the design system correctly
    enum Guidelines {

        /// Typography usage guidelines
        static let typographyGuidelines = """
        Typography Usage:
        - .daisyTitle: Use for screen headers, section titles
        - .daisyBody: Use for primary content, descriptions
        - .daisySubtitle: Use for secondary information, labels
        - .daisyCaption: Use for metadata, timestamps, small details

        Always test with Dynamic Type at all sizes (xSmall to xxxLarge)
        """

        /// Spacing usage guidelines
        static let spacingGuidelines = """
        Spacing Usage:
        - Use semantic names (.small, .medium, .large) over raw values
        - Follow 8pt grid for all measurements
        - Consistent spacing creates visual hierarchy
        - More space = more importance
        """

        /// Color usage guidelines
        static let colorGuidelines = """
        Color Usage:
        - Use semantic color names, not raw hex values
        - Test in both light and dark mode
        - Verify WCAG AA contrast ratios
        - Primary colors for backgrounds and surfaces
        - Secondary colors for accents and highlights
        - Accent colors sparingly for CTAs and important elements
        """

        /// Accessibility guidelines
        static let accessibilityGuidelines = """
        Accessibility Requirements:
        - Minimum 44pt touch targets (use Spacing.touchTarget)
        - WCAG AA contrast ratios (4.5:1 normal, 3:1 large text)
        - Meaningful accessibility labels and hints
        - Full Dynamic Type support
        - VoiceOver navigation testing required
        """
    }
}

// MARK: - Design System Extensions

extension DesignSystem {

    /// Quick access to commonly used values
    static var grid: CGFloat { Principles.gridUnit }
    static var cornerRadius: CGFloat { Principles.cornerRadius }
    static var shadowRadius: CGFloat { Principles.shadowRadius }
    static var touchTarget: CGFloat { Principles.recommendedTouchTarget }

    /// Environment-aware values that adapt to device and context
    static func adaptiveMargin(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch sizeClass {
        case .compact:
            return Layout.ScreenMargin.compact
        case .regular:
            return Layout.ScreenMargin.regular
        default:
            return Layout.ScreenMargin.compact
        }
    }
}