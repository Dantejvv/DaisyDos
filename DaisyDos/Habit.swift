//
//  Habit.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Model
class Habit {
    var id: UUID
    var title: String
    var habitDescription: String
    var currentStreak: Int
    var longestStreak: Int
    var createdDate: Date
    var lastCompletedDate: Date?

    @Relationship(deleteRule: .nullify, inverse: \Tag.habits)
    var tags: [Tag] = []

    init(title: String, habitDescription: String = "") {
        self.id = UUID()
        self.title = title
        self.habitDescription = habitDescription
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdDate = Date()
        self.lastCompletedDate = nil
    }

    var tagCount: Int {
        tags.count
    }

    func canAddTag() -> Bool {
        return tagCount < 3
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tags.contains(tag) {
            tags.append(tag)
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll { $0 == tag }
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

    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }

    func canMarkCompleted() -> Bool {
        return !isCompletedToday
    }
}