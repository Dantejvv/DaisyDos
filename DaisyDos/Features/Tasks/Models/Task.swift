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
    var startDate: Date?
    var recurrenceRule: RecurrenceRule?
    var completedDate: Date?

    // MARK: - Ordering Properties
    var subtaskOrder: Int = 0 // For ordering within parent's subtask list

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag] = [] {
        didSet {
            if tags.count > 3 {
                tags = Array(tags.prefix(3))
            }
        }
    }

    @Relationship(deleteRule: .cascade)
    var subtasks: [Task] = []

    @Relationship(inverse: \Task.subtasks)
    var parentTask: Task?

    @Relationship(deleteRule: .cascade)
    var attachments: [TaskAttachment] = []

    // MARK: - Initializers

    init(
        title: String,
        taskDescription: String = "",
        priority: Priority = .none,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescriptionData = AttributedString.migrate(from: taskDescription)
        self.priority = priority
        self.dueDate = dueDate
        self.startDate = startDate
        self.recurrenceRule = recurrenceRule
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
        let daysDifference = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return daysDifference >= 0 && daysDifference <= 3
    }

    var isStarted: Bool {
        guard let startDate = startDate else { return true } // No start date means can start anytime
        return Date() >= startDate
    }

    var canStart: Bool {
        return isStarted && !isCompleted
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
        return tagCount < 3
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
            for subtask in subtasks {
                if !subtask.isCompleted {
                    subtask.setCompleted(true)
                }
            }
        } else {
            // When uncompleting a task, propagate up to parent if necessary
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
        guard subtask != self && !subtask.hasAncestor(self) else {
            return false // Prevent circular references
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
            dueDate: self.dueDate, // Inherit due date by default
            startDate: self.startDate
        )

        _ = addSubtask(subtask)
        return subtask
    }

    private func hasAncestor(_ potentialAncestor: Task) -> Bool {
        var current = self.parentTask
        while let parent = current {
            if parent == potentialAncestor {
                return true
            }
            current = parent.parentTask
        }
        return false
    }

    // MARK: - Attachment Management

    var attachmentCount: Int {
        attachments.count
    }

    var totalAttachmentSize: Int64 {
        attachments.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var canAddAttachment: Bool {
        return totalAttachmentSize < TaskAttachment.maxTotalSizePerTask
    }

    func addAttachment(_ attachment: TaskAttachment) -> Bool {
        guard canAddAttachment,
              totalAttachmentSize + attachment.fileSizeBytes <= TaskAttachment.maxTotalSizePerTask else {
            return false
        }

        attachments.append(attachment)
        attachment.task = self
        modifiedDate = Date()
        return true
    }

    func removeAttachment(_ attachment: TaskAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        attachment.task = nil
        modifiedDate = Date()

        // Clean up the physical file
        _ = attachment.deleteFile()
    }

    // MARK: - Date Validation

    var hasValidDates: Bool {
        guard let startDate = startDate, let dueDate = dueDate else {
            return true // If either is nil, no conflict possible
        }
        return startDate <= dueDate
    }

    func validateDates() -> Bool {
        return hasValidDates
    }

    // MARK: - Recurrence Management

    var hasRecurrence: Bool {
        recurrenceRule != nil
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
            startDate: startDate != nil ? {
                let referenceDate = dueDate ?? createdDate
                let daysDifference = Calendar.current.dateComponents([.day], from: referenceDate, to: nextDate).day ?? 0
                return Calendar.current.date(byAdding: .day, value: daysDifference, to: startDate!)
            }() : nil,
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
    // Note: nestingLevel calculation is now unified in Task+Transferable.swift

    var rootTask: Task {
        var current = self
        while let parent = current.parentTask {
            current = parent
        }
        return current
    }

    func allSubtasks() -> [Task] {
        var allSubtasks: [Task] = []
        for subtask in subtasks {
            allSubtasks.append(subtask)
            allSubtasks.append(contentsOf: subtask.allSubtasks())
        }
        return allSubtasks
    }
}

// MARK: - TaskPriorityProvider Conformance

extension Task: TaskPriorityProvider {}

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