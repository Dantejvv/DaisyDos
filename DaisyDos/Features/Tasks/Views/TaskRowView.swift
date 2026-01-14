//
//  TaskRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//  Refactored on 1/2/25 - Removed unused display modes, extracted shared components
//

import SwiftUI
import SwiftData

// MARK: - TaskRowView

struct TaskRowView: View {
    // MARK: - Properties

    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.colorScheme) private var colorScheme

    let task: Task
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTagAssignment: (() -> Void)?

    // Animation state
    @State private var isAnimatingCompletion = false
    @State private var checkmarkScale: CGFloat = 1.0

    // MARK: - Initializers

    init(
        task: Task,
        onToggleCompletion: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onTagAssignment: (() -> Void)? = nil
    ) {
        self.task = task
        self.onToggleCompletion = onToggleCompletion
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onTagAssignment = onTagAssignment
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion toggle
            completionToggle

            // Content - 3 Row Layout
            VStack(alignment: .leading, spacing: 4) {
                // ROW 1: Title
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .daisyTextSecondary : .daisyText)
                    .lineLimit(1)

                if !task.isCompleted {
                    // UNCOMPLETED TASKS: Inline Layout

                    // ROW 2: Metadata • Tags (LEFT/MIDDLE) | Due Date (RIGHT)
                    if task.hasSubtasks || task.hasReminder || task.hasRecurrence || !(task.tags ?? []).isEmpty || task.dueDate != nil {
                        HStack(spacing: 4) {
                            // Left side: Subtasks
                            if let progressText = task.subtaskProgressText {
                                SubtaskProgressIndicator(progressText: progressText)
                            }

                            // Combined Alert/Recurrence indicator (only shows bell if notification hasn't fired)
                            if task.hasPendingReminder || task.hasRecurrence {
                                alertRecurrenceIndicator
                            }

                            // Middle: Tags (inline with metadata, limit to 3 max)
                            if !(task.tags ?? []).isEmpty {
                                let visibleTags = Array((task.tags ?? []).prefix(3))
                                let remainingCount = (task.tags ?? []).count - visibleTags.count

                                ForEach(visibleTags, id: \.id) { tag in
                                    IconOnlyTagChipView(tag: tag)
                                }

                                if remainingCount > 0 {
                                    Text("+\(remainingCount)")
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }

                            Spacer()

                            // Right side: Due date or "Today" badge
                            if let dueDate = task.dueDate {
                                if task.isDueToday {
                                    todayBadgeView
                                } else {
                                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyTextSecondary)
                                }
                            }
                        }
                    }
                } else {
                    // COMPLETED TASKS: Minimal Layout

                    // ROW 2: Subtasks (LEFT) | Completed Date (RIGHT)
                    HStack(spacing: 4) {
                        // Left side: Subtasks only
                        if let progressText = task.subtaskProgressText {
                            SubtaskProgressIndicator(progressText: progressText)
                        }

                        Spacer()

                        // Right side: Completed date
                        if let completedText = task.completedDateDisplayText {
                            Text(completedText)
                                .font(.caption2)
                                .foregroundColor(.daisySuccess.opacity(0.8))
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Priority background tint
                priorityBackgroundColor

                // Success highlight (only during animation)
                if isAnimatingCompletion {
                    Color.daisySuccess.opacity(0.2)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(task.isCompleted ? [.updatesFrequently] : [])
    }

    // MARK: - Reusable Components

    // MARK: Priority Background
    private var priorityBackgroundColor: Color {
        // Use higher opacity in dark mode for better visibility
        let baseOpacity = colorScheme == .dark ? 0.15 : 0.08

        // Completed tasks: all use gray
        if task.isCompleted {
            return Color.daisyTextSecondary.opacity(baseOpacity)
        }

        // If priority backgrounds are disabled, use default gray
        guard appearanceManager.showPriorityBackgrounds else {
            return Color.daisyTextSecondary.opacity(baseOpacity)
        }

        // Uncompleted tasks: priority-based colors
        switch task.priority {
        case .none:
            return Color.daisyTextSecondary.opacity(baseOpacity)
        case .low:
            return appearanceManager.lowPriorityDisplayColor.opacity(baseOpacity)
        case .medium:
            return appearanceManager.mediumPriorityDisplayColor.opacity(baseOpacity)
        case .high:
            return appearanceManager.highPriorityDisplayColor.opacity(baseOpacity)
        }
    }

    // MARK: Metadata Components

    @ViewBuilder
    private var alertRecurrenceIndicator: some View {
        if task.hasPendingReminder && task.hasRecurrence {
            Image(systemName: "bell.badge.fill")
                .font(.body)
                .foregroundColor(.daisyWarning)
                .accessibilityLabel("Has reminder and recurring")
        } else if task.hasPendingReminder {
            Image(systemName: "bell.fill")
                .font(.body)
                .foregroundColor(.daisyWarning)
                .accessibilityLabel("Has reminder")
        } else if task.hasRecurrence {
            Image(systemName: "repeat.circle.fill")
                .font(.body)
                .foregroundColor(.daisyTask)
                .accessibilityLabel(task.recurrenceRule?.displayDescription ?? "Recurring task")
        }
    }

    @ViewBuilder
    private var todayBadgeView: some View {
        Text("Today")
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(task.hasOverdueStatus ? Color.daisyError : Color.daisyWarning)
            .cornerRadius(4)
    }

    @ViewBuilder
    private func completedDateView(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.daisySuccess.opacity(0.8))
    }

    // MARK: Completion Toggle

    @ViewBuilder
    private var completionToggle: some View {
        Button(action: {
            // Only animate when marking as complete (not uncomplete)
            if !task.isCompleted {
                // Phase 1: Initial bounce (checkmark grows)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    isAnimatingCompletion = true
                    checkmarkScale = 1.4
                }

                // Phase 2: Settle back to normal size
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        checkmarkScale = 1.0
                    }
                }

                // Phase 3: Reset animation state after complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isAnimatingCompletion = false
                }

                // Call the actual completion after brief delay to show animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onToggleCompletion()
                }
            } else {
                // Immediate action when uncompleting
                onToggleCompletion()
            }
        }) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(task.isCompleted ? .daisySuccess : Colors.Primary.textTertiary)
                .scaleEffect(isAnimatingCompletion ? checkmarkScale : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
        .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = task.title

        if task.isCompleted {
            label += ", completed"
            if let completedText = task.completedDateDisplayText {
                label += ", \(completedText.lowercased())"
            }
        }

        if task.priority != .none {
            label += ", \(task.priority.displayName) priority"
        }

        if let progressText = task.subtaskProgressText {
            label += ", \(progressText) subtasks completed"
        }

        if task.hasAttachments {
            let attachmentWord = task.attachmentCount == 1 ? "attachment" : "attachments"
            label += ", \(task.attachmentCount) \(attachmentWord)"
        }

        if let dueDate = task.dueDate {
            if task.isDueToday {
                label += ", due today"
            } else {
                label += ", due \(dueDate.formatted(date: .complete, time: .omitted))"
            }
        }

        if task.hasOverdueStatus {
            label += ", overdue"
        }

        if task.hasReminder {
            label += ", has reminder"
        }

        if task.hasRecurrence {
            if let recurrenceRule = task.recurrenceRule {
                label += ", recurring \(recurrenceRule.displayDescription.lowercased())"
            } else {
                label += ", recurring task"
            }
        }

        return label
    }

    private var accessibilityHint: String {
        if task.isCompleted {
            return "Double tap to mark as incomplete"
        } else {
            return "Double tap to mark as complete"
        }
    }
}

