//
//  TaskSectionType.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import Foundation
import SwiftUI

/// Section types for organizing tasks in the TasksView list
/// Supports priority, date-based, and completion status grouping
enum TaskSectionType: String, CaseIterable, Identifiable {
    case none = "None"
    case priority = "Priority"
    case tags = "Tags"
    case createdDate = "Created"
    case dueDate = "Due Date"
    case completionStatus = "Status"

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .priority:
            return "Priority"
        case .tags:
            return "Tags"
        case .createdDate:
            return "Created"
        case .dueDate:
            return "Due Date"
        case .completionStatus:
            return "Status"
        }
    }

    var description: String {
        switch self {
        case .none:
            return "Show all tasks in a single list"
        case .priority:
            return "Group tasks by High, Medium, and Low priority"
        case .tags:
            return "Group tasks by assigned tags"
        case .createdDate:
            return "Group tasks by when they were created"
        case .dueDate:
            return "Group tasks by Today, Tomorrow, This Week, and Later"
        case .completionStatus:
            return "Group tasks by To Do, In Progress, and Completed"
        }
    }

    var sfSymbol: String {
        switch self {
        case .none:
            return "list.bullet"
        case .priority:
            return "exclamationmark.triangle"
        case .tags:
            return "tag"
        case .createdDate:
            return "clock"
        case .dueDate:
            return "calendar"
        case .completionStatus:
            return "checkmark.circle"
        }
    }

    // MARK: - Default Section

    static let `default`: TaskSectionType = .none
}

// MARK: - Task Sectioning Logic

extension TaskSectionType {

    /// Groups tasks according to this section type
    func groupTasks(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        switch self {
        case .none:
            return [("All Tasks", tasks)]
        case .priority:
            return groupTasksByPriority(tasks)
        case .tags:
            return groupTasksByTags(tasks)
        case .createdDate:
            return groupTasksByCreatedDate(tasks)
        case .dueDate:
            return groupTasksByDueDate(tasks)
        case .completionStatus:
            return groupTasksByCompletionStatus(tasks)
        }
    }

    // MARK: - Priority Grouping

    private func groupTasksByPriority(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        let grouped = Priority.group(tasks)
        var sections: [(String, [Task])] = []

        // Order sections by priority (High → Medium → Low)
        for priority in Priority.sortedByPriority {
            if let tasksForPriority = grouped[priority], !tasksForPriority.isEmpty {
                let sectionTitle = "\(priority.displayName) (\(tasksForPriority.count))"
                sections.append((sectionTitle, tasksForPriority))
            }
        }

        return sections
    }

    // MARK: - Tags Grouping

    private func groupTasksByTags(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        var taggedTasks: [(String, [DaisyDos.Task])] = []
        var untaggedTasks: [DaisyDos.Task] = []
        var usedTags: Set<String> = []

        for task in tasks {
            if task.tags.isEmpty {
                untaggedTasks.append(task)
            } else {
                for tag in task.tags {
                    if !usedTags.contains(tag.name) {
                        usedTags.insert(tag.name)
                        let tasksWithThisTag = tasks.filter { $0.tags.contains(tag) }
                        taggedTasks.append(("\(tag.name) (\(tasksWithThisTag.count))", tasksWithThisTag))
                    }
                }
            }
        }

        // Sort tag sections alphabetically
        taggedTasks.sort { $0.0 < $1.0 }

        // Add untagged section at the end if there are untagged tasks
        if !untaggedTasks.isEmpty {
            taggedTasks.append(("No Tags (\(untaggedTasks.count))", untaggedTasks))
        }

        return taggedTasks
    }

    // MARK: - Due Date Grouping

    private func groupTasksByDueDate(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        var overdueTasks: [DaisyDos.Task] = []
        var todayTasks: [DaisyDos.Task] = []
        var tomorrowTasks: [DaisyDos.Task] = []
        var thisWeekTasks: [DaisyDos.Task] = []
        var laterTasks: [DaisyDos.Task] = []
        var noDueDateTasks: [DaisyDos.Task] = []

        for task in tasks {
            guard let dueDate = task.dueDate else {
                noDueDateTasks.append(task)
                continue
            }

            let dueDateDay = calendar.startOfDay(for: dueDate)

            if dueDateDay < today {
                overdueTasks.append(task)
            } else if dueDateDay == today {
                todayTasks.append(task)
            } else if dueDateDay == calendar.startOfDay(for: tomorrow) {
                tomorrowTasks.append(task)
            } else if dueDateDay <= endOfWeek {
                thisWeekTasks.append(task)
            } else {
                laterTasks.append(task)
            }
        }

        var sections: [(String, [Task])] = []

        if !overdueTasks.isEmpty {
            sections.append(("Overdue (\(overdueTasks.count))", overdueTasks))
        }
        if !todayTasks.isEmpty {
            sections.append(("Today (\(todayTasks.count))", todayTasks))
        }
        if !tomorrowTasks.isEmpty {
            sections.append(("Tomorrow (\(tomorrowTasks.count))", tomorrowTasks))
        }
        if !thisWeekTasks.isEmpty {
            sections.append(("This Week (\(thisWeekTasks.count))", thisWeekTasks))
        }
        if !laterTasks.isEmpty {
            sections.append(("Later (\(laterTasks.count))", laterTasks))
        }
        if !noDueDateTasks.isEmpty {
            sections.append(("No Due Date (\(noDueDateTasks.count))", noDueDateTasks))
        }

        return sections
    }

