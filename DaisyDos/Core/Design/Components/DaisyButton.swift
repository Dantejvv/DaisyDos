//
//  DaisyButton.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Primary and secondary button components with liquid glass aesthetic
/// Provides consistent styling, accessibility, and interaction patterns
/// Supports multiple sizes, states, and loading indicators
struct DaisyButton: View {

    // MARK: - Configuration

    let title: String
    let style: ButtonStyle
    let size: ButtonSize
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - Style Definition

    enum ButtonStyle: CaseIterable {
        case primary
        case secondary
        case tertiary
        case destructive

        var backgroundColor: Color {
            switch self {
            case .primary:
                return Colors.Secondary.blue
            case .secondary:
                return Colors.Primary.surface
            case .tertiary:
                return Color.clear
            case .destructive:
                return Colors.Accent.error
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return Color.white
            case .secondary, .tertiary:
                return Colors.Primary.text
            }
        }

        var borderColor: Color {
            switch self {
            case .primary, .destructive:
                return Color.clear
            case .secondary:
                return Colors.Semantic.separator
            case .tertiary:
                return Colors.Secondary.blue
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .primary, .destructive:
                return 0
            case .secondary, .tertiary:
                return 1
            }
        }

        var shadowColor: Color {
            switch self {
            case .primary:
                return Colors.Secondary.blue.opacity(0.25)
            case .destructive:
                return Colors.Accent.error.opacity(0.25)
            default:
                return Color.black.opacity(0.05)
            }
        }

        var description: String {
            switch self {
            case .primary:
                return "Primary action button with high prominence"
            case .secondary:
                return "Secondary action button with medium prominence"
            case .tertiary:
                return "Tertiary action button with low prominence"
            case .destructive:
                return "Destructive action button for dangerous operations"
            }
        }
    }

    // MARK: - Size Definition

    enum ButtonSize: CaseIterable {
        case small
        case medium
        case large

        var height: CGFloat {
            switch self {
            case .small:
                return 36
            case .medium:
                return AccessibilityHelpers.TouchTarget.recommended.height
            case .large:
                return 56
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small:
                return Spacing.medium
            case .medium:
                return Spacing.large
            case .large:
                return Spacing.huge
            }
        }

        var fontSize: Font {
            switch self {
            case .small:
                return .daisySubtitle
            case .medium:
                return .daisyBody
            case .large:
                return .daisyTitle
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small:
                return 16
            case .medium:
                return 20
            case .large:
                return 24
            }
        }

        var description: String {
            switch self {
            case .small:
                return "Compact button for tight spaces"
            case .medium:
                return "Standard button meeting 48pt touch target"
            case .large:
                return "Large button for prominent actions"
            }
        }
    }

    // MARK: - Icon Position

    enum IconPosition {
        case leading
        case trailing
    }

    // MARK: - State Management

    @State private var isPressed: Bool = false

    // MARK: - Initializers

    /// Creates a button with all customization options
    init(
        title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    /// Creates a simple text-only button
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            style: style,
            size: size,
            icon: nil,
            iconPosition: .leading,
            isLoading: false,
            isEnabled: isEnabled,
            action: action
        )
    }

    // MARK: - View Body

    var body: some View {
        Button(action: performAction) {
            buttonContent
        }
        .buttonStyle(DaisyButtonStyle(
            buttonStyle: style,
            size: size,
            isEnabled: isEnabled,
            isLoading: isLoading
        ))
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
        .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
        .accessibilityValue(isLoading ? "Loading" : "")
    }

    private var buttonContent: some View {
        HStack(spacing: Spacing.small) {
            if iconPosition == .leading {
                buttonIcon
            }

            if isLoading {
                loadingIndicator
            } else {
                buttonText
            }

            if iconPosition == .trailing {
                buttonIcon
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size.height)
    }

    @ViewBuilder
    private var buttonIcon: some View {
        if let icon = icon, !isLoading {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
        }
    }

    private var buttonText: some View {
        Text(title)
            .font(size.fontSize.weight(.medium))
            .foregroundColor(style.foregroundColor)
            .lineLimit(1)
    }

    private var loadingIndicator: some View {
        HStack(spacing: Spacing.extraSmall) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                .scaleEffect(0.8)

            Text("Loading...")
                .font(size.fontSize.weight(.medium))
                .foregroundColor(style.foregroundColor)
        }
    }

    // MARK: - Actions

    private func performAction() {
        guard isEnabled && !isLoading else { return }

        // Haptic feedback for button press
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()

        action()
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), Loading"
        } else {
            return title
        }
    }

    private var accessibilityHint: String {
        if !isEnabled {
            return "Button is disabled"
        } else if isLoading {
            return "Please wait while loading"
        } else {
            switch style {
            case .primary:
                return "Primary action"
            case .secondary:
                return "Secondary action"
            case .tertiary:
                return "Tertiary action"
            case .destructive:
                return "Warning: This action cannot be undone"
            }
        }
    }
}

