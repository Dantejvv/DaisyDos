//
//  HabitManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

// MARK: - Subtask Completion Cascade Behavior
//
// DESIGN DECISION: Simplified one-way cascade (parent → subtasks only)
//
// WHEN HABIT IS MARKED COMPLETE TODAY:
// - All subtasks automatically complete for today (CASCADE DOWN)
// - Ensures data consistency (habit can't be "done" with incomplete subtasks)
//
// WHEN HABIT COMPLETION IS UNDONE:
// - Subtasks retain their completion state for today (NO CASCADE)
// - Note: Subtasks reset daily anyway (isCompletedToday resets at midnight)
//
// WHEN INDIVIDUAL SUBTASK IS TOGGLED:
// - Parent habit state UNCHANGED (NO PROPAGATION UP)
// - Users can complete subtasks without forcing habit completion
// - Removed complexity: toggleHabitSubtaskCompletion() is now simple
//
// RATIONALE:
// - Habits track daily behavioral patterns, not discrete work items
// - Subtasks are supporting milestones, not required completions
// - Daily reset makes the cascade behavior less critical than for tasks
//
// See also: TaskManager+Subtasks.swift for similar task cascade logic

import Foundation
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    static let habitDidChange = Notification.Name("habitDidChange")
    static let habitWasDeleted = Notification.Name("habitWasDeleted")
    static let habitWasCompleted = Notification.Name("habitWasCompleted")
}

@Observable
class HabitManager: EntityManagerProtocol {
    typealias Entity = Habit

