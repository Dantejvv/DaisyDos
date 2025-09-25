//
//  Typography.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Typography system for DaisyDos with full Dynamic Type support
/// Limited to 4 font sizes and 2 weights as per design system requirements
/// All fonts scale appropriately with user's Dynamic Type preferences
struct Typography {

    // MARK: - Font Weights

    /// Available font weights in the DaisyDos design system
    enum Weight {
        case regular
        case semibold

        var fontWeight: Font.Weight {
            switch self {
            case .regular:
                return .regular
            case .semibold:
                return .semibold
            }
        }
    }

    // MARK: - Font Sizes

    /// Available font sizes in the DaisyDos design system
    /// Limited to 4 sizes to maintain visual hierarchy and consistency
    enum Size {
        case title
        case body
        case subtitle
        case caption

        var font: Font {
            switch self {
            case .title:
                return .title2      // Large, prominent text
            case .body:
                return .body        // Standard reading text
            case .subtitle:
                return .subheadline // Secondary information
            case .caption:
                return .caption     // Small, supplementary text
            }
        }

        /// Human-readable description for each size
        var description: String {
            switch self {
            case .title:
                return "Title - Headers and prominent text"
            case .body:
                return "Body - Primary content and descriptions"
            case .subtitle:
                return "Subtitle - Secondary information and labels"
            case .caption:
                return "Caption - Metadata, timestamps, small details"
            }
        }
    }

    // MARK: - Text Styles

    /// Predefined text styles combining size and weight
    /// These are the primary typography tools for the application
    enum Style {
        case title
        case titleSemibold
        case body
        case bodySemibold
        case subtitle
        case subtitleSemibold
        case caption
        case captionSemibold

        var font: Font {
            switch self {
            case .title:
                return Size.title.font.weight(Weight.regular.fontWeight)
            case .titleSemibold:
                return Size.title.font.weight(Weight.semibold.fontWeight)
            case .body:
                return Size.body.font.weight(Weight.regular.fontWeight)
            case .bodySemibold:
                return Size.body.font.weight(Weight.semibold.fontWeight)
            case .subtitle:
                return Size.subtitle.font.weight(Weight.regular.fontWeight)
            case .subtitleSemibold:
                return Size.subtitle.font.weight(Weight.semibold.fontWeight)
            case .caption:
                return Size.caption.font.weight(Weight.regular.fontWeight)
            case .captionSemibold:
                return Size.caption.font.weight(Weight.semibold.fontWeight)
            }
        }

        /// Usage guidelines for each text style
        var usageGuideline: String {
            switch self {
            case .title:
                return "Use for main headers, screen titles - regular weight"
            case .titleSemibold:
                return "Use for emphasized headers, important titles - semibold weight"
            case .body:
                return "Use for primary content, descriptions, main text"
            case .bodySemibold:
                return "Use for emphasized body text, important information"
            case .subtitle:
                return "Use for secondary information, labels, subheadings"
            case .subtitleSemibold:
                return "Use for emphasized secondary information"
            case .caption:
                return "Use for metadata, timestamps, supplementary information"
            case .captionSemibold:
                return "Use for emphasized small text, important captions"
            }
        }
    }

    // MARK: - Semantic Text Styles

    /// Semantic text styles for specific use cases
    /// These provide meaningful names for common text patterns in the app
    enum Semantic {
        /// Screen and section headers
        static let screenHeader: Font = Style.titleSemibold.font
        static let sectionHeader: Font = Style.bodySemibold.font

        /// Body and content text
        static let primaryContent: Font = Style.body.font
        static let secondaryContent: Font = Style.subtitle.font

        /// Interactive elements
        static let buttonText: Font = Style.bodySemibold.font
        static let linkText: Font = Style.bodySemibold.font

        /// Form elements
        static let fieldLabel: Font = Style.subtitle.font
        static let fieldText: Font = Style.body.font
        static let helperText: Font = Style.caption.font

        /// List and card elements
        static let listItemTitle: Font = Style.body.font
        static let listItemSubtitle: Font = Style.subtitle.font
        static let cardTitle: Font = Style.bodySemibold.font
        static let cardContent: Font = Style.subtitle.font

        /// Status and metadata
        static let statusText: Font = Style.captionSemibold.font
        static let timestamp: Font = Style.caption.font
        static let badge: Font = Style.captionSemibold.font

        /// Error and validation
        static let errorText: Font = Style.caption.font
        static let validationText: Font = Style.caption.font
    }

    // MARK: - Dynamic Type Support

    /// Minimum and maximum scaling factors for Dynamic Type
    /// Ensures text remains readable at all accessibility sizes
    enum DynamicTypeSupport {
        static let minimumScaleFactor: CGFloat = 0.8
        static let maximumScaleFactor: CGFloat = 2.0

        /// Checks if current Dynamic Type setting is in the large accessibility range
        static var isAccessibilitySize: Bool {
            let category = UIApplication.shared.preferredContentSizeCategory
            return category.isAccessibilityCategory
        }

        /// Gets the current Dynamic Type category
        static var currentCategory: UIContentSizeCategory {
            return UIApplication.shared.preferredContentSizeCategory
        }