// MARK: - Button Style Implementation

struct DaisyButtonStyle: ButtonStyle {

    let buttonStyle: DaisyButton.ButtonStyle
    let size: DaisyButton.ButtonSize
    let isEnabled: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.BorderWidth.thick * 3))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Tokens.BorderWidth.thick * 3)
                    .stroke(buttonStyle.borderColor, lineWidth: buttonStyle.borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
            .scaleEffect(pressedScale(configuration.isPressed))
            .opacity(buttonOpacity)
            .animation(
                .easeInOut(duration: DesignSystem.Tokens.Animation.fast),
                value: configuration.isPressed
            )
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Tokens.BorderWidth.thick * 3)
            .fill(backgroundGradient)
    }

    private var backgroundGradient: LinearGradient {
        let baseColor = buttonStyle.backgroundColor
        return LinearGradient(
            colors: [
                baseColor,
                baseColor.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var shadowColor: Color {
        if !isEnabled {
            return Color.clear
        }
        return buttonStyle.shadowColor
    }

    private var shadowRadius: CGFloat {
        if !isEnabled {
            return 0
        }
        switch size {
        case .small:
            return 4
        case .medium:
            return 6
        case .large:
            return 8
        }
    }

    private var shadowOffset: CGFloat {
        if !isEnabled {
            return 0
        }
        return 2
    }

    private func pressedScale(_ isPressed: Bool) -> CGFloat {
        if !isEnabled || isLoading {
            return 1.0
        }
        return isPressed ? 0.96 : 1.0
    }

    private var buttonOpacity: Double {
        if isLoading {
            return 0.8
        } else if !isEnabled {
            return 0.5
        } else {
            return 1.0
        }
    }
}

// MARK: - Convenience Initializers

extension DaisyButton {

    /// Primary button for main actions
    static func primary(
        _ title: String,
        size: ButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> DaisyButton {
        DaisyButton(
            title: title,
            style: .primary,
            size: size,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Secondary button for supporting actions
    static func secondary(
        _ title: String,
        size: ButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> DaisyButton {
        DaisyButton(
            title: title,
            style: .secondary,
            size: size,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Tertiary button for subtle actions
    static func tertiary(
        _ title: String,
        size: ButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> DaisyButton {
        DaisyButton(
            title: title,
            style: .tertiary,
            size: size,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Destructive button for dangerous actions
    static func destructive(
        _ title: String,
        size: ButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> DaisyButton {
        DaisyButton(
            title: title,
            style: .destructive,
            size: size,
            icon: icon,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - Loading State Extensions

extension DaisyButton {

    /// Creates a button with loading state control
    func loading(_ isLoading: Bool) -> DaisyButton {
        DaisyButton(
            title: title,
            style: style,
            size: size,
            icon: icon,
            iconPosition: iconPosition,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }

    /// Creates a button with enabled state control
    func enabled(_ isEnabled: Bool) -> DaisyButton {
        DaisyButton(
            title: title,
            style: style,
            size: size,
            icon: icon,
            iconPosition: iconPosition,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct DaisyButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                Group {
                    Text("Button Styles")
                        .font(.daisyTitle)
                        .padding(.top)

                    VStack(spacing: Spacing.small) {
                        DaisyButton.primary("Primary Button") {}
                        DaisyButton.secondary("Secondary Button") {}
                        DaisyButton.tertiary("Tertiary Button") {}
                        DaisyButton.destructive("Destructive Button") {}
                    }

                    Text("Button Sizes")
                        .font(.daisyTitle)
                        .padding(.top)

                    VStack(spacing: Spacing.small) {
                        DaisyButton.primary("Large Button", size: .large) {}
                        DaisyButton.primary("Medium Button", size: .medium) {}
                        DaisyButton.primary("Small Button", size: .small) {}
                    }

                    Text("Button States")
                        .font(.daisyTitle)
                        .padding(.top)

                    VStack(spacing: Spacing.small) {
                        DaisyButton.primary("With Icon", icon: "star.fill") {}
                        DaisyButton.primary("Loading Button", isLoading: true) {}
                        DaisyButton.primary("Disabled Button", isEnabled: false) {}
                    }
                }
            }
            .padding()
        }
        .background(Colors.Primary.background)
    }
}
#endif