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
    @Query(sort: \Habit.createdDate, order: .reverse) private var allHabits: [Habit]
    @State private var searchText = ""
    @State private var showingAddHabit = false

    var body: some View {
        NavigationStack {
            VStack {
                if allHabits.isEmpty {
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

                        Text("Tap the + button to create your first habit!")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Habit list
                    List {
                        ForEach(allHabits) { habit in
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
                        showingAddHabit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
    }
}

// MARK: - Habit Row View

private struct HabitRowView: View {
    let habit: Habit
    @Environment(HabitManager.self) private var habitManager

    var body: some View {
        HStack {
            Button(action: {
                let _ = habitManager.markHabitCompleted(habit)
            }) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompletedToday ? Color(.systemGreen) : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(habit.isCompletedToday ? "Mark habit incomplete" : "Mark habit complete")
            .accessibilityAddTraits(.isButton)
            .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(habit.currentStreak > 0 ? Color(.systemOrange) : .secondary)
                        Text("\(habit.currentStreak) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current streak: \(habit.currentStreak) days")

                    if !habit.tags.isEmpty {
                        Text("• \(habit.tags.count) tag\(habit.tags.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                habitManager.deleteHabit(habit)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Delete habit")
            .accessibilityAddTraits(.isButton)
            .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = habit.title
        if habit.isCompletedToday {
            label += ", completed today"
        }
        label += ", \(habit.currentStreak) day streak"
        if !habit.tags.isEmpty {
            label += ", \(habit.tags.count) tag\(habit.tags.count == 1 ? "" : "s")"
        }
        return label
    }

    private var accessibilityHint: String {
        if habit.isCompletedToday {
            return "Double tap completion button to mark as incomplete"
        } else {
            return "Double tap completion button to mark as complete"
        }
    }
}

// MARK: - Add Habit View

private struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitManager.self) private var habitManager
    @State private var habitTitle = ""
    @State private var habitDescription = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Habit") {
                    TextField("Habit title", text: $habitTitle)
                    TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Text("Habit tracking features like streaks and schedules will be enhanced in future updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !habitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let _ = habitManager.createHabit(
                                title: habitTitle,
                                habitDescription: habitDescription.isEmpty ? "" : habitDescription
                            )
                            dismiss()
                        }
                    }
                    .disabled(habitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Habit.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return HabitsView()
        .modelContainer(container)
        .environment(HabitManager(modelContext: container.mainContext))
}