//
//  UnifiedTodayRow.swift
//  DaisyDos
//
//  Created by Claude Code on 1/2/25.
//

import SwiftUI

/// Unified row component that renders either a TaskRowView or HabitRowView
struct UnifiedTodayRow: View {
    let item: TodayItem
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: (() -> Void)? // Only for habits
    let onReschedule: (() -> Void)? // Only for tasks

    var body: some View {
        Group {
            switch item {
            case .task(let task):
                TaskRowView(
                    task: task,
                    onToggleCompletion: onToggleCompletion,
                    onEdit: onEdit,
                    onDelete: onDelete
                )

            case .habit(let habit):
                HabitRowView(
                    habit: habit,
                    onMarkComplete: onToggleCompletion,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onSkip: onSkip ?? {}
                )
            }
        }
    }
}
