//
//  DetailViewHelpers.swift
//  DaisyDos
//
//  Created by Claude Code on 11/11/25.
//  Shared utility methods for detail views
//
//  PURPOSE: Extract duplicate helper methods from TaskDetailView and HabitDetailView
//  to eliminate ~60 lines of duplicate code per detail view
//

import Foundation

/// Shared formatting utilities for detail views
/// Used by: TaskDetailView, HabitDetailView
enum DetailViewHelpers {

    // MARK: - Date Formatting

    /// Format relative date for display (e.g., "in 3 days", "Tomorrow", "Today")
    /// - Parameter date: The date to format
    /// - Returns: Human-readable relative date string
    ///
    /// Examples:
    /// - Past: "Overdue"
    /// - Today: "Today"
    /// - Tomorrow: "Tomorrow"
    /// - Future: "in 3 days", "in 2 months", "in 1 year"
    static func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now, to: date)

        // Handle past dates
        if date < now {
            return "Overdue"
        }

        // Handle today
        if calendar.isDateInToday(date) {
            return "Today"
        }

        // Handle tomorrow
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        // Calculate total components
        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        var parts: [String] = []

        if years > 0 {
            parts.append("\(years) \(years == 1 ? "year" : "years")")
        }

        if months > 0 {
            parts.append("\(months) \(months == 1 ? "month" : "months")")
        }

        if days > 0 {
            parts.append("\(days) \(days == 1 ? "day" : "days")")
        }

        if parts.isEmpty {
            return "Less than 1 day"
        }

        return "in " + parts.joined(separator: ", ")
    }

    // MARK: - Time Interval Formatting

    /// Format alert time interval for display (e.g., "1 day before", "30 minutes before")
    /// - Parameter interval: Time interval in seconds
    /// - Returns: Human-readable alert interval string
    ///
    /// Examples:
    /// - 0 seconds: "At time of event"
    /// - 1800 seconds (30 min): "30 minutes before"
    /// - 3600 seconds (1 hour): "1 hour before"
    /// - 86400 seconds (1 day): "1 day before"
    static func formatAlertInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") before"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") before"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") before"
        } else {
            return "At time of event"
        }
    }
}
