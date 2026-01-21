//
//  ReminderOffset.swift
//  DaisyDos
//
//  Created by Claude Code on 1/19/26.
//  Defines relative reminder offset presets for recurring tasks and habits
//

import Foundation

/// Represents preset reminder offset options for recurring tasks and habits
/// Offsets are stored as negative TimeIntervals (seconds before the event)
enum ReminderOffset: TimeInterval, CaseIterable, Identifiable {
    /// At the time of the event (0 offset)
    case atTime = 0
    /// 15 minutes before
    case fifteenMinutesBefore = -900
    /// 30 minutes before
    case thirtyMinutesBefore = -1800
    /// 1 hour before
    case oneHourBefore = -3600
    /// 2 hours before
    case twoHoursBefore = -7200
    /// 1 day before
    case oneDayBefore = -86400

    var id: TimeInterval { rawValue }

    /// Display name for the offset option
    var displayName: String {
        switch self {
        case .atTime:
            return "At time of event"
        case .fifteenMinutesBefore:
            return "15 minutes before"
        case .thirtyMinutesBefore:
            return "30 minutes before"
        case .oneHourBefore:
            return "1 hour before"
        case .twoHoursBefore:
            return "2 hours before"
        case .oneDayBefore:
            return "1 day before"
        }
    }

    /// Short display text for toolbar labels
    var shortDisplayText: String {
        switch self {
        case .atTime:
            return "At time"
        case .fifteenMinutesBefore:
            return "15m before"
        case .thirtyMinutesBefore:
            return "30m before"
        case .oneHourBefore:
            return "1h before"
        case .twoHoursBefore:
            return "2h before"
        case .oneDayBefore:
            return "1d before"
        }
    }

    /// SF Symbol name for the offset option
    var symbolName: String {
        switch self {
        case .atTime:
            return "bell.badge"
        case .fifteenMinutesBefore, .thirtyMinutesBefore:
            return "clock"
        case .oneHourBefore, .twoHoursBefore:
            return "clock.arrow.circlepath"
        case .oneDayBefore:
            return "calendar.badge.clock"
        }
    }

    /// Creates a ReminderOffset from a raw TimeInterval value
    /// Returns nil if the value doesn't match a preset
    static func from(timeInterval: TimeInterval?) -> ReminderOffset? {
        guard let interval = timeInterval else { return nil }
        return ReminderOffset(rawValue: interval)
    }

    /// Returns the display text for a given TimeInterval offset
    /// Falls back to a formatted description if not a preset value
    static func displayText(for offset: TimeInterval) -> String {
        if let preset = ReminderOffset(rawValue: offset) {
            return preset.shortDisplayText
        }

        // Fallback for custom offsets (shouldn't happen with presets-only UI)
        let absOffset = abs(offset)
        if absOffset < 60 {
            return "\(Int(absOffset))s before"
        } else if absOffset < 3600 {
            return "\(Int(absOffset / 60))m before"
        } else if absOffset < 86400 {
            return "\(Int(absOffset / 3600))h before"
        } else {
            return "\(Int(absOffset / 86400))d before"
        }
    }
}
