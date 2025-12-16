//
//  SubtaskRow.swift
//  DaisyDos
//
//  Standardized subtask row component
//  Works with both staging mode (SubtaskItem) and direct mode (Task/Habit model)
//
//  UPDATED: 11/11/25 - Added accent color support for Task/Habit differentiation
//

import SwiftUI

/// Protocol for subtask-like data that can be displayed in SubtaskRow
protocol SubtaskDisplayable {
    var title: String { get }
    var isCompleted: Bool { get }
}

/// A standardized subtask row with checkbox and completion states.
///
/// Features:
/// - Checkbox toggle with animation
/// - Strikethrough on completion
/// - Color coding for completion state with customizable accent color
/// - Generic over any SubtaskDisplayable type
/// - Consistent 44pt touch target for accessibility
///
/// Example:
/// ```swift
/// // For tasks
/// SubtaskRow(
///     subtask: taskSubtask,
///     accentColor: .daisyTask,
///     onToggle: { ... }
/// )
///
/// // For habits
/// SubtaskRow(
///     subtask: habitSubtask,
///     accentColor: .daisyHabit,
///     onToggle: { ... }
/// )
/// ```
struct SubtaskRow<T: SubtaskDisplayable>: View {
    let subtask: T
    let accentColor: Color
    let onToggle: () -> Void

    /// Initialize with custom accent color
    /// - Parameters:
    ///   - subtask: The subtask to display
    ///   - accentColor: Color for completed checkbox (e.g., .daisyTask, .daisyHabit)
    ///   - onToggle: Action to perform when checkbox is tapped
    init(subtask: T, accentColor: Color = .daisyTask, onToggle: @escaping () -> Void) {
        self.subtask = subtask
        self.accentColor = accentColor
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: Spacing.small) {
            // Completion checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggle()
                }
            }) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(subtask.isCompleted ? accentColor : .daisyTextSecondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(subtask.isCompleted ? "Completed" : "Not completed")
            .accessibilityHint("Tap to toggle completion")

            // Title
            Text(subtask.title)
                .font(.body)
                .foregroundColor(subtask.isCompleted ? .daisyTextSecondary : .daisyText)
                .strikethrough(subtask.isCompleted, color: .daisyTextSecondary)

            Spacer()
        }
        .padding(.vertical, 0)
        .padding(.horizontal, Spacing.medium)
        .frame(height: 32)
        .contentShape(Rectangle())
    }
}

// MARK: - Convenience Wrappers

/// Wrapper for staging mode subtasks (Add/Edit views)
/// Used by AddTaskView, TaskEditView, AddHabitView, HabitEditView
struct SubtaskRowStaging: View {
    let subtask: SubtaskItemProtocol
    let accentColor: Color
    let onToggle: () -> Void

    init(subtask: SubtaskItemProtocol, accentColor: Color = .daisyTask, onToggle: @escaping () -> Void) {
        self.subtask = subtask
        self.accentColor = accentColor
        self.onToggle = onToggle
    }

    var body: some View {
        SubtaskRow(
            subtask: SubtaskItemWrapper(item: subtask),
            accentColor: accentColor,
            onToggle: onToggle
        )
    }
}

/// Protocol for staging subtask items
protocol SubtaskItemProtocol {
    var title: String { get }
    var isCompleted: Bool { get }
}

/// Wrapper to make SubtaskItemProtocol conform to SubtaskDisplayable
private struct SubtaskItemWrapper: SubtaskDisplayable {
    let item: SubtaskItemProtocol
    var title: String { item.title }
    var isCompleted: Bool { item.isCompleted }
}

// MARK: - Preview Helpers

private struct PreviewSubtask: SubtaskDisplayable {
    let title: String
    let isCompleted: Bool
}

#Preview {
    VStack(spacing: 0) {
        SubtaskRow(
            subtask: PreviewSubtask(title: "Incomplete subtask", isCompleted: false),
            onToggle: {}
        )

        Divider().padding(.leading, 52)

        SubtaskRow(
            subtask: PreviewSubtask(title: "Completed subtask", isCompleted: true),
            onToggle: {}
        )

        Divider().padding(.leading, 52)

        SubtaskRow(
            subtask: PreviewSubtask(title: "Long subtask title that might wrap to multiple lines in the interface", isCompleted: false),
            onToggle: {}
        )
    }
    .background(Color.daisySurface)
    .cornerRadius(12)
    .padding()
}
