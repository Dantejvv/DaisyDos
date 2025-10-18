//
//  DesignSystemTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
@testable import DaisyDos

/// Test view to demonstrate and validate the DaisyDos design system
/// Shows all design system components in action with proper styling
struct DesignSystemTestView: View {

    @State private var textFieldValue = ""
    @State private var hasError = false
    @State private var sliderValue: Double = 50

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.medium) {

                    // MARK: - Typography Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Typography System")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                            Text("Title Text - DaisyTitle Font")
                                .font(.daisyTitle)

                            Text("Body Text - DaisyBody Font with full Dynamic Type support and proper line spacing for optimal readability.")
                                .font(.daisyBody)

                            Text("Subtitle Text - DaisySubtitle Font for secondary information")
                                .font(.daisySubtitle)
                                .foregroundColor(.daisyTextSecondary)

                            Text("Caption Text - DaisyCaption Font for metadata")
                                .font(.daisyCaption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                    .liquidCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Color System Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Color System (60-30-10 Rule)")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                            colorSwatch("Primary", color: .daisyText)
                            colorSwatch("Surface", color: .daisySurface)
                            colorSwatch("Background", color: .daisyBackground)
                            colorSwatch("CTA Blue", color: .daisyCTA)
                            colorSwatch("Task Blue", color: .daisyTask)
                            colorSwatch("Habit Teal", color: .daisyHabit)
                            colorSwatch("Success", color: .daisySuccess)
                            colorSwatch("Warning", color: .daisyWarning)
                            colorSwatch("Error", color: .daisyError)
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Button System Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Button System")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(spacing: Spacing.small) {
                            HStack(spacing: Spacing.small) {
                                Button("Primary Large") {}
                                    .liquidButton(style: .primary, size: .large)

                                Button("Secondary Large") {}
                                    .liquidButton(style: .secondary, size: .large)
                            }

                            HStack(spacing: Spacing.small) {
                                Button("Primary Medium") {}
                                    .liquidButton(style: .primary, size: .medium)

                                Button("Secondary Medium") {}
                                    .liquidButton(style: .secondary, size: .medium)

                                Button("Tertiary") {}
                                    .liquidButton(style: .tertiary, size: .medium)
                            }

                            HStack(spacing: Spacing.small) {
                                Button("Primary Small") {}
                                    .liquidButton(style: .primary, size: .small)

                                Button("Secondary Small") {}
                                    .liquidButton(style: .secondary, size: .small)

                                Button("Destructive") {}
                                    .liquidButton(style: .destructive, size: .small)
                            }
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Input System Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Input System")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(spacing: Spacing.medium) {
                            VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                                Text("Normal Input Field")
                                    .font(.daisySubtitle)
                                    .foregroundColor(.daisyTextSecondary)

                                TextField("Enter text here...", text: $textFieldValue)
                                    .liquidInput()
                            }

                            VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                                Text("Error Input Field")
                                    .font(.daisySubtitle)
                                    .foregroundColor(.daisyError)

                                TextField("This field has an error", text: $textFieldValue)
                                    .liquidInput(isError: hasError)

                                Toggle("Show Error State", isOn: $hasError)
                                    .font(.daisyCaption)
                            }
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Spacing System Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Spacing System (8pt Grid)")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(spacing: Spacing.extraSmall) {
                            spacingExample("Extra Small", size: Spacing.extraSmall)
                            spacingExample("Small", size: Spacing.small)
                            spacingExample("Medium", size: Spacing.medium)
                            spacingExample("Large", size: Spacing.large)
                            spacingExample("Extra Large", size: Spacing.extraLarge)
                            spacingExample("Touch Target", size: Spacing.touchTarget)
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Interactive Elements Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Interactive Elements")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(spacing: Spacing.medium) {
                            // Task-like row
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "circle")
                                        .font(.title2)
                                        .foregroundColor(.daisyTask)
                                }
                                .accessibleTouchTarget()

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sample Task Item")
                                        .font(.daisyBody)
                                        .foregroundColor(.daisyText)

                                    Text("Created today at 2:30 PM")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisyTextSecondary)
                                }

                                Spacer()

                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .font(.title3)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                                .accessibleTouchTarget()
                            }
                            .liquidCard(interactive: true)

                            // Habit-like row
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.daisyHabit)
                                }
                                .accessibleTouchTarget()

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily Exercise")
                                        .font(.daisyBody)
                                        .foregroundColor(.daisyText)

                                    Text("5 day streak • Completed today")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisySuccess)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("🔥")
                                        .font(.title2)
                                    Text("5")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                            .liquidCard(interactive: true)
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Accessibility Section

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Accessibility Features")
                            .font(.daisyTitle)
                            .foregroundColor(.daisyText)

                        VStack(alignment: .leading, spacing: Spacing.small) {
                            accessibilityStatusRow("Dynamic Type", isSupported: true)
                            accessibilityStatusRow("VoiceOver Navigation", isSupported: true)
                            accessibilityStatusRow("44pt Touch Targets", isSupported: true)
                            accessibilityStatusRow("WCAG AA Contrast", isSupported: true)
                            accessibilityStatusRow("Reduced Motion", isSupported: true)
                            accessibilityStatusRow("High Contrast", isSupported: true)
                        }
                    }
                    .liquidCard(elevation: 1)
                    .padding(.horizontal, Spacing.screenMargin)

                    Spacer(minLength: Spacing.large)
                }
            }
            .background(Colors.Primary.background)
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.large)
        }
        .accessibilityOptimized()
    }

    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(spacing: Spacing.extraSmall) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Colors.Semantic.separator, lineWidth: 1)
                )

            Text(name)
                .font(.daisyCaption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func spacingExample(_ name: String, size: CGFloat) -> some View {
        HStack {
            Text(name)
                .font(.daisyBody)
                .foregroundColor(.daisyText)
                .frame(width: 120, alignment: .leading)

            Rectangle()
                .fill(Color.daisyCTA)
                .frame(width: size, height: 16)

            Text("\(Int(size))pt")
                .font(.daisyCaption)
                .foregroundColor(.daisyTextSecondary)
                .monospacedDigit()

            Spacer()
        }
    }

    private func accessibilityStatusRow(_ feature: String, isSupported: Bool) -> some View {
        HStack {
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? .daisySuccess : .daisyError)

            Text(feature)
                .font(.daisyBody)
                .foregroundColor(.daisyText)

            Spacer()

            if isSupported {
                Text("Supported")
                    .font(.daisyCaption)
                    .foregroundColor(.daisySuccess)
            }
        }
    }
}

#Preview {
    DesignSystemTestView()
}