    // MARK: - Completion Status Grouping

    private func groupTasksByCompletionStatus(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        let todoTasks = tasks.filter { !$0.isCompleted }
        let completedTasks = tasks.filter { $0.isCompleted }

        var sections: [(String, [Task])] = []

        if !todoTasks.isEmpty {
            sections.append(("To Do (\(todoTasks.count))", todoTasks))
        }
        if !completedTasks.isEmpty {
            sections.append(("Completed (\(completedTasks.count))", completedTasks))
        }

        return sections
    }

    // MARK: - Created Date Grouping

    private func groupTasksByCreatedDate(_ tasks: [DaisyDos.Task]) -> [(String, [DaisyDos.Task])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!

        var todayTasks: [DaisyDos.Task] = []
        var yesterdayTasks: [DaisyDos.Task] = []
        var thisWeekTasks: [DaisyDos.Task] = []
        var thisMonthTasks: [DaisyDos.Task] = []
        var olderTasks: [DaisyDos.Task] = []

        for task in tasks {
            let createdDay = calendar.startOfDay(for: task.createdDate)

            if createdDay == today {
                todayTasks.append(task)
            } else if createdDay == calendar.startOfDay(for: yesterday) {
                yesterdayTasks.append(task)
            } else if createdDay >= lastWeek {
                thisWeekTasks.append(task)
            } else if createdDay >= lastMonth {
                thisMonthTasks.append(task)
            } else {
                olderTasks.append(task)
            }
        }

        var sections: [(String, [Task])] = []

        if !todayTasks.isEmpty {
            sections.append(("Today (\(todayTasks.count))", todayTasks))
        }
        if !yesterdayTasks.isEmpty {
            sections.append(("Yesterday (\(yesterdayTasks.count))", yesterdayTasks))
        }
        if !thisWeekTasks.isEmpty {
            sections.append(("This Week (\(thisWeekTasks.count))", thisWeekTasks))
        }
        if !thisMonthTasks.isEmpty {
            sections.append(("This Month (\(thisMonthTasks.count))", thisMonthTasks))
        }
        if !olderTasks.isEmpty {
            sections.append(("Older (\(olderTasks.count))", olderTasks))
        }

        return sections
    }
}

// MARK: - Section Header Styling

extension TaskSectionType {

    /// Creates a section header view with proper styling
    @ViewBuilder
    func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Image(systemName: sfSymbol)
                .foregroundColor(.daisyTask)
                .font(.headline)

            Text(title)
                .font(.daisySubtitle)
                .fontWeight(.semibold)
                .foregroundColor(.daisyText)

            Spacer()

            Text("\(count)")
                .font(.daisyCaption)
                .fontWeight(.medium)
                .foregroundColor(.daisyTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview Support

#if DEBUG
extension TaskSectionType {

    /// Sample tasks for preview purposes
    static var sampleTasks: [DaisyDos.Task] {
        let highPriorityTask = Task(title: "High Priority Task", priority: .high)
        highPriorityTask.dueDate = Date()

        let mediumPriorityTask = Task(title: "Medium Priority Task", priority: .medium)
        mediumPriorityTask.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())

        let lowPriorityTask = Task(title: "Low Priority Task", priority: .low)
        lowPriorityTask.isCompleted = true

        let noDueDateTask = Task(title: "No Due Date Task", priority: .medium)

        return [highPriorityTask, mediumPriorityTask, lowPriorityTask, noDueDateTask]
    }
}

struct TaskSectionType_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("Section Type Examples")
                .font(.daisyTitle)

            VStack(spacing: 8) {
                ForEach(TaskSectionType.allCases) { sectionType in
                    HStack {
                        Image(systemName: sectionType.sfSymbol)
                            .foregroundColor(.daisyTask)

                        VStack(alignment: .leading) {
                            Text(sectionType.displayName)
                                .font(.daisyBody)
                                .fontWeight(.medium)

                            Text(sectionType.description)
                                .font(.daisyCaption)
                                .foregroundColor(.daisyTextSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
#endif