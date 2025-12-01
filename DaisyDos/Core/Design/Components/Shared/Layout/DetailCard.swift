//
//  DetailCard.swift
//  DaisyDos
//
//  Created by Claude Code on 11/11/25.
//  Standardized card component for detail views
//
//  PURPOSE: Provide consistent card-based layout for all detail view sections
//  Used by: TaskDetailView, HabitDetailView, and all shared card components
//

import SwiftUI

/// A standardized card container for detail view sections
///
/// Provides consistent styling including:
/// - Optional section title with standard typography
/// - White surface background with rounded corners
/// - Standard padding and spacing
/// - Accessibility support
///
/// Usage:
/// ```swift
/// DetailCard(title: "Status") {
///     Text("Content goes here")
/// }
///
/// DetailCard(title: nil) {
///     // Card without title
///     CustomContent()
/// }
/// ```
struct DetailCard<Content: View>: View {
    /// Optional title displayed at top of card in headline font
    let title: String?

    /// Content to display in the card body
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Optional title
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.daisyText)
                    .accessibilityAddTraits(.isHeader)
            }

            // Card content
            content()
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Convenience Initializers

extension DetailCard {
    /// Create a card with only content (no title)
    /// - Parameter content: The view content
    init(@ViewBuilder content: @escaping () -> Content) where Content: View {
        self.title = nil
        self.content = content
    }
}

// MARK: - Preview

#Preview("With Title") {
    VStack(spacing: 20) {
        DetailCard(title: "Section Title") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Label")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Value")
                        .fontWeight(.medium)
                }

                Divider()

                HStack {
                    Text("Another Label")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Another Value")
                        .fontWeight(.medium)
                }
            }
        }

        DetailCard(title: "Status") {
            Text("This is a status card with content")
        }
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Without Title") {
    DetailCard {
        VStack(spacing: 12) {
            Text("Card with no title")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This card has content but no section header")
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Multiple Cards") {
    ScrollView {
        VStack(spacing: 20) {
            DetailCard(title: "Overview") {
                Text("Task or Habit title and description")
            }

            DetailCard(title: "Subtasks") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Subtask 1")
                    Text("• Subtask 2")
                    Text("• Subtask 3")
                }
            }

            DetailCard(title: "Details") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Due Date", systemImage: "calendar")
                        Spacer()
                        Text("Tomorrow")
                    }

                    Divider()

                    HStack {
                        Label("Priority", systemImage: "flag.fill")
                        Spacer()
                        Text("High")
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.daisyBackground)
}
