//
//  Spacing.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// 8pt Grid Spacing System for DaisyDos
/// All spacing values follow Apple's recommended 8pt grid system
/// This ensures consistent visual rhythm and alignment across all platforms
struct Spacing {

    // MARK: - Base Grid Unit

    /// Base unit for the 8pt grid system
    /// All spacing values are multiples of this base unit
    private static let baseUnit: CGFloat = 8

    // MARK: - Core Spacing Values

    /// Extra small spacing: 8pt (1 × base unit)
    /// Usage: Internal component padding, tight element spacing
    static let extraSmall: CGFloat = baseUnit * 1  // 8pt

    /// Small spacing: 16pt (2 × base unit)
    /// Usage: Related element spacing, compact layouts
    static let small: CGFloat = baseUnit * 2       // 16pt

    /// Medium spacing: 24pt (3 × base unit)
    /// Usage: Standard element spacing, comfortable layouts
    static let medium: CGFloat = baseUnit * 3      // 24pt

    /// Large spacing: 32pt (4 × base unit)
    /// Usage: Section separation, generous layouts
    static let large: CGFloat = baseUnit * 4       // 32pt

    /// Extra large spacing: 40pt (5 × base unit)
    /// Usage: Major section breaks, screen padding
    static let extraLarge: CGFloat = baseUnit * 5  // 40pt

    /// Huge spacing: 48pt (6 × base unit)
    /// Usage: Screen margins, major visual breaks
    static let huge: CGFloat = baseUnit * 6        // 48pt

    /// Gigantic spacing: 64pt (8 × base unit)
    /// Usage: Maximum spacing for special cases
    static let gigantic: CGFloat = baseUnit * 8    // 64pt

    // MARK: - Semantic Spacing

    /// Touch target size following iOS Human Interface Guidelines
    /// Minimum recommended interactive element size: 44pt
    /// DaisyDos standard: 48pt for comfortable interaction
    static let touchTarget: CGFloat = huge         // 48pt

    /// Minimum touch target as per iOS HIG
    /// Use only when space is extremely constrained
    static let minimumTouchTarget: CGFloat = baseUnit * 5.5  // 44pt

    /// Screen edge margins for different contexts
    static let screenMargin: CGFloat = medium      // 24pt
    static let compactScreenMargin: CGFloat = small // 16pt
    static let generousScreenMargin: CGFloat = large // 32pt

    /// Component internal padding
    static let componentPadding: CGFloat = small   // 16pt
    static let tightComponentPadding: CGFloat = extraSmall // 8pt
    static let generousComponentPadding: CGFloat = medium  // 24pt

    // MARK: - Layout Spacing

    /// Content spacing for different layout contexts
    enum ContentSpacing {
        /// Tight spacing for dense information
        static let tight = Spacing.extraSmall      // 8pt

        /// Comfortable spacing for readable content
        static let comfortable = Spacing.small     // 16pt

        /// Generous spacing for emphasis and clarity
        static let generous = Spacing.medium       // 24pt

        /// Spacious layout for premium feel
        static let spacious = Spacing.large        // 32pt
    }

    /// List and collection spacing
    enum ListSpacing {
        /// Tight list items (compact information)
        static let compact = Spacing.extraSmall    // 8pt

        /// Standard list items (most common)
        static let standard = Spacing.small        // 16pt

        /// Comfortable list items (more readable)
        static let comfortable = Spacing.medium    // 24pt

        /// Spacious list items (premium feel)
        static let spacious = Spacing.large        // 32pt
    }

    /// Card and container spacing
    enum CardSpacing {
        /// Internal card padding
        static let internalPadding = Spacing.medium  // 24pt

        /// Tight internal padding for dense cards
        static let tightInternalPadding = Spacing.small // 16pt

        /// External card margins
        static let externalMargin = Spacing.small    // 16pt

        /// Space between stacked cards
        static let cardGap = Spacing.small           // 16pt

        /// Space between card sections
        static let sectionGap = Spacing.medium       // 24pt
    }

    // MARK: - Responsive Spacing

    /// Environment-aware spacing that adapts to device size
    static func adaptive(
        compact: CGFloat = small,
        regular: CGFloat = medium,
        large: CGFloat = large
    ) -> CGFloat {
        // In a real implementation, this would check the current environment
        // For now, return the regular size as default
        return regular
    }

    /// Responsive margin based on device size class
    static func responsiveMargin(
        for horizontalSizeClass: UserInterfaceSizeClass? = nil
    ) -> CGFloat {
        switch horizontalSizeClass {
        case .compact:
            return compactScreenMargin  // 16pt
        case .regular:
            return generousScreenMargin // 32pt
        default:
            return screenMargin         // 24pt
        }
    }
}

// MARK: - SwiftUI Extensions

extension Spacing {

    /// Edge insets for common spacing patterns
    enum EdgeInsets {
        /// Standard content insets
        static let content = SwiftUI.EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.medium,
            bottom: Spacing.medium,
            trailing: Spacing.medium
        )

        /// Tight content insets
        static let tight = SwiftUI.EdgeInsets(
            top: Spacing.small,
            leading: Spacing.small,
            bottom: Spacing.small,
            trailing: Spacing.small
        )

        /// Generous content insets
        static let generous = SwiftUI.EdgeInsets(
            top: Spacing.large,
            leading: Spacing.large,
            bottom: Spacing.large,
            trailing: Spacing.large
        )

        /// Screen margin insets
        static let screen = SwiftUI.EdgeInsets(
            top: Spacing.screenMargin,
            leading: Spacing.screenMargin,
            bottom: Spacing.screenMargin,
            trailing: Spacing.screenMargin
        )
    }

    /// Common padding values as EdgeInsets
    enum Padding {
        static let extraSmall = SwiftUI.EdgeInsets(
            top: Spacing.extraSmall,
            leading: Spacing.extraSmall,
            bottom: Spacing.extraSmall,
            trailing: Spacing.extraSmall
        )

        static let small = SwiftUI.EdgeInsets(
            top: Spacing.small,
            leading: Spacing.small,
            bottom: Spacing.small,
            trailing: Spacing.small
        )

        static let medium = SwiftUI.EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.medium,
            bottom: Spacing.medium,
            trailing: Spacing.medium
        )

        static let large = SwiftUI.EdgeInsets(
            top: Spacing.large,
            leading: Spacing.large,
            bottom: Spacing.large,
            trailing: Spacing.large
        )
    }
}

// MARK: - Validation Helpers

extension Spacing {

    /// Validates that a spacing value follows the 8pt grid
    /// Returns the closest valid spacing value if input doesn't conform
    static func validateGridAlignment(_ value: CGFloat) -> CGFloat {
        let remainder = value.truncatingRemainder(dividingBy: baseUnit)
        if remainder == 0 {
            return value  // Already aligned
        }

        // Round to nearest grid unit
        let quotient = value / baseUnit
        let roundedQuotient = round(quotient)
        return roundedQuotient * baseUnit
    }

    /// Suggests the appropriate spacing for a given context
    static func suggestSpacing(for context: SpacingContext) -> CGFloat {
        switch context {
        case .componentInternal:
            return componentPadding
        case .relatedElements:
            return small
        case .sectionBreak:
            return medium
        case .majorSeparation:
            return large
        case .screenMargin:
            return screenMargin
        case .touchTarget:
            return touchTarget
        }
    }

    /// Spacing context enumeration for suggestions
    enum SpacingContext {
        case componentInternal
        case relatedElements
        case sectionBreak
        case majorSeparation
        case screenMargin
        case touchTarget
    }
}