//
//  TaskRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

// MARK: - TaskRowDisplayMode

enum TaskRowDisplayMode {
    case compact    // Minimal info for dense lists
    case detailed   // Full information display
    case today      // Today-specific optimizations
}

// MARK: - TaskRowView

struct TaskRowView: View {
    // MARK: - Properties

    let task: Task
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTagAssignment: (() -> Void)?

    let displayMode: TaskRowDisplayMode
    let showsSubtasks: Bool
    let showsTagButton: Bool

    // MARK: - Initializers

    init(
        task: Task,
        onToggleCompletion: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onTagAssignment: (() -> Void)? = nil,
        displayMode: TaskRowDisplayMode = .detailed,
        showsSubtasks: Bool = true,
        showsTagButton: Bool = true
    ) {
        self.task = task
        self.onToggleCompletion = onToggleCompletion
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onTagAssignment = onTagAssignment
        self.displayMode = displayMode
        self.showsSubtasks = showsSubtasks
        self.showsTagButton = showsTagButton
    }

    // MARK: - Body

    var body: some View {
        switch displayMode {
        case .compact:
            compactView
        case .detailed:
            detailedView
        case .today:
            todayView
        }
    }

    // MARK: - Display Mode Views

    @ViewBuilder
    private var compactView: some View {
        HStack(spacing: 12) {
            // Completion toggle
            completionToggle

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(task.hasOverdueStatus ? .red : .secondary)
                }
            }

            Spacer()

            // Priority indicator
            if task.priority != .medium {
                task.priority.indicatorView()
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(task.isCompleted ? [.updatesFrequently] : [])
    }

    @ViewBuilder
    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task header
            HStack {
                completionToggle

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)

                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Priority indicator
                if task.priority != .medium {
                    task.priority.indicatorView()
                        .font(.caption)
                }
            }

            // Tags section
            if !task.tags.isEmpty {
                tagsSection
            }

            // Metadata footer
            metadataFooter
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var todayView: some View {
        HStack(spacing: 12) {
            // Completion toggle
            completionToggle

            // Content optimized for today view
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer()

                    // Priority and due date in header for today view
                    if task.priority != .medium {
                        task.priority.indicatorView()
                            .font(.caption)
                    }

                    if task.hasOverdueStatus {
                        Text("Overdue")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1), in: Capsule())
                    }
                }

                // Tags for today view (more compact)
                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.tags.prefix(2), id: \.id) { tag in
                            TagChipView(tag: tag)
                                .scaleEffect(0.8)
                        }
                        if task.tags.count > 2 {
                            Text("+\(task.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private var completionToggle: some View {
        Button(action: onToggleCompletion) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(task.isCompleted ? Color(.systemGreen) : .gray)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
        .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
    }

    @ViewBuilder
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(task.tags, id: \.id) { tag in
                    TagChipView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tags: " + task.tags.map(\.name).joined(separator: ", "))
    }

    @ViewBuilder
    private var metadataFooter: some View {
        HStack {
            // Due date
            if let dueDate = task.dueDate {
                Label(
                    dueDate.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(task.hasOverdueStatus ? .red : .secondary)
                .accessibilityLabel("Due " + dueDate.formatted(date: .complete, time: .omitted))
            }

            // Subtasks progress
            if showsSubtasks && task.hasSubtasks {
                Label("\(task.completedSubtaskCount)/\(task.subtaskCount)", systemImage: "checklist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("\(task.completedSubtaskCount) of \(task.subtaskCount) subtasks completed")
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if showsTagButton, let onTagAssignment = onTagAssignment {
                    Button(action: onTagAssignment) {
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Assign tags")
                    .frame(minWidth: 44, minHeight: 44)
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit task")
                .frame(minWidth: 44, minHeight: 44)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete task")
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = task.title
        if task.isCompleted {
            label += ", completed"
        }
        if task.priority != .medium {
            label += ", \(task.priority.displayName) priority"
        }
        if let dueDate = task.dueDate {
            label += ", due \(dueDate.formatted(date: .complete, time: .omitted))"
        }
        if task.hasOverdueStatus {
            label += ", overdue"
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

#Preview("Detailed Mode") {
    TaskRowViewPreview(displayMode: .detailed)
}

#Preview("Compact Mode") {
    TaskRowViewPreview(displayMode: .compact)
}

#Preview("Today Mode") {
    TaskRowViewPreview(displayMode: .today)
}

#Preview("Accessibility") {
    TaskRowViewPreview(displayMode: .detailed)
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

struct TaskRowViewPreview: View {
    let displayMode: TaskRowDisplayMode

    init(displayMode: TaskRowDisplayMode = .detailed) {
        self.displayMode = displayMode
    }

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
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            startDate: Date()
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
                },
                displayMode: displayMode
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
                onDelete: {},
                displayMode: displayMode
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
                onDelete: {},
                displayMode: displayMode
            )
        }
        .modelContainer(container)
        .padding()
    }
}