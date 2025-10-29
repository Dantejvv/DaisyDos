//
//  HabitCompletionUndoToast.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Habit-specific undo toast - now uses generic CompletionUndoToast component
//

import SwiftUI
import SwiftData

// MARK: - Type Aliases (for backwards compatibility)

/// Type alias for HabitCompletionUndoToast using the generic component
typealias HabitCompletionUndoToast = CompletionUndoToast<Habit>

/// Type alias for HabitCompletionToastManager using the generic component
/// Already defined in CompletionUndoToast.swift

/// Type alias for HabitCompletionToastContainer using the generic component
/// Already defined in CompletionUndoToast.swift

// MARK: - Preview

#Preview("Habit Undo Toast") {
    struct PreviewWrapper: View {
        var body: some View {
            let container = try! ModelContainer(
                for: Habit.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let habit = Habit(
                title: "Morning Exercise",
                habitDescription: "30 minutes of cardio",
                recurrenceRule: RecurrenceRule(frequency: .daily, interval: 1)
            )
            context.insert(habit)

            return VStack {
                Spacer()

                CompletionUndoToast(
                    entity: habit,
                    config: .habit(),
                    onUndo: {
                        print("Undo tapped")
                    },
                    isVisible: .constant(true)
                )
                .padding()

                Spacer()
            }
            .background(Color.daisyBackground)
            .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

#Preview("Habit Toast Container") {
    CompletionToastContainer(config: .habit()) {
        VStack {
            Text("Main Content")
                .font(.title)

            Button("Test Toast") {
                // This would trigger a toast in real usage
            }
            .padding()
        }
    }
}
