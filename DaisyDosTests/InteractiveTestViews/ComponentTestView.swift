//
//  ComponentTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Test view to demonstrate all core reusable components
/// Validates functionality, accessibility, and visual consistency
struct ComponentTestView: View {

    @State private var textInput = ""
    @State private var emailInput = ""
    @State private var passwordInput = ""
    @State private var hasEmailError = false
    @State private var showLoadingOverlay = false
    @State private var showEmptyState = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.large) {

                    // MARK: - Card Components

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Card Components")
                            .font(.daisyTitle)

                        VStack(spacing: Spacing.medium) {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Text("Content Card")
                                    .font(.daisyBody.weight(.semibold))
                                Text("Basic card for displaying content with subtle elevation.")
                                    .font(.daisySubtitle)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            .asCard()

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Interactive Card")
                                        .font(.daisyBody.weight(.semibold))
                                    Text("Tap to interact with this card")
                                        .font(.daisySubtitle)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            .asInteractiveCard(onTap: {})

                            VStack(spacing: Spacing.small) {
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundColor(.daisySuccess)
                                Text("Prominent Card")
                                    .font(.daisyBody.weight(.semibold))
                                Text("High elevation for important content")
                                    .font(.daisySubtitle)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .asCard(elevation: .prominent)
                        }
                    }
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Button Components

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Button Components")
                            .font(.daisyTitle)

                        VStack(spacing: Spacing.small) {
                            HStack(spacing: Spacing.small) {
                                DaisyButton.primary("Primary", size: .large) {}
                                DaisyButton.secondary("Secondary", size: .large) {}
                            }

                            HStack(spacing: Spacing.small) {
                                DaisyButton.primary("Medium") {}
                                DaisyButton.tertiary("Tertiary") {}
                                DaisyButton.destructive("Delete") {}
                            }

                            HStack(spacing: Spacing.small) {
                                DaisyButton.primary("With Icon", size: .small, icon: "star.fill") {}
                                DaisyButton.secondary("Loading", size: .small, isLoading: true) {}
                                DaisyButton.primary("Disabled", size: .small, isEnabled: false) {}
                            }
                        }
                    }
                    .asCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Input Components

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Input Components")
                            .font(.daisyTitle)

                        VStack(spacing: Spacing.medium) {
                            InputField(
                                "Basic Text Input",
                                text: $textInput,
                                placeholder: "Enter some text..."
                            )

                            InputField.email(
                                text: $emailInput,
                                isRequired: true,
                                errorMessage: hasEmailError ? "Please enter a valid email address" : nil
                            )
                            .onChange(of: emailInput) { _, newValue in
                                hasEmailError = !newValue.isEmpty && !newValue.contains("@")
                            }

                            InputField.password(
                                text: $passwordInput,
                                helperText: "Minimum 8 characters required"
                            )

                            InputField.search(
                                text: .constant(""),
                                placeholder: "Search tasks and habits..."
                            )
                        }
                    }
                    .asCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - State Components

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("State Components")
                            .font(.daisyTitle)

                        VStack(spacing: Spacing.medium) {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.small) {
                                    Text("Loading States")
                                        .font(.daisyBody.weight(.semibold))

                                    LoadingView(message: "Loading data...", size: .small)
                                    InlineLoadingView(message: "Syncing", size: .small)
                                }
                                Spacer()
                            }

                            Divider()

                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.small) {
                                    Text("Shimmer Effect")
                                        .font(.daisyBody.weight(.semibold))

                                    VStack(alignment: .leading, spacing: 4) {
                                        ShimmerView(width: 200, height: 16)
                                        ShimmerView(width: 150, height: 12)
                                        ShimmerView(width: 100, height: 12)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .asCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Interactive Demonstrations

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Interactive Demos")
                            .font(.daisyTitle)

                        VStack(spacing: Spacing.small) {
                            DaisyButton.secondary("Toggle Loading Overlay") {
                                showLoadingOverlay.toggle()
                            }

                            DaisyButton.tertiary("Show Empty State") {
                                showEmptyState = true
                            }
                        }
                    }
                    .asCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    // MARK: - Component Composition Example

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Component Composition")
                            .font(.daisyTitle)

                        // Example of a typical app content structure using components
                        VStack(spacing: Spacing.medium) {
                            // Task-like item
                            HStack(spacing: Spacing.small) {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundColor(.daisyTask)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Review quarterly goals")
                                        .font(.daisyBody)
                                        .foregroundColor(.daisyText)

                                    Text("Due today • High priority")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisyWarning)
                                }

                                Spacer()

                                Image(systemName: "ellipsis")
                                    .font(.body)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            .asInteractiveCard(onTap: {})

                            // Habit-like item
                            HStack(spacing: Spacing.small) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.daisyHabit)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Morning exercise")
                                        .font(.daisyBody)
                                        .foregroundColor(.daisyText)

                                    Text("7 day streak • Completed today")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisySuccess)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("🔥")
                                        .font(.title3)
                                    Text("7")
                                        .font(.daisyCaption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                            .asInteractiveCard(onTap: {})
                        }
                    }
                    .asCard()
                    .padding(.horizontal, Spacing.screenMargin)

                    Spacer(minLength: Spacing.large)
                }
            }
            .background(Colors.Primary.background)
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.large)
            .loadingOverlay(isLoading: showLoadingOverlay, message: "Processing...")
            .sheet(isPresented: $showEmptyState) {
                NavigationView {
                    EmptyStateView.noTasks {
                        showEmptyState = false
                    }
                    .navigationTitle("Empty State Demo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showEmptyState = false
                            }
                        }
                    }
                }
            }
        }
        .accessibilityOptimized()
    }
}

#Preview {
    ComponentTestView()
}