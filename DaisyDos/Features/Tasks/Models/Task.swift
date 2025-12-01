//
//  Task.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Task {
    // MARK: - Core Properties
    var id: UUID
    var title: String

    // Rich text description storage (Data-backed AttributedString)
    @Attribute(.externalStorage) var taskDescriptionData: Data?

    // Backward compatibility: Computed property for plain text access
    var taskDescription: String {
        get {
            guard let data = taskDescriptionData else { return "" }
            return AttributedString.extractText(from: data)
        }
        set {
            // Convert plain text to AttributedString and store as Data
            taskDescriptionData = AttributedString.migrate(from: newValue)
        }
    }

    // Rich text accessor for UI components
    var taskDescriptionAttributed: AttributedString {
        get {
            guard let data = taskDescriptionData else {
                return AttributedString.fromPlainText("")
            }
            return AttributedString.fromData(data) ?? AttributedString.fromPlainText("")
        }
        set {
            taskDescriptionData = newValue.toData()
        }
    }

    var isCompleted: Bool
    var createdDate: Date
    var modifiedDate: Date

    // MARK: - Enhanced Properties (Phase 2.1)
    var priority: Priority
    var dueDate: Date?
    var recurrenceRule: RecurrenceRule?
    var completedDate: Date?
    var alertTimeInterval: TimeInterval? // Time interval for alert/reminder (negative = before due date)

    // MARK: - Ordering Properties
    var subtaskOrder: Int = 0 // For ordering within parent's subtask list

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag] = [] {
        didSet {
            if tags.count > 5 {
                tags = Array(tags.prefix(5))
            }
        }
    }

    @Relationship(deleteRule: .cascade)
    var subtasks: [Task] = []

    @Relationship(inverse: \Task.subtasks)
    var parentTask: Task?

    @Relationship(deleteRule: .cascade, inverse: \TaskAttachment.task)
    var attachments: [TaskAttachment] = []

    // MARK: - Initializers

    init(
        title: String,
        taskDescription: String = "",
        priority: Priority = .none,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        alertTimeInterval: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescriptionData = AttributedString.migrate(from: taskDescription)
        self.priority = priority
        self.dueDate = dueDate
        self.recurrenceRule = recurrenceRule
        self.alertTimeInterval = alertTimeInterval
        self.isCompleted = false
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.completedDate = nil
    }

    /// Legacy initializer for backward compatibility
    convenience init(title: String) {
        self.init(title: title, taskDescription: "")
    }

    // MARK: - Computed Properties

    var tagCount: Int {
        tags.count
    }

    var subtaskCount: Int {
        subtasks.count
    }

    var completedSubtaskCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    var hasSubtasks: Bool {
        !subtasks.isEmpty
    }

    /// Returns subtasks ordered by their subtaskOrder property
    var orderedSubtasks: [Task] {
        // Ensure order values are assigned for existing tasks
        ensureSubtaskOrderValues()
        return subtasks.sorted { $0.subtaskOrder < $1.subtaskOrder }
    }

    /// Ensures all subtasks have proper order values assigned
    private func ensureSubtaskOrderValues() {
        // Check if all subtasks have the default order value (0)
        let allHaveZeroOrder = subtasks.allSatisfy { $0.subtaskOrder == 0 }

        if allHaveZeroOrder && subtasks.count > 1 {
            // Assign sequential order values to all subtasks
            for (index, subtask) in subtasks.enumerated() {
                subtask.subtaskOrder = index
            }
        }
    }

    var isRootTask: Bool {
        parentTask == nil
    }

    var hasOverdueStatus: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }

    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, inSameDayAs: Date())
    }

    var isDueSoon: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }

        // Use start of day for both dates to avoid time-of-day issues
        let calendar = Calendar.current
        guard let todayStart = calendar.startOfDay(for: Date()) as Date?,
              let dueDateStart = calendar.startOfDay(for: dueDate) as Date? else {
            return false
        }

        let daysDifference = calendar.dateComponents([.day], from: todayStart, to: dueDateStart).day ?? 0
        return daysDifference >= 0 && daysDifference <= 3
    }


    var subtaskCompletionPercentage: Double {
        guard hasSubtasks else { return isCompleted ? 1.0 : 0.0 }
        guard subtaskCount > 0 else { return 0.0 } // Prevent division by zero
        return Double(completedSubtaskCount) / Double(subtaskCount)
    }

    var isPartiallyComplete: Bool {
        hasSubtasks && subtaskCompletionPercentage > 0 && subtaskCompletionPercentage < 1.0
    }

    // MARK: - Tag Management

    func canAddTag() -> Bool {
        return tagCount < 5
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tags.contains(tag) {
            tags.append(tag)
            modifiedDate = Date()
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll { $0 == tag }
        modifiedDate = Date()
    }

    // MARK: - Completion Management

    func toggleCompletion() {
        setCompleted(!isCompleted)
    }

    func setCompleted(_ completed: Bool) {
        guard isCompleted != completed else { return }

        isCompleted = completed
        completedDate = completed ? Date() : nil
        modifiedDate = Date()

        if completed {
            // When completing a parent task, mark all subtasks as complete
            // and inherit the parent's completion date for age-based housekeeping
            for subtask in subtasks {
                if !subtask.isCompleted {
                    subtask.setCompleted(true)
                    subtask.completedDate = self.completedDate
                }
            }
        } else {
            // When uncompleting a parent task, also uncomplete all subtasks
            for subtask in subtasks {
                if subtask.isCompleted {
                    subtask.setCompleted(false)
                }
            }

            // When uncompleting a subtask, propagate up to parent if necessary
            updateParentCompletionStatus()
        }
    }

    private func updateParentCompletionStatus() {
        guard let parent = parentTask else { return }

        // If parent is complete but this subtask is now incomplete, uncomplete the parent
        if parent.isCompleted && !isCompleted {
            parent.setCompleted(false)
        }
    }

    // MARK: - Subtask Management

    func addSubtask(_ subtask: Task) -> Bool {
        // Prevent subtasks of subtasks - only one level allowed
        guard self.parentTask == nil else {
            return false // This task is already a subtask, cannot have subtasks
        }

        guard subtask != self else {
            return false // Prevent self-reference
        }

        // Assign the next order value
        let maxOrder = subtasks.map(\.subtaskOrder).max() ?? -1
        subtask.subtaskOrder = maxOrder + 1

        subtasks.append(subtask)
        subtask.parentTask = self
        modifiedDate = Date()
        return true
    }

    func removeSubtask(_ subtask: Task) {
        subtasks.removeAll { $0 == subtask }
        subtask.parentTask = nil
        modifiedDate = Date()
    }

    /// Moves a subtask up one position by adjusting order values
    func moveSubtaskUp(_ subtask: Task) {
        let orderedTasks = orderedSubtasks
        guard let currentIndex = orderedTasks.firstIndex(of: subtask),
              currentIndex > 0 else {
            return
        }

        // Get the target task to swap orders with
        let targetTask = orderedTasks[currentIndex - 1]

        // Swap the order values
        let tempOrder = subtask.subtaskOrder
        subtask.subtaskOrder = targetTask.subtaskOrder
        targetTask.subtaskOrder = tempOrder

        modifiedDate = Date()
    }

    /// Moves a subtask down one position by adjusting order values
    func moveSubtaskDown(_ subtask: Task) {
        let orderedTasks = orderedSubtasks
        guard let currentIndex = orderedTasks.firstIndex(of: subtask),
              currentIndex < orderedTasks.count - 1 else {
            return
        }

        // Get the target task to swap orders with
        let targetTask = orderedTasks[currentIndex + 1]

        // Swap the order values
        let tempOrder = subtask.subtaskOrder
        subtask.subtaskOrder = targetTask.subtaskOrder
        targetTask.subtaskOrder = tempOrder

        modifiedDate = Date()
    }

    func createSubtask(
        title: String,
        taskDescription: String = "",
        priority: Priority = .none
    ) -> Task {
        let subtask = Task(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: self.dueDate // Inherit due date by default
        )

        // Inherit parent's creation date for age-based housekeeping
        subtask.createdDate = self.createdDate

        _ = addSubtask(subtask)
        return subtask
    }

    // MARK: - Recurrence Management

    var hasRecurrence: Bool {
        recurrenceRule != nil
    }

    var hasAttachments: Bool {
        !attachments.isEmpty
    }

    var attachmentCount: Int {
        attachments.count
    }

    var hasAlert: Bool {
        alertTimeInterval != nil
    }

    var subtaskProgressText: String? {
        guard hasSubtasks else { return nil }
        return "\(completedSubtaskCount)/\(subtaskCount)"
    }

    var completedDateDisplayText: String? {
        guard isCompleted, let completedDate = completedDate else { return nil }

        let calendar = Calendar.current
        if calendar.isDateInToday(completedDate) {
            return "Completed today"
        } else if calendar.isDateInYesterday(completedDate) {
            return "Completed yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: completedDate, to: Date()).day, daysAgo < 7 {
            return "Completed \(daysAgo) days ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Completed \(formatter.string(from: completedDate))"
        }
    }

    func nextRecurrence() -> Date? {
        guard let recurrenceRule = recurrenceRule else {
            return nil
        }
        let baseDate = completedDate ?? dueDate ?? createdDate
        return recurrenceRule.nextOccurrence(after: baseDate)
    }

    func createRecurringInstance() -> Task? {
        guard let nextDate = nextRecurrence() else { return nil }

        let newTask = Task(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: nextDate,
            recurrenceRule: recurrenceRule
        )

        // Copy tags
        newTask.tags = tags

        return newTask
    }

    // MARK: - Search and Filtering

    func matches(searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        return title.lowercased().contains(query) ||
               taskDescription.lowercased().contains(query) ||
               tags.contains { $0.name.lowercased().contains(query) }
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        return title.isEmpty ? "Untitled Task" : title
    }

    var priorityDisplayText: String {
        return priority.displayName
    }

    var dueDateDisplayText: String? {
        guard let dueDate = dueDate else { return nil }

        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: dueDate)
    }

    // MARK: - Hierarchy Helpers

    var rootTask: Task {
        var current = self
        while let parent = current.parentTask {
            current = parent
        }
        return current
    }
}

// MARK: - Equatable Conformance

extension Task: Equatable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable Conformance

extension Task: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SubtaskDisplayable Conformance

/// Enables Task to be displayed in unified SubtaskRow component
/// Task already has required properties: title, isCompleted
extension Task: SubtaskDisplayable {}
