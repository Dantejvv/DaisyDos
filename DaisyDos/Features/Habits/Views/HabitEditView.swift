//
//  HabitEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct HabitEditView: View {
    // MARK: - Properties

    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var habitManager: HabitManager
    @State private var title: String
    @State private var habitDescription: String

    // MARK: - Initializer

    init(habit: Habit) {
        self.habit = habit
        self._habitManager = State(initialValue: HabitManager(modelContext: ModelContext(habit.modelContext!.container)))
        self._title = State(initialValue: habit.title)
        self._habitDescription = State(initialValue: habit.habitDescription)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Habit Title", text: $title)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)

                    TextField("Description (Optional)", text: $habitDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(true)
                }


                Section("Tags") {
                    // Placeholder for tag management
                    Text("Tag management coming soon")
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Methods

    private func saveChanges() {
        habitManager.updateHabit(
            habit,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            habitDescription: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save habit changes: \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Edit Habit") {
    let container = try! ModelContainer(
        for: Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let habit = Habit(
        title: "Morning Exercise",
        habitDescription: "30 minutes of cardio to start the day"
    )
    context.insert(habit)

    return HabitEditView(habit: habit)
        .modelContainer(container)
}