//
//  HabitsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(HabitManager.self) private var habitManager
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if habitManager.allHabits.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "repeat.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No Habits Yet")
                            .font(.title2.bold())

                        Text("Build positive routines by creating your first habit. Consistency is key to success!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Habit creation will be available in future updates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Habit list
                    List {
                        ForEach(habitManager.allHabits) { habit in
                            HabitRowView(habit: habit)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add habit creation
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(true) // Disabled until implementation
                }
            }
        }
    }
}

// MARK: - Habit Row View

private struct HabitRowView: View {
    let habit: Habit

    var body: some View {
        HStack {
            Button(action: {
                // TODO: Implement habit completion
            }) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompletedToday ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(true) // Disabled until implementation

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(habit.currentStreak > 0 ? .orange : .secondary)
                        Text("\(habit.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !habit.tags.isEmpty {
                        Text("• \(habit.tags.count) tag\(habit.tags.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = try! ModelContainer(for: Habit.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return HabitsView()
        .modelContainer(container)
        .environment(HabitManager(modelContext: container.mainContext))
}