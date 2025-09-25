//
//  LiquidGlassModifiers.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Liquid Glass design language modifiers for DaisyDos
/// Creates a cohesive visual language with subtle transparency, blur effects,
/// soft shadows, and smooth animations throughout the application
struct LiquidGlassModifiers {

    // MARK: - Design Language Principles

    /// Core visual characteristics of the Liquid Glass aesthetic
    enum Characteristics {
        /// Subtle transparency levels for layering
        static let subtleOpacity: Double = 0.95
        static let mediumOpacity: Double = 0.85
        static let strongOpacity: Double = 0.75

        /// Blur and material effects
        static let subtleBlur: CGFloat = 10
        static let mediumBlur: CGFloat = 20
        static let strongBlur: CGFloat = 30

        /// Shadow parameters
        static let shadowRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowOpacity: Double = 0.1

        /// Corner radius for different elements
        static let buttonRadius: CGFloat = 12
        static let cardRadius: CGFloat = 16
        static let containerRadius: CGFloat = 20
        static let screenRadius: CGFloat = 24

        /// Animation timing
        static let quickAnimation: TimeInterval = 0.2
        static let standardAnimation: TimeInterval = 0.3
        static let smoothAnimation: TimeInterval = 0.5
    }
}

// MARK: - Liquid Card Modifier

/// Primary card style for content containers
struct LiquidCardModifier: ViewModifier {

    let elevation: Int
    let interactive: Bool

    init(elevation: Int = 1, interactive: Bool = false) {
        self.elevation = elevation
        self.interactive = interactive
    }

    func body(content: Content) -> some View {
        content
            .background(liquidCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.cardRadius))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
            .scaleEffect(interactive ? 0.98 : 1.0)
            .animation(
                .easeInOut(duration: LiquidGlassModifiers.Characteristics.quickAnimation),
                value: interactive
            )
    }

    private var liquidCardBackground: some View {
        RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.cardRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.cardRadius)
                    .fill(Colors.Primary.surface)
                    .opacity(cardOpacity)
            )
    }

    private var cardOpacity: Double {
        switch elevation {
        case 0:
            return LiquidGlassModifiers.Characteristics.subtleOpacity
        case 1:
            return LiquidGlassModifiers.Characteristics.mediumOpacity
        case 2:
            return LiquidGlassModifiers.Characteristics.strongOpacity
        default:
            return LiquidGlassModifiers.Characteristics.mediumOpacity
        }
    }

    private var shadowRadius: CGFloat {
        LiquidGlassModifiers.Characteristics.shadowRadius * CGFloat(elevation + 1)
    }

    private var shadowOffset: CGFloat {
        LiquidGlassModifiers.Characteristics.shadowOffset.height * CGFloat(elevation + 1)
    }

    private var shadowColor: Color {
        Color.black.opacity(LiquidGlassModifiers.Characteristics.shadowOpacity)
    }
}

// MARK: - Liquid Button Modifier

/// Button styling with liquid glass aesthetic
struct LiquidButtonModifier: ViewModifier {

