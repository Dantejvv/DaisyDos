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
    // MARK: - Core Properties (CloudKit-compatible: all have defaults)
    var id: UUID = UUID()
    var title: String = ""

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

    var isCompleted: Bool = false
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()

    // MARK: - Enhanced Properties (Phase 2.1)
    var priority: Priority = Priority.none
    var dueDate: Date?
    var recurrenceRule: RecurrenceRule?
    var completedDate: Date?
    var reminderDate: Date? // Absolute date/time for reminder notification (non-recurring tasks only)
    var reminderOffset: TimeInterval? // Seconds before due time for relative reminders (recurring tasks only, negative value e.g., -900 for 15 min before)
    var snoozedUntil: Date? // When snoozed, this overrides the normal reminder time until the snooze fires
    var notificationFired: Bool = false // Tracks if the reminder notification has been delivered
    var occurrenceIndex: Int = 1 // Tracks which occurrence this is (1-based, for maxOccurrences enforcement)

    // MARK: - Ordering Properties
    var subtaskOrder: Int = 0 // For ordering within parent's subtask list

    // MARK: - Relationships (CloudKit-compatible: all optional)
    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag]? {
        didSet {
            if let tags = tags, tags.count > 5 {
                self.tags = Array(tags.prefix(5))
            }
        }
    }

    @Relationship(deleteRule: .cascade)
    var subtasks: [Task]?

    @Relationship(inverse: \Task.subtasks)
    var parentTask: Task?

    @Relationship(deleteRule: .cascade, inverse: \TaskAttachment.task)
    var attachments: [TaskAttachment]?

    // MARK: - Computed Properties for Non-Optional Array Access

    private var tagsArray: [Tag] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    private var subtasksArray: [Task] {
        get { subtasks ?? [] }
        set { subtasks = newValue }
    }

    private var attachmentsArray: [TaskAttachment] {
        get { attachments ?? [] }
        set { attachments = newValue }
    }

    // MARK: - Initializers

    init(
        title: String,
        taskDescription: String = "",
        priority: Priority = .none,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        reminderDate: Date? = nil,
        reminderOffset: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescriptionData = AttributedString.migrate(from: taskDescription)
        self.priority = priority
        self.dueDate = dueDate
        self.recurrenceRule = recurrenceRule
        self.reminderDate = reminderDate
        self.reminderOffset = reminderOffset
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
        tagsArray.count
    }

    var subtaskCount: Int {
        subtasksArray.count
    }

    var completedSubtaskCount: Int {
        subtasksArray.filter(\.isCompleted).count
    }

    var hasSubtasks: Bool {
        !subtasksArray.isEmpty
    }

    /// Returns subtasks ordered by their subtaskOrder property
    var orderedSubtasks: [Task] {
        // Ensure order values are assigned for existing tasks
        ensureSubtaskOrderValues()
        return subtasksArray.sorted { $0.subtaskOrder < $1.subtaskOrder }
    }

    /// Ensures all subtasks have proper order values assigned
    private func ensureSubtaskOrderValues() {
        // Check if all subtasks have the default order value (0)
        let allHaveZeroOrder = subtasksArray.allSatisfy { $0.subtaskOrder == 0 }

        if allHaveZeroOrder && subtasksArray.count > 1 {
            // Assign sequential order values to all subtasks
            for (index, subtask) in subtasksArray.enumerated() {
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

    // MARK: - Tag Management

    func canAddTag() -> Bool {
        return tagCount < 5
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tagsArray.contains(tag) {
            tagsArray.append(tag)
            modifiedDate = Date()
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tagsArray.removeAll { $0 == tag }
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
            for subtask in subtasksArray {
                if !subtask.isCompleted {
                    subtask.setCompleted(true)
                    subtask.completedDate = self.completedDate
                }
            }
        } else {
            // When uncompleting a parent task, also uncomplete all subtasks
            for subtask in subtasksArray {
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
        let maxOrder = subtasksArray.map(\.subtaskOrder).max() ?? -1
        subtask.subtaskOrder = maxOrder + 1

        subtasksArray.append(subtask)
        subtask.parentTask = self
        modifiedDate = Date()
        return true
    }

    func removeSubtask(_ subtask: Task) {
        subtasksArray.removeAll { $0 == subtask }
        subtask.parentTask = nil
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
        !attachmentsArray.isEmpty
    }

    var attachmentCount: Int {
        attachmentsArray.count
    }

    var hasReminder: Bool {
        reminderDate != nil || reminderOffset != nil
    }

    /// Computes the effective reminder date based on whether this is a recurring or non-recurring task
    /// - If snoozed: Use snoozedUntil date (overrides normal calculation)
    /// - Recurring tasks: Calculate from dueDate + reminderOffset
    /// - Non-recurring tasks: Use absolute reminderDate
    var effectiveReminderDate: Date? {
        // If snoozed, use the snooze time
        if let snoozed = snoozedUntil {
            return snoozed
        }
        // For recurring tasks with a relative offset
        if let offset = reminderOffset, let due = dueDate, recurrenceRule != nil {
            return due.addingTimeInterval(offset)
        }
        // For non-recurring tasks with an absolute reminder date
        return reminderDate
    }

    /// Returns true if the task has a reminder that hasn't fired yet
    var hasPendingReminder: Bool {
        effectiveReminderDate != nil && !notificationFired
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

        // Determine base date based on repeatMode
        let baseDate: Date
        switch recurrenceRule.repeatMode {
        case .fromOriginalDate:
            // Use original due date (or created date if no due date)
            baseDate = dueDate ?? createdDate

        case .fromCompletionDate:
            // Use when task was actually completed (or now if not completed)
            baseDate = completedDate ?? Date()
        }

        return recurrenceRule.nextOccurrence(after: baseDate)
    }

    func createRecurringInstance() -> Task? {
        // Check if maxOccurrences limit has been reached
        if let maxOccurrences = recurrenceRule?.maxOccurrences,
           occurrenceIndex >= maxOccurrences {
            return nil // Reached max occurrences limit
        }

        guard let nextDate = nextRecurrence() else { return nil }

        let newTask = Task(
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: nextDate,
            recurrenceRule: recurrenceRule,
            reminderDate: nil, // Recurring instances don't use absolute reminders
            reminderOffset: reminderOffset // Inherit the relative reminder offset
        )

        // Copy tags
        newTask.tags = tags

        // Increment occurrence index for tracking maxOccurrences
        newTask.occurrenceIndex = occurrenceIndex + 1

        return newTask
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        return title.isEmpty ? "Untitled Task" : title
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

    /// Short display text for reminder (used in toolbar labels)
    /// For snoozed tasks, shows "Snoozed" with time
    /// For recurring tasks with relative offsets, shows the offset (e.g., "15m before")
    /// For non-recurring tasks, shows the absolute date/time
    var reminderDisplayText: String? {
        // If snoozed, show snooze time
        if let snoozed = snoozedUntil {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Snoozed \(formatter.string(from: snoozed))"
        }

        // For recurring tasks with relative offset, show the offset description
        if recurrenceRule != nil, let offset = reminderOffset {
            return ReminderOffset.displayText(for: offset)
        }

        // For non-recurring tasks, show the absolute reminder date
        guard let reminderDate = reminderDate else { return nil }

        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(reminderDate) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: reminderDate)
        } else if calendar.isDateInTomorrow(reminderDate) {
            formatter.dateFormat = "h:mm a"
            return "Tmrw \(formatter.string(from: reminderDate))"
        } else if calendar.isDate(reminderDate, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEE h:mm a"
            return formatter.string(from: reminderDate)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: reminderDate)
        }
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