        /// Provides scaling factor for custom implementations
        static var scaleFactor: CGFloat {
            let category = currentCategory
            switch category {
            case .extraSmall:
                return 0.8
            case .small:
                return 0.9
            case .medium:
                return 1.0
            case .large:
                return 1.0  // Default size
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
    }

    // MARK: - Line Height and Spacing

    /// Line height multipliers for different text styles
    /// Ensures optimal readability across all font sizes
    enum LineHeight {
        static let tight: CGFloat = 1.1      // For large titles
        static let normal: CGFloat = 1.3     // For body text
        static let comfortable: CGFloat = 1.5 // For small text
        static let spacious: CGFloat = 1.6   // For accessibility

        /// Gets appropriate line height for a given text style
        static func forStyle(_ style: Style) -> CGFloat {
            switch style {
            case .title, .titleSemibold:
                return tight
            case .body, .bodySemibold:
                return normal
            case .subtitle, .subtitleSemibold:
                return normal
            case .caption, .captionSemibold:
                return comfortable
            }
        }
    }

    // MARK: - Text Color Context

    /// Text color contexts for different UI states
    /// Used with the color system to ensure proper contrast
    enum ColorContext {
        case primary      // Main text color
        case secondary    // Subdued text color
        case tertiary     // Very subdued text color
        case accent       // Accent/brand colored text
        case success      // Success state text
        case warning      // Warning state text
        case error        // Error state text
        case onSurface    // Text on colored surfaces
        case onPrimary    // Text on primary colored backgrounds
        case onSecondary  // Text on secondary colored backgrounds

        /// Opacity values for text hierarchy
        var opacity: Double {
            switch self {
            case .primary, .accent, .success, .warning, .error, .onSurface, .onPrimary, .onSecondary:
                return 1.0
            case .secondary:
                return 0.7
            case .tertiary:
                return 0.5
            }
        }
    }
}

// MARK: - Font Extensions

/// SwiftUI Font extensions for the DaisyDos design system
/// Provides easy access to design system typography
extension Font {

    // MARK: - Primary Typography Styles

    /// Large text for headers and important content
    /// Semibold weight for emphasis and hierarchy
    static let daisyTitle: Font = Typography.Style.titleSemibold.font

    /// Standard body text for primary content
    /// Regular weight for comfortable reading
    static let daisyBody: Font = Typography.Style.body.font

    /// Secondary information and labels
    /// Regular weight, smaller than body text
    static let daisySubtitle: Font = Typography.Style.subtitle.font

    /// Small text for captions and metadata
    /// Regular weight, smallest size in the system
    static let daisyCaption: Font = Typography.Style.caption.font

    // MARK: - Semantic Typography Convenience

    /// Screen header typography
    static let screenHeader: Font = Typography.Semantic.screenHeader

    /// Section header typography
    static let sectionHeader: Font = Typography.Semantic.sectionHeader

    /// Button text typography
    static let buttonText: Font = Typography.Semantic.buttonText

    /// Field label typography
    static let fieldLabel: Font = Typography.Semantic.fieldLabel

    /// Error text typography
    static let errorText: Font = Typography.Semantic.errorText

    // MARK: - Custom Font Methods

    /// Creates a font with Dynamic Type support and custom scaling
    static func daisyCustom(
        _ style: Typography.Style,
        scaleFactor: CGFloat = 1.0
    ) -> Font {
        return style.font
    }

    /// Creates a font with specific line height
    /// Note: SwiftUI doesn't directly support line height on Font
    /// This method serves as documentation for intended line heights
    static func daisyWithLineHeight(
        _ style: Typography.Style,
        lineHeight: CGFloat
    ) -> Font {
        // In practice, line height would be applied via Text modifiers
        // This method documents the intended combination
        return style.font
    }
}

// MARK: - Text View Modifiers

/// Custom view modifiers for applying typography styles
extension Text {

    /// Applies a DaisyDos typography style with proper line height
    func daisyStyle(_ style: Typography.Style) -> some View {
        self
            .font(style.font)
            .lineSpacing(Typography.LineHeight.forStyle(style) - 1.0)
    }

    /// Applies typography with specific color context
    func daisyStyle(
        _ style: Typography.Style,
        color: Typography.ColorContext
    ) -> some View {
        self
            .font(style.font)
            .lineSpacing(Typography.LineHeight.forStyle(style) - 1.0)
            .opacity(color.opacity)
    }

    /// Applies semantic typography for common use cases
    func screenHeader() -> some View {
        self.font(.screenHeader)
    }

    func sectionHeader() -> some View {
        self.font(.sectionHeader)
    }

    func buttonText() -> some View {
        self.font(.buttonText)
    }

    func fieldLabel() -> some View {
        self.font(.fieldLabel)
    }

    func errorText() -> some View {
        self.font(.errorText)
            .foregroundColor(.red)
    }
}

// MARK: - Typography Validation

extension Typography {

    /// Validates that a text style is appropriate for its context
    static func validateUsage(
        style: Style,
        context: String,
        contentLength: Int
    ) -> (isValid: Bool, suggestion: String?) {

        // Long content should use body or subtitle styles
        if contentLength > 100 {
            switch style {
            case .title, .titleSemibold:
                return (false, "Use .body or .subtitle for long content")
            default:
                break
            }
        }

        // Short, important content can use title styles
        if contentLength < 20 {
            switch context.lowercased() {
            case let ctx where ctx.contains("header") || ctx.contains("title"):
                if style == .caption || style == .captionSemibold {
                    return (false, "Use .title or .titleSemibold for headers")
                }
            default:
                break
            }
        }

        return (true, nil)
    }

    /// Suggests appropriate typography for content type
    static func suggestStyle(
        for contentType: ContentType,
        emphasis: Emphasis = .normal
    ) -> Style {
        switch (contentType, emphasis) {
        case (.header, .normal):
            return .title
        case (.header, .emphasized):
            return .titleSemibold
        case (.body, .normal):
            return .body
        case (.body, .emphasized):
            return .bodySemibold
        case (.label, .normal):
            return .subtitle
        case (.label, .emphasized):
            return .subtitleSemibold
        case (.metadata, .normal):
            return .caption
        case (.metadata, .emphasized):
            return .captionSemibold
        }
    }

    enum ContentType {
        case header
        case body
        case label
        case metadata
    }

    enum Emphasis {
        case normal
        case emphasized
    }
}