    let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var activeHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.currentStreak >= 0
            },
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var completedTodayHabits: [Habit] {
        // Fetch all habits and filter in memory since isCompletedToday is a computed property
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        let allHabits = (try? modelContext.fetch(descriptor)) ?? []
        return allHabits.filter { $0.isCompletedToday }
    }

    var pendingTodayHabits: [Habit] {
        // Fetch all habits and filter in memory since isCompletedToday is a computed property
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        let allHabits = (try? modelContext.fetch(descriptor)) ?? []
        return allHabits.filter { !$0.isCompletedToday }
    }

    var habitsByStreak: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func createHabit(title: String, habitDescription: String = "", isCustomSortActive: Bool = false) -> Result<Habit, AnyRecoverableError> {
        let result = ErrorTransformer.safely(
            operation: "create habit",
            entityType: "habit"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // If in custom sort mode, increment all existing habits to make room at position 0
            if isCustomSortActive {
                for habit in allHabits {
                    habit.habitOrder += 1
                }
            }

            let habit = Habit(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                habitDescription: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            // Set order to 0 for custom mode, or assign next sequential order for other modes
            if isCustomSortActive {
                habit.habitOrder = 0
            } else {
                // For non-custom modes, assign the next available order value
                let maxOrder = allHabits.map(\.habitOrder).max() ?? -1
                habit.habitOrder = maxOrder + 1
            }

            modelContext.insert(habit)
            try modelContext.save()
            return habit
        }

        // Notify after successful creation for notification scheduling
        if case .success(let habit) = result {
            notifyHabitChanged(habit)
        }

        return result
    }

    func updateHabit(_ habit: Habit, title: String? = nil, habitDescription: String? = nil) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update habit",
            entityType: "habit"
        ) {
            var hasChanges = false

            if let title = title {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    throw DaisyDosError.validationFailed("title")
                }
                habit.title = trimmedTitle
                hasChanges = true
            }

            if let habitDescription = habitDescription {
                habit.habitDescription = habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                hasChanges = true
            }

            if hasChanges {
                habit.modifiedDate = Date()
                try modelContext.save()

                // Reschedule notifications if title changed (for notification body)
                notifyHabitChanged(habit)
            }
        }
    }

    /// Notify that a habit has changed and needs notification rescheduling
    /// This should be called after any changes that affect notifications (title, recurrence, etc.)
    private func notifyHabitChanged(_ habit: Habit) {
        // Post notification for HabitNotificationManager to observe
        NotificationCenter.default.post(
            name: .habitDidChange,
            object: nil,
            userInfo: ["habitId": habit.id.uuidString]
        )
    }

    func markHabitCompleted(_ habit: Habit) -> Bool {
        guard habit.canMarkCompleted() else {
            return false // Already completed today
        }

        habit.markCompleted()

        do {
            try modelContext.save()
            notifyHabitCompleted(habit)
            return true
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "mark habit completed")
            return false
        }
    }

    /// Mark habit completed with detailed tracking
    func markHabitCompletedWithTracking(_ habit: Habit, notes: String = "") -> HabitCompletion? {
        guard habit.canMarkCompleted() else {
            return nil // Already completed today
        }

        let completion = habit.markCompletedWithTracking(notes: notes)

        if let completion = completion {
            modelContext.insert(completion)
        }

        // CASCADE: When habit is marked complete today, complete all subtasks
        // This ensures data consistency and provides clear completion state
        for subtask in (habit.subtasks ?? []) {
            if !subtask.isCompletedToday {
                subtask.isCompletedToday = true
                subtask.lastCompletedDate = Date()
                subtask.modifiedDate = Date()
            }
        }

        do {
            try modelContext.save()
            notifyHabitCompleted(habit)
            return completion
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "mark habit completed with tracking")
            return nil
        }
    }

    /// Notify that a habit was completed today (for notification rescheduling)
    private func notifyHabitCompleted(_ habit: Habit) {
        NotificationCenter.default.post(
            name: .habitWasCompleted,
            object: nil,
            userInfo: ["habitId": habit.id.uuidString]
        )
    }

    /// Undo today's habit completion
    func undoHabitCompletion(_ habit: Habit) -> Bool {
        guard habit.undoTodaysCompletion() else {
            return false // Nothing to undo
        }

        do {
            try modelContext.save()
            return true
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "undo habit completion")
            return false
        }
    }

    func skipHabit(_ habit: Habit, reason: String? = nil) -> HabitSkip? {
        guard let skip = habit.skipHabit(reason: reason) else {
            return nil // Already completed or skipped today
        }

        // Insert the skip into the model context
        modelContext.insert(skip)

        do {
            try modelContext.save()
            return skip
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "skip habit")
            return nil
        }
    }

    func resetHabitStreak(_ habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "reset habit streak",
            entityType: "habit"
        ) {
            habit.resetStreak()
            try modelContext.save()
        }
    }

    func deleteHabit(_ habit: Habit) -> Result<Void, AnyRecoverableError> {
        let habitId = habit.id.uuidString // Capture before deletion
        return ErrorTransformer.safely(
            operation: "delete habit",
            entityType: "habit"
        ) {
            modelContext.delete(habit)
            try modelContext.save()

            // Notify that habit was deleted to cleanup notifications
            NotificationCenter.default.post(
                name: .habitWasDeleted,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
    }

    func deleteHabits(_ habits: [Habit]) -> Result<Void, AnyRecoverableError> {
        let habitIds = habits.map { $0.id.uuidString } // Capture before deletion
        return ErrorTransformer.safely(
            operation: "delete habits",
            entityType: "habits"
        ) {
            for habit in habits {
                modelContext.delete(habit)
            }
            try modelContext.save()

            // Notify that habits were deleted to cleanup notifications
            for habitId in habitIds {
                NotificationCenter.default.post(
                    name: .habitWasDeleted,
                    object: nil,
                    userInfo: ["habitId": habitId]
                )
            }
        }
    }

    // MARK: - Custom Ordering

    /// Update a single habit's order value
    func updateHabitOrder(_ habit: Habit, newOrder: Int) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update habit order",
            entityType: "habit"
        ) {
            habit.habitOrder = newOrder
            habit.modifiedDate = Date()
            try modelContext.save()
        }
    }

    /// Bulk update habit orders after drag-and-drop reordering
    func reorderHabits(_ habits: [Habit]) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "reorder habits",
            entityType: "habits"
        ) {
            for (index, habit) in habits.enumerated() {
                habit.habitOrder = index
                habit.modifiedDate = Date()
            }
            try modelContext.save()
        }
    }

    /// Get the next order value for new habits in custom sort mode
    /// Returns 0 for new habits (existing habits will be incremented)
    func getNextOrderValue() -> Int {
        return 0
    }

    /// Increment all habit orders by 1 to make room for a new habit at position 0
    func incrementAllHabitOrders() -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "increment habit orders",
            entityType: "habits"
        ) {
            for habit in allHabits {
                habit.habitOrder += 1
                habit.modifiedDate = Date()
            }
            try modelContext.save()
        }
    }

    // MARK: - Habit Duplication

    func duplicateHabit(_ habit: Habit) -> Result<Habit, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "duplicate habit",
            entityType: "habit"
        ) {
            let trimmedTitle = habit.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // Create new habit with "(Copy)" suffix
            let duplicateTitle = "\(trimmedTitle) (Copy)"

            let duplicateHabit = Habit(
                title: duplicateTitle,
                habitDescription: habit.habitDescription,
                recurrenceRule: habit.recurrenceRule,
                priority: habit.priority
            )

            modelContext.insert(duplicateHabit)

            // Copy tags
            for tag in habit.tags ?? [] {
                _ = duplicateHabit.addTag(tag)
            }

            // Copy subtasks
            for subtask in (habit.subtasks ?? []) {
                let duplicateSubtask = HabitSubtask(title: subtask.title)
                duplicateSubtask.subtaskOrder = subtask.subtaskOrder

                if duplicateHabit.subtasks == nil {
                    duplicateHabit.subtasks = []
                }
                duplicateHabit.subtasks?.append(duplicateSubtask)
                modelContext.insert(duplicateSubtask)
            }

            // Copy attachments
            for attachment in habit.attachments ?? [] {
                let duplicateAttachment = HabitAttachment(
                    fileName: attachment.fileName,
                    fileSize: attachment.fileSize,
                    mimeType: attachment.mimeType,
                    fileData: attachment.fileData,
                    thumbnailData: attachment.thumbnailData
                )
                if duplicateHabit.attachments == nil {
                    duplicateHabit.attachments = []
                }
                duplicateHabit.attachments?.append(duplicateAttachment)
                modelContext.insert(duplicateAttachment)
            }

            try modelContext.save()
            return duplicateHabit
        }
    }

    /// Duplicate a habit and handle errors internally
    func duplicateHabitSafely(_ habit: Habit) -> Habit? {
        switch duplicateHabit(habit) {
        case .success(let duplicatedHabit):
            return duplicatedHabit
        case .failure(let error):
            lastError = error.wrapped
            return nil
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: Tag, to habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "add tag to habit",
            entityType: "habit"
        ) {
            guard habit.addTag(tag) else {
                throw DaisyDosError.tagLimitExceeded
            }
            try modelContext.save()
        }
    }

    func removeTag(_ tag: Tag, from habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "remove tag from habit",
            entityType: "habit"
        ) {
            habit.removeTag(tag)
            try modelContext.save()
        }
    }

    // MARK: - Subtask Management

    func createHabitSubtask(for habit: Habit, title: String) -> Result<HabitSubtask, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "create habit subtask",
            entityType: "subtask"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // Create subtask object
            let subtask = HabitSubtask(title: title.trimmingCharacters(in: .whitespacesAndNewlines))

            // Inherit parent's creation date
            subtask.createdDate = habit.createdDate

            // Insert into context FIRST so SwiftData can track the relationship
            modelContext.insert(subtask)

            // THEN establish the relationship (this is now tracked by SwiftData)
            _ = habit.addSubtask(subtask)

            try modelContext.save()
            return subtask
        }
    }

    /// Batch create multiple habit subtasks - follows SwiftData best practice of inserting all objects before manipulating relationships
    func createHabitSubtasks(
        for habit: Habit,
        titles: [(title: String, order: Int)]
    ) -> Result<[HabitSubtask], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "create habit subtasks",
            entityType: "subtask"
        ) {
            var createdSubtasks: [HabitSubtask] = []

            // Step 1: Create and insert ALL subtask objects FIRST
            for (title, order) in titles {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else { continue }

                let subtask = HabitSubtask(title: trimmedTitle)
                subtask.createdDate = habit.createdDate
                subtask.subtaskOrder = order

                modelContext.insert(subtask)
                createdSubtasks.append(subtask)
            }

            // Step 2: THEN establish relationships after all are inserted
            for subtask in createdSubtasks {
                _ = habit.addSubtask(subtask)
            }

            // Step 3: Save once at the end
            try modelContext.save()

            return createdSubtasks
        }
    }

    func updateHabitSubtask(_ subtask: HabitSubtask, title: String) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update habit subtask",
            entityType: "subtask"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            subtask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            subtask.modifiedDate = Date()
            try modelContext.save()
        }
    }

    func deleteHabitSubtask(_ subtask: HabitSubtask, from habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "delete habit subtask",
            entityType: "subtask"
        ) {
            habit.removeSubtask(subtask)
            modelContext.delete(subtask)
            try modelContext.save()
        }
    }

    func toggleHabitSubtaskCompletion(_ subtask: HabitSubtask) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle habit subtask completion",
            entityType: "subtask"
        ) {
            subtask.toggleCompletion()
            try modelContext.save()
        }
    }

    // MARK: - Search and Filtering

    func searchHabits(query: String) -> [Habit] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allHabits
        }

        // Manual filtering because habitDescription is a computed property
        // and can't be used in #Predicate
        return allHabits.filter { habit in
            habit.title.localizedStandardContains(query) ||
            habit.habitDescription.localizedStandardContains(query)
        }
    }

    func habitsWithTag(_ tag: Tag) -> [Habit] {
        // For now, fetch all habits and filter in memory since @Predicate with contains is complex
        return allHabits.filter { habit in
            habit.tags?.contains { $0.id == tag.id } ?? false
        }
    }

    // MARK: - Statistics and Analytics

    var habitCount: Int {
        allHabits.count
    }

    var completedTodayCount: Int {
        completedTodayHabits.count
    }

    var pendingTodayCount: Int {
        pendingTodayHabits.count
    }

    var todayCompletionRate: Double {
        guard habitCount > 0 else { return 0.0 }
        return Double(completedTodayCount) / Double(habitCount)
    }

    var averageStreak: Double {
        let habits = allHabits
        guard !habits.isEmpty else { return 0.0 }
        let totalStreak = habits.reduce(0) { $0 + $1.currentStreak }
        return Double(totalStreak) / Double(habits.count)
    }

    var longestActiveStreak: Int {
        allHabits.map(\.currentStreak).max() ?? 0
    }

    var longestEverStreak: Int {
        allHabits.map(\.longestStreak).max() ?? 0
    }

    // MARK: - Helper Properties

    var habitsCompletableToday: [Habit] {
        allHabits.filter { $0.canMarkCompleted() }
    }

    var habitsDueToday: [Habit] {
        // For now, all habits are considered "due" every day
        // This can be enhanced with recurrence rules in future phases
        return allHabits
    }
}