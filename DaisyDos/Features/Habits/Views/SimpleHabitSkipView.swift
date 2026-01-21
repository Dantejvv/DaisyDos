//
//  SimpleHabitSkipView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI
import SwiftData

/// Simple confirmation dialog for skipping a habit
struct SimpleHabitSkipView: View {
    // MARK: - Properties

    let habit: Habit
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "forward.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                // Header
                VStack(spacing: 8) {
                    Text("Skip Habit")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.daisyText)

                    Text("Skip \"\(habit.title)\" for today?")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Streak info - reassure user streak won't break
                if habit.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Your \(habit.currentStreak) day streak will be preserved")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSkip()
                        dismiss()
                    }) {
                        Text("Skip Today")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Simple Skip View") {
    let container = try! ModelContainer(
        for: Habit.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let habit = Habit(
        title: "Morning Exercise",
        habitDescription: "30 minutes of cardio"
    )
    habit.currentStreak = 15
    context.insert(habit)

    return SimpleHabitSkipView(
        habit: habit,
        onSkip: {
            print("Habit skipped")
        }
    )
    .modelContainer(container)
}

#Preview("No Streak") {
    let container = try! ModelContainer(
        for: Habit.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let habit = Habit(
        title: "New Habit",
        habitDescription: "Just started"
    )
    habit.currentStreak = 0
    context.insert(habit)

    return SimpleHabitSkipView(
        habit: habit,
        onSkip: {
            print("Habit skipped")
        }
    )
    .modelContainer(container)
}
