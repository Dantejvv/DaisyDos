//
//  LogbookManager.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Manages logbook operations: archival, cleanup, and queries
//

import Foundation
import SwiftData

@Observable
class LogbookManager {
    internal let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    // Housekeeping statistics
    struct HousekeepingStats {
        var tasksArchived: Int = 0
        var logsDeleted: Int = 0
        var aggregatesCreated: Int = 0
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Housekeeping Operations

    /// Performs all housekeeping operations: archive old tasks, cleanup old logs
    func performHousekeeping() -> Result<HousekeepingStats, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "logbook housekeeping",
            entityType: "logbook"
        ) {
            var stats = HousekeepingStats()

            // Archive tasks completed 90+ days ago
            stats.tasksArchived = try archiveTasks(olderThanDays: 90)

            // Delete log entries 365+ days old
            stats.logsDeleted = try cleanupLogEntries(olderThanDays: 365)

            return stats
        }
    }

    // MARK: - Archival Logic

    /// Archive tasks completed more than specified days ago
    /// Converts Task -> TaskLogEntry and deletes original task (with attachments)
    private func archiveTasks(olderThanDays days: Int) throws -> Int {
        // Calculate cutoff date using local variable (SwiftData #Predicate requirement)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted &&
                task.completedDate != nil &&
                task.completedDate! < cutoffDate
            }
        )

        let tasksToArchive = try modelContext.fetch(descriptor)

        for task in tasksToArchive {
            // Create lightweight log entry
            let logEntry = TaskLogEntry(from: task)
            modelContext.insert(logEntry)

            // Delete task (cascades to attachments automatically via SwiftData)
            modelContext.delete(task)
        }

        if !tasksToArchive.isEmpty {
            try modelContext.save()
        }

        return tasksToArchive.count
    }

    /// Delete log entries older than specified days
    private func cleanupLogEntries(olderThanDays days: Int) throws -> Int {
        // Calculate cutoff date using local variable
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let descriptor = FetchDescriptor<TaskLogEntry>(
            predicate: #Predicate<TaskLogEntry> { entry in
                entry.completedDate < cutoffDate
            }
        )

        let entriesToDelete = try modelContext.fetch(descriptor)

        for entry in entriesToDelete {
            modelContext.delete(entry)
        }

        if !entriesToDelete.isEmpty {
            try modelContext.save()
        }

        return entriesToDelete.count
    }

    // MARK: - Query Methods

    /// Get recent completions (still in Task table)
    func recentCompletions(days: Int = 30) -> [Task] {
        // Query ALL completed tasks first (no date filter)
        // Note: We fetch all and filter manually because SwiftData #Predicate
        // has issues with optional Date comparisons
        let allCompletedDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.isCompleted },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )

        let allCompleted = (try? modelContext.fetch(allCompletedDescriptor)) ?? []

        // Filter manually in Swift
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return allCompleted.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= cutoffDate
        }
    }

    /// Get archived completions (in TaskLogEntry table)
    func archivedCompletions(from startDate: Date, to endDate: Date) -> [TaskLogEntry] {
        let descriptor = FetchDescriptor<TaskLogEntry>(
            predicate: #Predicate<TaskLogEntry> { entry in
                entry.completedDate >= startDate &&
                entry.completedDate <= endDate
            },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Search completed tasks by query
    func searchCompletions(query: String, days: Int = 90) -> [Task] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return recentCompletions(days: days) }

        // Fetch all completed tasks and filter manually
        let allCompletedDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.isCompleted },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )

        let allCompleted = (try? modelContext.fetch(allCompletedDescriptor)) ?? []

        // Filter by date and search query manually
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let lowercaseQuery = trimmedQuery.lowercased()

        return allCompleted.filter { task in
            guard let completedDate = task.completedDate,
                  completedDate >= cutoffDate else { return false }

            return task.title.lowercased().contains(lowercaseQuery) ||
                   task.taskDescription.lowercased().contains(lowercaseQuery)
        }
    }

}
