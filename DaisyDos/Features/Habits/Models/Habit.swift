//
//  Habit.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Habit {
    // CloudKit-compatible: all have defaults
    var id: UUID = UUID()
    var title: String = ""

    // Rich text description storage (Data-backed AttributedString)
    @Attribute(.externalStorage) var habitDescriptionData: Data?

    // Backward compatibility: Computed property for plain text access
    var habitDescription: String {
        get {
            guard let data = habitDescriptionData else { return "" }
            return AttributedString.extractText(from: data)
        }
        set {
            // Convert plain text to AttributedString and store as Data
            habitDescriptionData = AttributedString.migrate(from: newValue)
        }
    }

    // Rich text accessor for UI components
    var habitDescriptionAttributed: AttributedString {
        get {
            guard let data = habitDescriptionData else {
                return AttributedString.fromPlainText("")
            }
            return AttributedString.fromData(data) ?? AttributedString.fromPlainText("")
        }
        set {
            habitDescriptionData = newValue.toData()
        }
    }

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var lastCompletedDate: Date?

    // MARK: - Enhanced Properties for Phase 3

    /// Recurrence rule for habit scheduling (optional for flexible habits)
    var recurrenceRule: RecurrenceRule?

    /// Priority level for habit importance and organization
    var priority: Priority = Priority.none

    /// Time interval for alert/reminder (e.g., -3600 = 1 hour before)
    var alertTimeInterval: TimeInterval?

    /// Custom sort order for manual habit arrangement (lower values appear first)
    var habitOrder: Int = 0

    // MARK: - Relationships (CloudKit-compatible: all optional)

    @Relationship(deleteRule: .nullify, inverse: \Tag.habits)
    var tags: [Tag]? {
        didSet {
            if let tags = tags, tags.count > 5 {
                self.tags = Array(tags.prefix(5))
            }
        }
    }

    /// Individual completion entries with detailed tracking
    @Relationship(deleteRule: .cascade) var completionEntries: [HabitCompletion]?

    /// Streak history and management
    @Relationship(deleteRule: .cascade) var streaks: [HabitStreak]?

    /// Skip entries for tracking when habit was skipped
    @Relationship(deleteRule: .cascade) var skips: [HabitSkip]?

    /// Attachments (photos, documents, etc.)
    @Relationship(deleteRule: .cascade, inverse: \HabitAttachment.habit)
    var attachments: [HabitAttachment]?

    /// Subtasks/checklist items for the habit
    @Relationship(deleteRule: .cascade)
    var subtasks: [HabitSubtask]?

    // MARK: - Computed Properties for Non-Optional Array Access

    private var tagsArray: [Tag] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    private var completionEntriesArray: [HabitCompletion] {
        get { completionEntries ?? [] }
        set { completionEntries = newValue }
    }

    private var streaksArray: [HabitStreak] {
        get { streaks ?? [] }
        set { streaks = newValue }
    }

    private var skipsArray: [HabitSkip] {
        get { skips ?? [] }
        set { skips = newValue }
    }

    private var attachmentsArray: [HabitAttachment] {
        get { attachments ?? [] }
        set { attachments = newValue }
    }

    private var subtasksArray: [HabitSubtask] {
        get { subtasks ?? [] }
        set { subtasks = newValue }
    }

    init(title: String, habitDescription: String = "", recurrenceRule: RecurrenceRule? = nil, priority: Priority = .none) {
        self.id = UUID()
        self.title = title
        self.habitDescriptionData = AttributedString.migrate(from: habitDescription)
        self.currentStreak = 0
        self.longestStreak = 0
        let now = Date()
        self.createdDate = now
        self.modifiedDate = now
        self.lastCompletedDate = nil
        self.recurrenceRule = recurrenceRule
        self.priority = priority
    }

    var tagCount: Int {
        tagsArray.count
    }

    var subtaskCount: Int {
        subtasksArray.count
    }

    var completedSubtaskCount: Int {
        subtasksArray.filter(\.isCompletedToday).count
    }

    var hasSubtasks: Bool {
        !subtasksArray.isEmpty
    }

    var hasAttachments: Bool {
        !attachmentsArray.isEmpty
    }

    var attachmentCount: Int {
        attachmentsArray.count
    }

    var hasAlert: Bool {
        alertTimeInterval != nil
    }

    var subtaskProgressText: String? {
        guard hasSubtasks else { return nil }
        return "\(completedSubtaskCount)/\(subtaskCount)"
    }

    var hasRecurrence: Bool {
        recurrenceRule != nil
    }

    /// Returns subtasks ordered by their subtaskOrder property
    var orderedSubtasks: [HabitSubtask] {
        // Ensure order values are assigned for existing subtasks
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

    func canAddTag() -> Bool {
        return tagCount < 5
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tagsArray.contains(tag) {
            tagsArray.append(tag)
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tagsArray.removeAll { $0 == tag }
    }

    // MARK: - Subtask Management

    func addSubtask(_ subtask: HabitSubtask) -> Bool {
        guard subtask.parentHabit == nil else {
            return false // Subtask already has a parent
        }

        // Assign the next order value
        let maxOrder = subtasksArray.map(\.subtaskOrder).max() ?? -1
        subtask.subtaskOrder = maxOrder + 1

        subtasksArray.append(subtask)
        subtask.parentHabit = self
        modifiedDate = Date()
        return true
    }

    func removeSubtask(_ subtask: HabitSubtask) {
        subtasksArray.removeAll { $0 == subtask }
        subtask.parentHabit = nil
        modifiedDate = Date()
    }

    /// Moves a subtask up one position by adjusting order values
    func moveSubtaskUp(_ subtask: HabitSubtask) {
        let orderedTasks = orderedSubtasks
        guard let currentIndex = orderedTasks.firstIndex(of: subtask),
              currentIndex > 0 else {
            return
        }

        // Get the target subtask to swap orders with
        let targetSubtask = orderedTasks[currentIndex - 1]

        // Swap the order values
        let tempOrder = subtask.subtaskOrder
        subtask.subtaskOrder = targetSubtask.subtaskOrder
        targetSubtask.subtaskOrder = tempOrder

        modifiedDate = Date()
    }

    /// Moves a subtask down one position by adjusting order values
    func moveSubtaskDown(_ subtask: HabitSubtask) {
        let orderedTasks = orderedSubtasks
        guard let currentIndex = orderedTasks.firstIndex(of: subtask),
              currentIndex < orderedTasks.count - 1 else {
            return
        }

        // Get the target subtask to swap orders with
        let targetSubtask = orderedTasks[currentIndex + 1]

        // Swap the order values
        let tempOrder = subtask.subtaskOrder
        subtask.subtaskOrder = targetSubtask.subtaskOrder
        targetSubtask.subtaskOrder = tempOrder

        modifiedDate = Date()
    }

    func createSubtask(title: String) -> HabitSubtask {
        let subtask = HabitSubtask(title: title)

        // Inherit parent's creation date
        subtask.createdDate = self.createdDate

        _ = addSubtask(subtask)
        return subtask
    }

    /// Reset all subtask completion statuses (called when new day starts)
    func resetSubtaskCompletions() {
        for subtask in subtasksArray {
            subtask.resetDailyCompletion()
        }
        modifiedDate = Date()
    }

    var subtaskCompletionPercentage: Double {
        guard hasSubtasks else { return isCompletedToday ? 1.0 : 0.0 }
        guard subtaskCount > 0 else { return 0.0 }
        return Double(completedSubtaskCount) / Double(subtaskCount)
    }

    var isPartiallyComplete: Bool {
        hasSubtasks && subtaskCompletionPercentage > 0 && subtaskCompletionPercentage < 1.0
    }

    func markCompleted() {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if let lastCompleted = lastCompletedDate,
           Calendar.current.isDate(lastCompleted, inSameDayAs: today) {
            return
        }

        lastCompletedDate = today

        // Update streak
        if let lastCompleted = lastCompletedDate,
           Calendar.current.dateInterval(of: .day, for: lastCompleted)?.end == Calendar.current.dateInterval(of: .day, for: today)?.start {
            // Consecutive day
            currentStreak += 1
        } else {
            // Start new streak
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    func resetStreak() {
        currentStreak = 0
        lastCompletedDate = nil
    }

    /// Undo today's completion and recalculate streak
    func undoTodaysCompletion() -> Bool {
        guard isCompletedToday else { return false }

        let today = Calendar.current.startOfDay(for: Date())

        // Remove today's completion entry
        if let todaysCompletion = completionEntriesArray.first(where: { Calendar.current.isDate($0.completedDate, inSameDayAs: today) }) {
            completionEntriesArray.removeAll { $0.id == todaysCompletion.id }
        }

        // Recalculate streak from completion history
        recalculateStreakFromHistory()

        return true
    }

    /// Recalculate current streak based on completion history
    private func recalculateStreakFromHistory() {
        let sortedCompletions = completionEntriesArray.sorted { $0.completedDate > $1.completedDate }

        guard !sortedCompletions.isEmpty else {
            currentStreak = 0
            lastCompletedDate = nil
            return
        }

        let mostRecentCompletion = sortedCompletions.first!
        lastCompletedDate = mostRecentCompletion.completedDate

        // Calculate streak by counting consecutive days from most recent completion
        var streak = 1
        let calendar = Calendar.current

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate

            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                streak += 1
            } else {
                break // Streak broken
            }
        }

        currentStreak = streak
    }

    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }

    var isSkippedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return skipsArray.contains { Calendar.current.isDate($0.skippedDate, inSameDayAs: today) }
    }

    func canMarkCompleted() -> Bool {
        return !isCompletedToday && !isSkippedToday
    }

    func canSkip() -> Bool {
        return !isCompletedToday && !isSkippedToday
    }

    // MARK: - Enhanced Business Logic for Phase 3

    /// Enhanced completion tracking
    func markCompletedWithTracking(notes: String = "", mood: HabitCompletion.Mood = .neutral) -> HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if isCompletedToday {
            return nil
        }

        // Create completion entry
        let completion = HabitCompletion(
            habit: self,
            completedDate: today,
            notes: notes,
            mood: mood
        )

        // Add to completion entries
        completionEntriesArray.append(completion)

        // Update streak with simple consecutive day logic
        updateStreak(completionDate: today)

        lastCompletedDate = today
        return completion
    }

    /// Skip habit with optional reason
    func skipHabit(reason: String? = nil) -> HabitSkip? {
        guard canSkip() else { return nil }

        let today = Calendar.current.startOfDay(for: Date())

        let skip = HabitSkip(
            habit: self,
            skippedDate: today,
            reason: reason
        )

        // Add to skip entries
        skipsArray.append(skip)

        return skip
    }

    /// Check if habit should be due based on recurrence rule
    func isDueOn(date: Date) -> Bool {
        guard let recurrenceRule = recurrenceRule else {
            // No recurrence rule means flexible habit - due every day
            return true
        }

        return recurrenceRule.matches(date: date, relativeTo: createdDate)
    }

    /// Get next due date based on recurrence rule
    func nextDueDate(after date: Date = Date()) -> Date? {
        guard let recurrenceRule = recurrenceRule else {
            // Flexible habit - next day
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        }

        return recurrenceRule.nextOccurrence(after: date)
    }

    /// Calculate completion rate over a period
    func completionRate(over days: Int) -> Double {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return 0.0
        }

        let completedDays = completionEntriesArray.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }.count

        let totalDueDays = dueDaysInPeriod(from: startDate, to: endDate)
        guard totalDueDays > 0 else { return 0.0 }

        return Double(completedDays) / Double(totalDueDays)
    }

    // MARK: - Private Helper Methods

    private func updateStreak(completionDate: Date) {
        guard let lastCompleted = lastCompletedDate else {
            // First completion
            currentStreak = 1
            return
        }

        let calendar = Calendar.current

        // No recurrence rule = simple consecutive day logic
        guard let recurrenceRule = recurrenceRule else {
            let daysBetween = calendar.dateComponents([.day], from: lastCompleted, to: completionDate).day ?? 0

            if daysBetween == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }

            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
            return
        }

        // WITH RECURRENCE: Check if we missed any SCHEDULED occurrences
        let missedScheduledDays = countMissedScheduledDays(
            from: lastCompleted,
            to: completionDate,
            rule: recurrenceRule
        )

        if missedScheduledDays == 0 {
            // No missed scheduled days - streak continues
            currentStreak += 1
        } else {
            // Missed scheduled days - restart streak
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Counts how many SCHEDULED occurrences were missed
    /// For M/W/F habit: Tuesday doesn't count, but skipping Monday does
    private func countMissedScheduledDays(from startDate: Date, to endDate: Date, rule: RecurrenceRule) -> Int {
        let calendar = Calendar.current

        // Get scheduled occurrences between dates
        let scheduledOccurrences = rule.occurrences(from: startDate, limit: 100)
            .filter { occurrence in
                occurrence > startDate && occurrence < endDate
            }

        // Count scheduled days with NO completion entry
        var missedCount = 0
        for scheduledDate in scheduledOccurrences {
            let hasCompletion = completionEntriesArray.contains { completion in
                calendar.isDate(completion.completedDate, inSameDayAs: scheduledDate)
            }

            if !hasCompletion {
                missedCount += 1
            }
        }

        return missedCount
    }

    private func dueDaysInPeriod(from startDate: Date, to endDate: Date) -> Int {
        guard let recurrenceRule = recurrenceRule else {
            // Flexible habit - every day is due
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        let occurrences = recurrenceRule.occurrences(from: startDate, limit: 100)
        return occurrences.filter { $0 <= endDate }.count
    }
}

// MARK: - Equatable Conformance

extension Habit: Equatable {
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable Conformance

extension Habit: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

