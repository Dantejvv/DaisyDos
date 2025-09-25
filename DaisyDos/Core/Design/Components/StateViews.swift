//
//  StateViews.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

// MARK: - Loading View

/// Loading state component with customizable appearance and messaging
/// Provides consistent loading indicators across the application
struct LoadingView: View {

    let message: String
    let style: LoadingStyle
    let size: LoadingSize

    // MARK: - Style Definition

    enum LoadingStyle {
        case spinner
        case dots
        case pulse

        @ViewBuilder
        func indicator(size: LoadingSize) -> some View {
            switch self {
            case .spinner:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Secondary.blue))
                    .scaleEffect(size.scale)
            case .dots:
                DotsLoadingView(size: size)
            case .pulse:
                PulseLoadingView(size: size)
            }
        }
    }

    // MARK: - Size Definition

    enum LoadingSize {
        case small
        case medium
        case large

        var scale: CGFloat {
            switch self {
            case .small: return 0.8
            case .medium: return 1.0
            case .large: return 1.5
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return Spacing.extraSmall
            case .medium: return Spacing.small
            case .large: return Spacing.medium
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .daisyCaption
            case .medium: return .daisyBody
            case .large: return .daisyTitle
            }
        }
    }

    // MARK: - Initializers

    init(
        message: String = "Loading...",
        style: LoadingStyle = .spinner,
        size: LoadingSize = .medium
    ) {
        self.message = message
        self.style = style
        self.size = size
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: size.spacing) {
            style.indicator(size: size)

            if !message.isEmpty {
                Text(message)
                    .font(size.fontSize)
                    .foregroundColor(Colors.Primary.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Dots Loading Animation

struct DotsLoadingView: View {
    let size: LoadingView.LoadingSize
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Colors.Secondary.blue)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }

    private var dotSize: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}

// MARK: - Pulse Loading Animation

struct PulseLoadingView: View {
    let size: LoadingView.LoadingSize
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(Colors.Secondary.blue.opacity(0.6))
            .frame(width: circleSize, height: circleSize)
            .scaleEffect(animating ? 1.2 : 0.8)
            .opacity(animating ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: animating
            )
            .onAppear {
                animating = true
            }
    }

    private var circleSize: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        }
    }
}

// MARK: - Empty State View

/// Empty state component for when content is not available
/// Provides helpful messaging and actions to guide users
struct EmptyStateView: View {

    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - Initializers

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: Spacing.large) {
            VStack(spacing: Spacing.medium) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Colors.Primary.textSecondary)

                // Title and description
                VStack(spacing: Spacing.small) {
                    Text(title)
                        .font(.daisyTitle)
                        .foregroundColor(Colors.Primary.text)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.daisyBody)
                        .foregroundColor(Colors.Primary.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                DaisyButton.primary(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Spacing.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityAddTraits(actionTitle != nil ? .isButton : [])
    }
}

// MARK: - Empty State Presets

extension EmptyStateView {

    /// Empty tasks state
    static func noTasks(
        onCreate: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "checklist",
            title: "No Tasks Yet",
            description: "Create your first task to get started organizing your day.",
            actionTitle: "Create Task",
            action: onCreate
        )
    }

    /// Empty habits state
    static func noHabits(
        onCreate: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "repeat",
            title: "No Habits Yet",
            description: "Start building positive habits to improve your daily routine.",
            actionTitle: "Create Habit",
            action: onCreate
        )
    }

    /// Empty search results state
    static func noSearchResults(
        query: String
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            description: "Try adjusting your search terms or browse all items instead."
        )
    }

    /// Empty today view state
    static func nothingToday(
        onAddItems: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "sun.max",
            title: "Nothing Scheduled Today",
            description: "Your day is free! Add some tasks or habits to make the most of it.",
            actionTitle: "Add Items",
            action: onAddItems
        )
    }

    /// Network error state
    static func networkError(
        onRetry: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connection Error",
            description: "Please check your internet connection and try again.",
            actionTitle: "Retry",
            action: onRetry
        )
    }

    /// Generic error state
    static func error(
        title: String = "Something Went Wrong",
        description: String = "An unexpected error occurred. Please try again.",
        onRetry: @escaping () -> Void
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: title,
            description: description,
            actionTitle: "Try Again",
            action: onRetry
        )
    }

    /// Success state
    static func success(
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action
        )
    }
}

// MARK: - Inline Loading View

/// Compact loading view for inline use in lists and cards
struct InlineLoadingView: View {

    let message: String?
    let size: CompactSize

    enum CompactSize {
        case small
        case medium

        var indicatorSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            }
        }

        var font: Font {
            switch self {
            case .small: return .daisyCaption
            case .medium: return .daisySubtitle
            }
        }
    }

    init(message: String? = nil, size: CompactSize = .medium) {
        self.message = message
        self.size = size
    }

    var body: some View {
        HStack(spacing: Spacing.extraSmall) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Colors.Primary.textSecondary))
                .frame(width: size.indicatorSize, height: size.indicatorSize)

            if let message = message {
                Text(message)
                    .font(size.font)
                    .foregroundColor(Colors.Primary.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message ?? "Loading")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Shimmer Loading Effect

/// Shimmer loading effect for placeholder content
struct ShimmerView: View {

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var animating = false

    init(
        width: CGFloat = 100,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 4
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Colors.Primary.backgroundSecondary,
                        Colors.Primary.backgroundTertiary,
                        Colors.Primary.backgroundSecondary
                    ],
                    startPoint: animating ? .leading : .trailing,
                    endPoint: animating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                value: animating
            )
            .onAppear {
                animating = true
            }
            .accessibilityHidden(true)
    }
}

// MARK: - View Extensions

extension View {

    /// Adds a loading overlay to any view
    func loadingOverlay(
        isLoading: Bool,
        message: String = "Loading...",
        style: LoadingView.LoadingStyle = .spinner
    ) -> some View {
        ZStack {
            self
                .disabled(isLoading)

            if isLoading {
                Rectangle()
                    .fill(Colors.Primary.background.opacity(0.8))
                    .ignoresSafeArea()

                LoadingView(message: message, style: style)
            }
        }
    }

    /// Shows empty state when condition is true
    func emptyState(
        _ isEmpty: Bool,
        @ViewBuilder emptyContent: () -> some View
    ) -> some View {
        Group {
            if isEmpty {
                emptyContent()
            } else {
                self
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct StateViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.large) {
                    Group {
                        Text("Loading States")
                            .font(.daisyTitle)
                            .padding(.top)

                        VStack(spacing: Spacing.medium) {
                            LoadingView(message: "Loading tasks...", style: .spinner)
                            LoadingView(message: "Syncing data...", style: .dots)
                            LoadingView(message: "Processing...", style: .pulse, size: .large)
                        }
                        .asCard()

                        Text("Empty States")
                            .font(.daisyTitle)
                            .padding(.top)

                        EmptyStateView.noTasks { }
                        EmptyStateView.noSearchResults(query: "meeting")
                        EmptyStateView.networkError { }

                        Text("Inline Loading")
                            .font(.daisyTitle)
                            .padding(.top)

                        VStack(spacing: Spacing.small) {
                            HStack {
                                InlineLoadingView(message: "Loading...", size: .small)
                                Spacer()
                            }

                            HStack {
                                Text("Shimmer Effect:")
                                    .font(.daisyBody)
                                ShimmerView(width: 150, height: 16)
                                Spacer()
                            }
                        }
                        .asCard()
                    }
                }
                .padding()
            }
            .navigationTitle("State Views")
            .background(Colors.Primary.background)
        }
    }
}
#endif