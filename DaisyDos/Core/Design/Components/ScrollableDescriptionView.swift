//
//  ScrollableDescriptionView.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//

import SwiftUI

// MARK: - ScrollableDescriptionView

/// A reusable component that displays text content with automatic scrolling when content exceeds max height.
/// Provides visual feedback with scroll indicators and fade gradients for better UX.
struct ScrollableDescriptionView: View {
    // MARK: - Properties

    let text: AttributedString
    let maxHeight: CGFloat

    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    // MARK: - Computed Properties

    /// Determines if content is tall enough to require scrolling
    private var isScrollable: Bool {
        contentHeight > maxHeight
    }

    /// Shows top fade when user has scrolled down
    private var showTopFade: Bool {
        isScrollable && scrollOffset > 5
    }

    /// Shows bottom fade when there's more content below
    private var showBottomFade: Bool {
        isScrollable && (contentHeight - scrollOffset - maxHeight) > 5
    }

    // MARK: - Initializer

    init(text: AttributedString, maxHeight: CGFloat = 200) {
        self.text = text
        self.maxHeight = maxHeight
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Scrollable content
            ScrollView(.vertical, showsIndicators: isScrollable) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.daisyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, isScrollable ? -8 : 0) // Reduce scrollbar whitespace
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: HeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                        }
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).minY
                            )
                        }
                    )
            }
            .coordinateSpace(name: "scrollView")
            .frame(maxHeight: maxHeight)
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                contentHeight = height
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollOffset = -offset
            }

            // Top fade gradient
            if showTopFade {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.daisySurface.opacity(0.95),
                        Color.daisySurface.opacity(0.7),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                .allowsHitTesting(false)
            }

            // Bottom fade gradient
            if showBottomFade {
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.daisySurface.opacity(0.7),
                            Color.daisySurface.opacity(0.95)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                    .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isScrollable ? "Description, scrollable content" : "Description")
        .accessibilityHint(isScrollable ? "Swipe up or down to read more" : "")
    }
}

// MARK: - Preference Keys

/// Preference key for measuring content height
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview("Short Description") {
    VStack(spacing: 20) {
        ScrollableDescriptionView(
            text: AttributedString("This is a short description that fits in one line."),
            maxHeight: 200
        )
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Long Description") {
    VStack(spacing: 20) {
        ScrollableDescriptionView(
            text: AttributedString("""
            This is a very long description that will definitely need scrolling.

            It has multiple paragraphs with lots of content.

            Here's another paragraph to make it even longer.

            And another one for good measure.

            We want to test how the scroll view handles lots of vertical content.

            This should trigger the scroll indicators and fade gradients.

            Keep adding more content to really test the limits.

            Almost there...

            Just a bit more...

            This should definitely be scrollable now!
            """),
            maxHeight: 200
        )
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Multiple Newlines") {
    VStack(spacing: 20) {
        ScrollableDescriptionView(
            text: AttributedString("""
            First line.




            Second line with many newlines above.




            Third line.




            Fourth line.




            Fifth line.
            """),
            maxHeight: 200
        )
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Accessibility - Large Text") {
    VStack(spacing: 20) {
        ScrollableDescriptionView(
            text: AttributedString("""
            This is a description with Dynamic Type support.

            It should adapt to larger text sizes while maintaining the scroll functionality.

            Test this with different accessibility text sizes.
            """),
            maxHeight: 200
        )
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color.daisyBackground)
    .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
