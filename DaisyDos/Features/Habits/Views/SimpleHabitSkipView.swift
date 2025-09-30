//
//  SimpleHabitSkipView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI
import SwiftData

struct SimpleHabitSkipView: View {
    // MARK: - Properties

    let habit: Habit
    let onSkip: (String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var skipReason = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(habit.title)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.daisyText)
                        .multilineTextAlignment(.center)

                    Text("Skip this habit for today?")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Current streak info
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(habit.currentStreak)")
                                .font(.title.weight(.bold))
                                .foregroundColor(.daisyHabit)
                            Text("Current Streak")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }

                        VStack(spacing: 4) {
                            Text("\(habit.longestStreak)")
                                .font(.title.weight(.bold))
                                .foregroundColor(.daisySuccess)
                            Text("Best Streak")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                }

                // Optional reason
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (optional)")
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    TextField("Why are you skipping today?", text: $skipReason, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                        .autocorrectionDisabled(true)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        performSkip()
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
            .padding(20)
            .navigationTitle("Skip Habit")
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

    // MARK: - Methods

    private func performSkip() {
        let reason = skipReason.trimmingCharacters(in: .whitespacesAndNewlines)
        onSkip(reason.isEmpty ? nil : reason)
        dismiss()
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
        habitDescription: "30 minutes of cardio to start the day",
    )
    habit.currentStreak = 15
    habit.longestStreak = 28
    context.insert(habit)

    return SimpleHabitSkipView(
        habit: habit,
        onSkip: { reason in
            print("Habit skipped with reason: \(reason ?? "No reason")")
        }
    )
    .modelContainer(container)
}