// MARK: - Preview Providers

#Preview("Task Row View") {
    TaskRowViewPreview()
}

#Preview("Accessibility") {
    TaskRowViewPreview()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

struct TaskRowViewPreview: View {
    var body: some View {
        let container = try! ModelContainer(
            for: Task.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let tagManager = TagManager(modelContext: context)

        // Create sample data
        let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
        let personalTag = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")!
        let urgentTag = tagManager.createTag(name: "Urgent", sfSymbolName: "exclamationmark", colorName: "red")!

        let task = Task(
            title: "Sample Task with Description",
            taskDescription: "This is a sample task description that demonstrates the reusable TaskRowView component in action.",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        context.insert(task)
        _ = task.addTag(workTag)
        _ = task.addTag(personalTag)

        // Create subtasks
        let subtask1 = task.createSubtask(title: "Subtask 1")
        let subtask2 = task.createSubtask(title: "Subtask 2")
        subtask1.setCompleted(true)
        context.insert(subtask1)
        context.insert(subtask2)

        try! context.save()

        return VStack(spacing: 16) {
            TaskRowView(
                task: task,
                onToggleCompletion: {
                    task.toggleCompletion()
                },
                onEdit: {
                    print("Edit tapped")
                },
                onDelete: {
                    print("Delete tapped")
                },
                onTagAssignment: {
                    print("Tag assignment tapped")
                }
            )

            // Show completed version
            TaskRowView(
                task: {
                    let completedTask = Task(title: "Completed Task", taskDescription: "This task is already done")
                    completedTask.setCompleted(true)
                    _ = completedTask.addTag(personalTag)
                    return completedTask
                }(),
                onToggleCompletion: {},
                onEdit: {},
                onDelete: {}
            )

            // Show overdue task
            TaskRowView(
                task: {
                    let overdueTask = Task(
                        title: "Overdue Task",
                        priority: .high,
                        dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
                    )
                    _ = overdueTask.addTag(urgentTag)
                    return overdueTask
                }(),
                onToggleCompletion: {},
                onEdit: {},
                onDelete: {}
            )
        }
        .modelContainer(container)
        .padding()
    }
}