    let style: ButtonStyle
    let size: ButtonSize
    @State private var isPressed = false

    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    enum ButtonSize {
        case small
        case medium
        case large

        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(
                    top: Spacing.extraSmall,
                    leading: Spacing.small,
                    bottom: Spacing.extraSmall,
                    trailing: Spacing.small
                )
            case .medium:
                return EdgeInsets(
                    top: Spacing.small,
                    leading: Spacing.medium,
                    bottom: Spacing.small,
                    trailing: Spacing.medium
                )
            case .large:
                return EdgeInsets(
                    top: Spacing.medium,
                    leading: Spacing.large,
                    bottom: Spacing.medium,
                    trailing: Spacing.large
                )
            }
        }

        var minHeight: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return Spacing.touchTarget
            case .large:
                return 56
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .font(.daisyBody.weight(.medium))
            .foregroundColor(textColor)
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius))
            .shadow(
                color: shadowColor,
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 1 : 3
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(
                .easeInOut(duration: LiquidGlassModifiers.Characteristics.quickAnimation),
                value: isPressed
            )
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius)
            .fill(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var backgroundGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [
                    Colors.Secondary.blue,
                    Colors.Secondary.blue.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .secondary:
            return LinearGradient(
                colors: [
                    Colors.Primary.surface,
                    Colors.Primary.surface.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .tertiary:
            return LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .destructive:
            return LinearGradient(
                colors: [
                    Colors.Accent.error,
                    Colors.Accent.error.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return Color.white
        case .secondary, .tertiary:
            return Colors.Primary.text
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive:
            return Color.clear
        case .secondary:
            return Colors.Semantic.separator
        case .tertiary:
            return Colors.Secondary.blue
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .primary, .destructive:
            return 0
        case .secondary, .tertiary:
            return 1
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Colors.Secondary.blue.opacity(0.3)
        case .destructive:
            return Colors.Accent.error.opacity(0.3)
        default:
            return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Liquid Background Modifier

/// Background styling with subtle material effects
struct LiquidBackgroundModifier: ViewModifier {

    let level: BackgroundLevel
    let material: Material?

    enum BackgroundLevel {
        case base
        case elevated
        case overlay

        var material: Material {
            switch self {
            case .base:
                return .regularMaterial
            case .elevated:
                return .thickMaterial
            case .overlay:
                return .ultraThinMaterial
            }
        }

        var opacity: Double {
            switch self {
            case .base:
                return 1.0
            case .elevated:
                return 0.95
            case .overlay:
                return 0.85
            }
        }
    }

    init(level: BackgroundLevel, material: Material? = nil) {
        self.level = level
        self.material = material
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundEffect)
    }

    private var backgroundEffect: Material {
        material ?? level.material
    }
}

// MARK: - Liquid Border Modifier

/// Border styling with subtle transparency and glow
struct LiquidBorderModifier: ViewModifier {

    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat
    let glowIntensity: CGFloat

    init(
        color: Color = Colors.Semantic.separator,
        width: CGFloat = 1,
        cornerRadius: CGFloat = LiquidGlassModifiers.Characteristics.cardRadius,
        glowIntensity: CGFloat = 0
    ) {
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
        self.glowIntensity = glowIntensity
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
                    .shadow(
                        color: color,
                        radius: glowIntensity,
                        x: 0,
                        y: 0
                    )
            )
    }
}

// MARK: - Liquid Input Field Modifier

/// Input field styling with liquid glass aesthetic
struct LiquidInputModifier: ViewModifier {

    @FocusState private var isFocused: Bool
    let isError: Bool

    init(isError: Bool = false) {
        self.isError = isError
    }

    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(
                top: Spacing.medium,
                leading: Spacing.medium,
                bottom: Spacing.medium,
                trailing: Spacing.medium
            ))
            .background(inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(
                .easeInOut(duration: LiquidGlassModifiers.Characteristics.quickAnimation),
                value: isFocused
            )
            .animation(
                .easeInOut(duration: LiquidGlassModifiers.Characteristics.quickAnimation),
                value: isError
            )
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassModifiers.Characteristics.buttonRadius)
                    .fill(Colors.Semantic.inputBackground)
                    .opacity(0.9)
            )
    }

    private var borderColor: Color {
        if isError {
            return Colors.Accent.error
        } else if isFocused {
            return Colors.Semantic.inputBorderFocused
        } else {
            return Colors.Semantic.inputBorder
        }
    }

    private var borderWidth: CGFloat {
        isFocused || isError ? 2 : 1
    }
}

// MARK: - View Extensions

extension View {

    /// Applies liquid glass card styling
    func liquidCard(elevation: Int = 1, interactive: Bool = false) -> some View {
        self.modifier(LiquidCardModifier(elevation: elevation, interactive: interactive))
    }

    /// Applies liquid glass button styling
    func liquidButton(
        style: LiquidButtonModifier.ButtonStyle = .primary,
        size: LiquidButtonModifier.ButtonSize = .medium
    ) -> some View {
        self.modifier(LiquidButtonModifier(style: style, size: size))
    }

    /// Applies liquid glass background styling
    func liquidBackground(
        level: LiquidBackgroundModifier.BackgroundLevel = .base,
        material: Material? = nil
    ) -> some View {
        self.modifier(LiquidBackgroundModifier(level: level, material: material))
    }

    /// Applies liquid glass border styling
    func liquidBorder(
        color: Color = Colors.Semantic.separator,
        width: CGFloat = 1,
        cornerRadius: CGFloat = LiquidGlassModifiers.Characteristics.cardRadius,
        glowIntensity: CGFloat = 0
    ) -> some View {
        self.modifier(LiquidBorderModifier(
            color: color,
            width: width,
            cornerRadius: cornerRadius,
            glowIntensity: glowIntensity
        ))
    }

    /// Applies liquid glass input field styling
    func liquidInput(isError: Bool = false) -> some View {
        self.modifier(LiquidInputModifier(isError: isError))
    }

    // MARK: - Animation Helpers

    /// Standard liquid glass animation for interactive elements
    func liquidAnimation() -> some View {
        self.animation(
            .easeInOut(duration: LiquidGlassModifiers.Characteristics.standardAnimation),
            value: UUID()
        )
    }

    /// Quick liquid glass animation for immediate feedback
    func liquidQuickAnimation() -> some View {
        self.animation(
            .easeInOut(duration: LiquidGlassModifiers.Characteristics.quickAnimation),
            value: UUID()
        )
    }

    /// Smooth liquid glass animation for state transitions
    func liquidSmoothAnimation() -> some View {
        self.animation(
            .easeInOut(duration: LiquidGlassModifiers.Characteristics.smoothAnimation),
            value: UUID()
        )
    }

    // MARK: - Hover Effects (for supporting platforms)

    /// Adds liquid glass hover effect
    func liquidHover() -> some View {
        self
            .onHover { isHovering in
                // Hover effects would be implemented here for macOS
                // For iOS, this provides a consistent API
            }
    }

    // MARK: - Accessibility Integration

    /// Ensures liquid glass elements meet accessibility requirements
    func liquidAccessible(
        label: String? = nil,
        hint: String? = nil,
        touchTargetSize: CGSize = CGSize(width: Spacing.touchTarget, height: Spacing.touchTarget)
    ) -> some View {
        self
            .frame(minWidth: touchTargetSize.width, minHeight: touchTargetSize.height)
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Liquid Glass Presets

extension LiquidGlassModifiers {

    /// Predefined combinations for common use cases
    enum Presets {

        /// Content card preset
        static func contentCard() -> some ViewModifier {
            LiquidCardModifier(elevation: 1, interactive: false)
        }

        /// Interactive card preset
        static func interactiveCard() -> some ViewModifier {
            LiquidCardModifier(elevation: 1, interactive: true)
        }

        /// Prominent card preset for important content
        static func prominentCard() -> some ViewModifier {
            LiquidCardModifier(elevation: 2, interactive: false)
        }

        /// Primary action button preset
        static func primaryButton() -> some ViewModifier {
            LiquidButtonModifier(style: .primary, size: .medium)
        }

        /// Secondary action button preset
        static func secondaryButton() -> some ViewModifier {
            LiquidButtonModifier(style: .secondary, size: .medium)
        }

        /// Text input field preset
        static func textInput() -> some ViewModifier {
            LiquidInputModifier(isError: false)
        }

        /// Error input field preset
        static func errorInput() -> some ViewModifier {
            LiquidInputModifier(isError: true)
        }
    }
}

// MARK: - Performance Considerations

extension LiquidGlassModifiers {

    /// Performance settings for liquid glass effects
    enum Performance {

        /// Reduced motion settings for accessibility
        static var prefersReducedMotion: Bool {
            UIAccessibility.isReduceMotionEnabled
        }

        /// Simplified effects for lower-end devices
        static var prefersReducedTransparency: Bool {
            UIAccessibility.isReduceTransparencyEnabled
        }

        /// Adaptive animation duration based on accessibility settings
        static var adaptiveAnimationDuration: TimeInterval {
            prefersReducedMotion ? 0.1 : Characteristics.standardAnimation
        }

        /// Adaptive blur radius based on accessibility settings
        static var adaptiveBlurRadius: CGFloat {
            prefersReducedTransparency ? 5 : Characteristics.mediumBlur
        }
    }
}