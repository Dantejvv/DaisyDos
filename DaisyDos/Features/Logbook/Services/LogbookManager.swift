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
        var tasksDeleted: Int = 0
        var logsDeleted: Int = 0
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Housekeeping Operations

    /// Performs all housekeeping operations: archive old tasks, cleanup old logs
    func performHousekeeping() -> Result<HousekeepingStats, AnyRecoverableError> {
        #if DEBUG
        print("\n🧹 [Housekeeping] Starting housekeeping at \(Date())")
        #endif

        return ErrorTransformer.safely(
            operation: "logbook housekeeping",
            entityType: "logbook"
        ) {
            var stats = HousekeepingStats()

            // Step 1: Archive tasks in the 91-365 day range FIRST (create log entries)
            stats.tasksArchived = try archiveTasks(olderThanDays: 91, newerThanDays: 365)

            // Step 2: Delete very old tasks (366+ days) - tasks exactly 365 days already archived above
            stats.tasksDeleted = try deleteOldTasks(olderThanDays: 366)

            // Step 3: Delete very old log entries (365+ days)
            stats.logsDeleted = try cleanupLogEntries(olderThanDays: 365)

            #if DEBUG
            print("✅ [Housekeeping] Complete - Deleted: \(stats.tasksDeleted), Archived: \(stats.tasksArchived), Logs deleted: \(stats.logsDeleted)\n")
            #endif

            return stats
        }
    }

    // MARK: - Archival Logic

    /// Delete very old completed tasks (365+ days) without creating log entries
    /// These are too old to need archival - just delete them entirely
    private func deleteOldTasks(olderThanDays days: Int) throws -> Int {
        // Calculate cutoff date
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            #if DEBUG
            print("⚠️ [Housekeeping] Failed to calculate cutoff date")
            #endif
            return 0
        }

        #if DEBUG
        print("🗑️ [Housekeeping] Looking for tasks to DELETE (365+ days old)")
        print("   Cutoff date: \(cutoffDate)")
        #endif

        // Fetch ALL completed tasks (SwiftData #Predicate has issues with optional Date comparisons)
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in task.isCompleted }
        )

        let allCompleted = try modelContext.fetch(descriptor)

        // Filter manually in Swift
        // Note: age > 365 days (strictly greater than 365)
        // IMPORTANT: Only delete root tasks (parentTask == nil)
        // Subtasks are deleted via cascade when parent is deleted
        let tasksToDelete = allCompleted.filter { task in
            guard let completedDate = task.completedDate else { return false }
            let isOldEnough = completedDate < cutoffDate
            let isRootTask = task.parentTask == nil
            return isOldEnough && isRootTask
        }

        #if DEBUG
        print("   Total completed tasks: \(allCompleted.count)")
        print("   Found \(tasksToDelete.count) tasks to delete:")
        for task in tasksToDelete {
            print("   - \(task.title) (completed: \(task.completedDate ?? Date()))")
        }
        #endif

        for task in tasksToDelete {
            // Delete task directly (cascades to attachments automatically via SwiftData)
            modelContext.delete(task)
        }

        if !tasksToDelete.isEmpty {
            try modelContext.save()
        }

        return tasksToDelete.count
    }

    /// Archive tasks completed in the 91-365 day range
    /// Converts Task -> TaskLogEntry and deletes original task (with attachments)
    private func archiveTasks(olderThanDays olderDays: Int, newerThanDays newerDays: Int) throws -> Int {
        // Calculate cutoff dates
        guard let olderCutoff = Calendar.current.date(byAdding: .day, value: -olderDays, to: Date()),
              let newerCutoff = Calendar.current.date(byAdding: .day, value: -newerDays, to: Date()) else {
            #if DEBUG
            print("⚠️ [Housekeeping] Failed to calculate cutoff dates")
            #endif
            return 0
        }

        #if DEBUG
        print("📦 [Housekeeping] Looking for tasks to ARCHIVE (91-365 days old)")
        print("   Older cutoff (91 days): \(olderCutoff)")
        print("   Newer cutoff (365 days): \(newerCutoff)")
        #endif

        // Fetch ALL completed tasks (SwiftData #Predicate has issues with optional Date comparisons)
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in task.isCompleted }
        )

        let allCompleted = try modelContext.fetch(descriptor)

        // Filter manually in Swift for date range
        // Note: 91 <= age <= 365 (inclusive at both ends)
        // IMPORTANT: Only archive root tasks (parentTask == nil)
        // Subtasks are deleted via cascade when parent is archived
        let tasksToArchive = allCompleted.filter { task in
            guard let completedDate = task.completedDate else { return false }
            let isInDateRange = completedDate < olderCutoff && completedDate >= newerCutoff
            let isRootTask = task.parentTask == nil
            return isInDateRange && isRootTask
        }

        #if DEBUG
        print("   Total completed tasks: \(allCompleted.count)")
        print("   Found \(tasksToArchive.count) tasks to archive:")
        for task in tasksToArchive {
            print("   - \(task.title) (completed: \(task.completedDate ?? Date()))")
        }
        #endif

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
        // Calculate cutoff date
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            #if DEBUG
            print("⚠️ [Housekeeping] Failed to calculate cutoff date")
            #endif
            return 0
        }

        #if DEBUG
        print("🗄️ [Housekeeping] Looking for log entries to DELETE (365+ days old)")
        print("   Cutoff date: \(cutoffDate)")
        #endif

        // Fetch ALL log entries (using manual filter for consistency with other methods)
        let descriptor = FetchDescriptor<TaskLogEntry>()
        let allEntries = try modelContext.fetch(descriptor)

        // Filter manually in Swift
        let entriesToDelete = allEntries.filter { entry in
            entry.completedDate < cutoffDate
        }

        #if DEBUG
        print("   Total log entries: \(allEntries.count)")
        print("   Found \(entriesToDelete.count) log entries to delete")
        #endif

        for entry in entriesToDelete {
            modelContext.delete(entry)
        }

        if !entriesToDelete.isEmpty {
            try modelContext.save()
        }

        return entriesToDelete.count
    }

}
