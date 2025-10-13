//
//  CompletionAggregate.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Aggregated statistics for completion history (366+ days)
//

import Foundation
import SwiftData

@Model
class CompletionAggregate {
    // MARK: - Core Properties

    var id: UUID

    var period: Date  // Start of day/month
    var periodType: PeriodType

    // MARK: - Completion Statistics

    var tasksCompleted: Int
    var tasksByPriority: [String: Int]  // Priority.rawValue -> count
    var averageCompletionDuration: TimeInterval
    var overdueCompletionCount: Int

    // MARK: - Additional Metrics

    var totalSubtasksCompleted: Int
    var averageSubtasksPerTask: Double

    // MARK: - Period Type Enum

    enum PeriodType: String, Codable, CaseIterable {
        case daily = "Daily"
        case monthly = "Monthly"

        var displayName: String { rawValue }
    }

    // MARK: - Initializers

    init(
        period: Date,
        periodType: PeriodType,
        tasksCompleted: Int,
        tasksByPriority: [Priority: Int] = [:],
        averageCompletionDuration: TimeInterval = 0,
        overdueCompletionCount: Int = 0,
        totalSubtasksCompleted: Int = 0,
        averageSubtasksPerTask: Double = 0
    ) {
        self.id = UUID()
        self.period = period
        self.periodType = periodType
        self.tasksCompleted = tasksCompleted
        // Convert Priority enum to String keys for SwiftData compatibility
        self.tasksByPriority = Dictionary(
            uniqueKeysWithValues: tasksByPriority.map { ($0.key.rawValue, $0.value) }
        )
        self.averageCompletionDuration = averageCompletionDuration
        self.overdueCompletionCount = overdueCompletionCount
        self.totalSubtasksCompleted = totalSubtasksCompleted
        self.averageSubtasksPerTask = averageSubtasksPerTask
    }

    // MARK: - Helper Methods

    /// Get completion count for specific priority
    func count(for priority: Priority) -> Int {
        return tasksByPriority[priority.rawValue] ?? 0
    }

    /// Formatted period display
    var formattedPeriod: String {
        let formatter = DateFormatter()
        switch periodType {
        case .daily:
            formatter.dateFormat = "MMM d, yyyy"
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: period)
    }

    /// Average duration formatted
    var formattedAverageDuration: String {
        let days = Int(averageCompletionDuration / 86400)
        let hours = Int((averageCompletionDuration.truncatingRemainder(dividingBy: 86400)) / 3600)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(averageCompletionDuration / 60)
            return "\(minutes)m"
        }
    }

    /// Completion rate (tasks completed / tasks created) - requires additional tracking
    var completionEfficiency: Double {
        // This would require tracking created tasks as well
        // For now, return a placeholder
        return 1.0
    }
}

// MARK: - Identifiable Conformance

extension CompletionAggregate: Identifiable {}
