//
//  CardView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Base card component with liquid glass aesthetic
/// Provides consistent styling and behavior for all content containers
/// Supports multiple elevation levels, interactive states, and full accessibility
struct CardView<Content: View>: View {

    // MARK: - Configuration

    let content: Content
    let elevation: Elevation
    let interactive: Bool
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let onTap: (() -> Void)?

    // MARK: - Elevation Levels

    enum Elevation: Int, CaseIterable {
        case none = 0
        case subtle = 1
        case moderate = 2
        case prominent = 3

        var shadowRadius: CGFloat {
            switch self {
            case .none: return 0
            case .subtle: return 4
            case .moderate: return 8
            case .prominent: return 16
            }
        }

        var shadowOffset: CGSize {
            let y = CGFloat(rawValue * 2)
            return CGSize(width: 0, height: y)
        }

        var shadowOpacity: Double {
            switch self {
            case .none: return 0
            case .subtle: return 0.08
            case .moderate: return 0.12
            case .prominent: return 0.16
            }
        }

        var backgroundOpacity: Double {
            switch self {
            case .none: return 1.0
            case .subtle: return 0.98
            case .moderate: return 0.95
            case .prominent: return 0.92
            }
        }
    }

    // MARK: - Initializers

    /// Creates a basic card with default styling
    init(
        elevation: Elevation = .subtle,
        interactive: Bool = false,
        padding: EdgeInsets = EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.medium,
            bottom: Spacing.medium,
            trailing: Spacing.medium
        ),
        cornerRadius: CGFloat = DesignSystem.cornerRadius,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.elevation = elevation
        self.interactive = interactive
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    /// Creates an interactive card with tap action
    init(
        elevation: Elevation = .subtle,
        padding: EdgeInsets = EdgeInsets(
            top: Spacing.medium,
            leading: Spacing.medium,
            bottom: Spacing.medium,
            trailing: Spacing.medium
        ),
        cornerRadius: CGFloat = DesignSystem.cornerRadius,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.elevation = elevation
        self.interactive = true
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    // MARK: - View Body

    var body: some View {
        Group {
            if interactive && onTap != nil {
                Button(action: onTap!) {
                    cardContent
                }
                .buttonStyle(CardButtonStyle())
            } else {
                cardContent
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap?()
                    }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(interactive ? .isButton : [])
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                x: elevation.shadowOffset.width,
                y: elevation.shadowOffset.height
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Colors.Primary.surface)
                    .opacity(elevation.backgroundOpacity)
            )
    }
}

// MARK: - Card Button Style

/// Button style for interactive cards that preserves liquid glass aesthetic
struct CardButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(
                .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}

// MARK: - Card Presets (removed static factory methods to avoid generic parameter conflicts)

// MARK: - View Extensions

extension View {

    /// Wraps any view in a card container
    func asCard(
        elevation: CardView<Self>.Elevation = .subtle,
        interactive: Bool = false,
        onTap: (() -> Void)? = nil
    ) -> CardView<Self> {
        CardView(
            elevation: elevation,
            interactive: interactive,
            onTap: onTap
        ) {
            self
        }
    }

    /// Wraps any view in an interactive card
    func asInteractiveCard(
        elevation: CardView<Self>.Elevation = .moderate,
        onTap: @escaping () -> Void
    ) -> CardView<Self> {
        CardView(
            elevation: elevation,
            onTap: onTap
        ) {
            self
        }
    }
}

// MARK: - Accessibility Extensions

extension CardView {

    /// Adds accessibility labels and hints to the card
    func accessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }

    /// Configures card for specific content types
    func cardAccessibilityRole() -> some View {
        self.accessibilityElement(children: .contain)
            .accessibilityAddTraits(interactive ? .isButton : [])
    }
}

// MARK: - Card Modifiers

extension CardView {

    /// Updates card elevation dynamically
    func cardElevation(_ newElevation: Elevation) -> CardView<Content> {
        CardView(
            elevation: newElevation,
            interactive: interactive,
            padding: padding,
            cornerRadius: cornerRadius,
            onTap: onTap
        ) {
            content
        }
    }

    /// Updates card corner radius
    func cardCornerRadius(_ radius: CGFloat) -> CardView<Content> {
        CardView(
            elevation: elevation,
            interactive: interactive,
            padding: padding,
            cornerRadius: radius,
            onTap: onTap
        ) {
            content
        }
    }

    /// Updates card padding
    func cardPadding(_ newPadding: EdgeInsets) -> CardView<Content> {
        CardView(
            elevation: elevation,
            interactive: interactive,
            padding: newPadding,
            cornerRadius: cornerRadius,
            onTap: onTap
        ) {
            content
        }
    }

    /// Updates card padding with uniform insets
    func cardPadding(_ inset: CGFloat) -> CardView<Content> {
        cardPadding(EdgeInsets(
            top: inset,
            leading: inset,
            bottom: inset,
            trailing: inset
        ))
    }
}

// MARK: - Performance Considerations

extension View {

    /// Wraps view in an optimized card for list performance
    func asListOptimizedCard() -> CardView<Self> {
        CardView(
            elevation: .none, // Reduced shadows for performance
            interactive: false,
            padding: EdgeInsets(
                top: Spacing.small,
                leading: Spacing.medium,
                bottom: Spacing.small,
                trailing: Spacing.medium
            ),
            cornerRadius: 12 // Smaller radius for performance
        ) {
            self
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.medium) {
                // Basic content card
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Content Card")
                        .font(.daisyTitle)
                    Text("This is a basic content card with subtle elevation and liquid glass aesthetic.")
                        .font(.daisyBody)
                }
                .asCard()

                // Interactive card
                HStack {
                    VStack(alignment: .leading) {
                        Text("Interactive Card")
                            .font(.daisyTitle)
                        Text("Tap to interact")
                            .font(.daisySubtitle)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.daisyTextSecondary)
                }
                .asInteractiveCard(onTap: {})

                // Prominent card
                VStack(spacing: Spacing.small) {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.daisySuccess)
                    Text("Prominent Card")
                        .font(.daisyTitle)
                    Text("High elevation for important content")
                        .font(.daisyBody)
                        .multilineTextAlignment(.center)
                }
                .asCard(elevation: .prominent)

                // Compact card
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.daisySuccess)
                    Text("Compact Card")
                        .font(.daisyBody)
                    Spacer()
                }
                .asCard()
            }
            .padding()
        }
        .background(Colors.Primary.background)
    }
}
#endif