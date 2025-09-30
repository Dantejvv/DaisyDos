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
                            HabitRowView(
                                habit: habit,
                                onMarkComplete: {
                                    let _ = habitManager.markHabitCompleted(habit)
                                },
                                onEdit: {
                                    // TODO: Implement habit editing
                                    print("Edit habit: \(habit.title)")
                                },
                                onDelete: {
                                    habitManager.deleteHabit(habit)
                                },
                                onSkip: {
                                    // TODO: Implement habit skipping
                                    print("Skip habit: \(habit.title)")
                                },
                                onTagAssignment: {
                                    // TODO: Implement tag assignment
                                    print("Assign tags to habit: \(habit.title)")
                                }
                            )
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