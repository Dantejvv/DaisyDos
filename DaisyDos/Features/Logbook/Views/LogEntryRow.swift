//
//  LogEntryRow.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Lightweight row view for archived task log entries (91-365 days old)
//  NOTE: This is intentionally read-only. Only recent completions (0-90 days)
//  displayed as full Task objects support navigation to TaskDetailView.
//

import SwiftUI

struct LogEntryRow: View {
    let entry: TaskLogEntry

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkmark (read-only)
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.daisySuccess)
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(entry.displayTitle)
                    .font(.body)
                    .strikethrough()
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(2)

                // Parent task indicator if this was a subtask
                if entry.wasSubtask, let parentTitle = entry.parentTaskTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption2)
                        Text(parentTitle)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(Colors.Primary.textTertiary)
                }

                // Metadata row
                HStack(spacing: 8) {
                    // Completion date
                    Text(entry.formattedCompletedDate)
                        .font(.caption)
                        .foregroundColor(Colors.Primary.textTertiary)

                    if !entry.tagNames.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(Colors.Primary.textTertiary)

                        // Tag names (no icons for archived entries)
                        Text(entry.tagNames.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(Colors.Primary.textTertiary)
                            .lineLimit(1)
                    }

                    if entry.subtaskCount > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(Colors.Primary.textTertiary)

                        Label("\(entry.completedSubtaskCount)/\(entry.subtaskCount)", systemImage: "checklist")
                            .font(.caption)
                            .foregroundColor(Colors.Primary.textTertiary)
                    }
                }
            }

            Spacer()

            // Priority indicator
            entry.priority.indicatorView()
                .font(.caption2)

            // Overdue badge
            if entry.wasOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.daisyError)
                    .accessibilityLabel("Was overdue")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = ""

        if entry.wasSubtask {
            label = "Subtask: \(entry.displayTitle)"
            if let parentTitle = entry.parentTaskTitle {
                label += ", parent task: \(parentTitle)"
            }
        } else {
            label = "\(entry.displayTitle)"
        }

        label += ", completed \(entry.formattedCompletedDate)"

        if entry.priority != .medium {
            label += ", \(entry.priority.displayName) priority"
        }

        if entry.wasOverdue {
            label += ", was overdue"
        }

        if entry.subtaskCount > 0 {
            label += ", \(entry.completedSubtaskCount) of \(entry.subtaskCount) subtasks completed"
        }

        if !entry.tagNames.isEmpty {
            label += ", tags: \(entry.tagNames.joined(separator: ", "))"
        }

        return label
    }
}

// MARK: - Preview

#Preview("Log Entry Row") {
    VStack(spacing: 12) {
        // High priority, overdue - regular task
        LogEntryRow(entry: TaskLogEntry(
            originalTaskId: UUID(),
            title: "Complete Quarterly Report",
            taskDescription: "Prepare comprehensive quarterly report",
            completedDate: Calendar.current.date(byAdding: .day, value: -95, to: Date())!,
            createdDate: Calendar.current.date(byAdding: .day, value: -110, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: -98, to: Date())!,
            priority: .high,
            wasOverdue: true,
            subtaskCount: 3,
            completedSubtaskCount: 3,
            wasSubtask: false,
            parentTaskTitle: nil,
            tagNames: ["Work", "Urgent"],
            completionDuration: 1296000  // 15 days
        ))

        // Subtask example
        LogEntryRow(entry: TaskLogEntry(
            originalTaskId: UUID(),
            title: "Gather financial data",
            taskDescription: "",
            completedDate: Calendar.current.date(byAdding: .day, value: -100, to: Date())!,
            createdDate: Calendar.current.date(byAdding: .day, value: -105, to: Date())!,
            dueDate: nil,
            priority: .high,
            wasOverdue: false,
            subtaskCount: 0,
            completedSubtaskCount: 0,
            wasSubtask: true,
            parentTaskTitle: "Complete Quarterly Report",
            tagNames: ["Work"],
            completionDuration: 432000  // 5 days
        ))

        // Medium priority, on time
        LogEntryRow(entry: TaskLogEntry(
            originalTaskId: UUID(),
            title: "Write blog post about SwiftData",
            taskDescription: "",
            completedDate: Calendar.current.date(byAdding: .day, value: -120, to: Date())!,
            createdDate: Calendar.current.date(byAdding: .day, value: -125, to: Date())!,
            dueDate: nil,
            priority: .medium,
            wasOverdue: false,
            subtaskCount: 0,
            completedSubtaskCount: 0,
            wasSubtask: false,
            parentTaskTitle: nil,
            tagNames: ["Personal", "Writing"],
            completionDuration: 432000  // 5 days
        ))
    }
    .padding()
}
