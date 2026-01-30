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

    /// Alert time for habit reminders (time-of-day when notification fires)
    var alertTimeHour: Int? // 0-23
    var alertTimeMinute: Int? // 0-59

    /// When snoozed, this overrides the normal reminder time until the snooze fires
    var snoozedUntil: Date?

    /// Tracks if the reminder notification has been delivered (resets at replenishment)
    var notificationFired: Bool = false

    /// When the current instance period started (resets at replenishment time)
    /// For habits, this tracks when the current "active period" began
    /// Alerts only apply to the current instance, not future instances
    var currentInstanceDate: Date?

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

    /// Skip entries for tracking when habit was skipped
    @Relationship(deleteRule: .cascade) var skips: [HabitSkip]?

    /// Attachments (photos, documents, etc.)
    @Relationship(deleteRule: .cascade, inverse: \HabitAttachment.habit)
    var attachments: [HabitAttachment]?

    /// Subtasks/checklist items for the habit
    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask]?

    // MARK: - Computed Properties for Non-Optional Array Access

    private var tagsArray: [Tag] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    private var completionEntriesArray: [HabitCompletion] {
        get { completionEntries ?? [] }
        set { completionEntries = newValue }
    }

    private var skipsArray: [HabitSkip] {
        get { skips ?? [] }
        set { skips = newValue }
    }

    private var attachmentsArray: [HabitAttachment] {
        get { attachments ?? [] }
        set { attachments = newValue }
    }

    private var subtasksArray: [Subtask] {
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
        subtasksArray.filter(\.isCompleted).count
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

    /// Computes the effective reminder date from alertTime
    /// Uses currentInstanceDate to determine when the alert should fire for THIS instance
    /// Priority: snoozedUntil > alert time applied to instance date
    var effectiveReminderDate: Date? {
        // If snoozed, use the snooze time (overrides normal calculation)
        if let snoozed = snoozedUntil {
            return snoozed
        }

        guard let hour = alertTimeHour, let minute = alertTimeMinute else {
            return nil
        }

        // Use currentInstanceDate if available, otherwise no alert (not yet replenished)
        // This ensures alerts only apply to the current active instance
        guard let instanceDate = currentInstanceDate else {
            return nil
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: instanceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components)
    }

    /// Returns true if the habit has a future reminder/alert that hasn't fired yet
    /// and the current instance is still active (not completed)
    var hasPendingAlert: Bool {
        // No pending alert if instance is completed
        guard !isCompletedToday else { return false }

        guard let date = effectiveReminderDate else { return false }
        return date > Date() && !notificationFired
    }

    /// Short display text for alert time (e.g., "9:00 AM")
    /// Returns nil if no alert configured or no active instance
    /// Used for notification scheduling logic
    var reminderDisplayText: String? {
        guard let hour = alertTimeHour, let minute = alertTimeMinute else {
            return nil
        }

        // Only show reminder text if there's an active instance
        guard currentInstanceDate != nil else {
            return nil
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(from: components) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Display text for configured alert time - always shows the time if configured
    /// Used in detail views to show what time is set, regardless of instance state
    /// Returns nil only if no alert is configured
    var configuredAlertDisplayText: String? {
        guard let hour = alertTimeHour, let minute = alertTimeMinute else {
            return nil
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(from: components) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var subtaskProgressText: String? {
        guard hasSubtasks else { return nil }
        return "\(completedSubtaskCount)/\(subtaskCount)"
    }

    var hasRecurrence: Bool {
        recurrenceRule != nil
    }

    /// Returns subtasks ordered by their subtaskOrder property
    var orderedSubtasks: [Subtask] {
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

    func addSubtask(_ subtask: Subtask) -> Bool {
        // Assign the next order value
        let maxOrder = subtasksArray.map(\.subtaskOrder).max() ?? -1
        subtask.subtaskOrder = maxOrder + 1

        subtasksArray.append(subtask)
        subtask.parentHabit = self
        modifiedDate = Date()
        return true
    }

    func removeSubtask(_ subtask: Subtask) {
        subtasksArray.removeAll { $0 == subtask }
        subtask.parentHabit = nil
        modifiedDate = Date()
    }

    func createSubtask(title: String) -> Subtask {
        let subtask = Subtask(title: title)
        subtask.createdDate = self.createdDate  // Inherit parent's creation date
        _ = addSubtask(subtask)
        return subtask
    }

    var subtaskCompletionPercentage: Double {
        guard hasSubtasks, subtaskCount > 0 else { return 0.0 }
        return Double(completedSubtaskCount) / Double(subtaskCount)
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
    func markCompletedWithTracking(notes: String = "") -> HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if isCompletedToday {
            return nil
        }

        // Create completion entry
        let completion = HabitCompletion(
            habit: self,
            completedDate: today,
            notes: notes
        )

        // Add to completion entries
        completionEntriesArray.append(completion)

        // Update streak with simple consecutive day logic
        updateStreak(completionDate: today)

        lastCompletedDate = today
        return completion
    }

    /// Skip habit for today without breaking streak
    func skipHabit() -> HabitSkip? {
        guard canSkip() else { return nil }

        let today = Calendar.current.startOfDay(for: Date())

        let skip = HabitSkip(
            habit: self,
            skippedDate: today
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

// MARK: - Alertable Conformance

extension Habit: Alertable {
    /// For habits, completion status is determined by whether completed today
    var isItemCompleted: Bool {
        isCompletedToday
    }

    // Note: currentInstanceDate is already a stored property on Habit
    // Note: alertTimeHour, alertTimeMinute, notificationFired, snoozedUntil are stored properties
    // Note: effectiveReminderDate, hasPendingAlert, reminderDisplayText have custom implementations above
    // Note: hasAlert uses protocol default (alertTimeHour != nil)
}

