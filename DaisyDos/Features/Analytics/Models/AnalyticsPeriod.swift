//
//  AnalyticsPeriod.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import Foundation

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case year = "Year"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .ninetyDays: return "90 Days"
        case .year: return "This Year"
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .year: return 365
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .sevenDays, .thirtyDays, .ninetyDays:
            return calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        case .year:
            return calendar.startOfYear(for: Date())
        }
    }

    var endDate: Date {
        return Date()
    }
}

extension Calendar {
    func startOfYear(for date: Date) -> Date {
        let components = self.dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
}
