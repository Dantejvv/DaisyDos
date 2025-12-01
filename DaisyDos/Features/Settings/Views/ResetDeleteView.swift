//
//  ResetDeleteView.swift
//  DaisyDos
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import SwiftData

struct ResetDeleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var showingClearCompletedTasksConfirmation = false
    @State private var showingResetHabitsConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    @State private var showingFinalDeleteConfirmation = false
    @State private var error: DaisyDosError?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Task Actions
                Section {
                    Button(action: {
                        showingClearCompletedTasksConfirmation = true
                    }) {
                        Label("Clear Logbook", systemImage: "book.closed")
                            .foregroundColor(.daisyWarning)
                    }
                } header: {
                    Text("Task Management")
                } footer: {
                    Text("Removes all logbook entries. This action cannot be undone.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Habit Actions
                Section {
                    Button(action: {
                        showingResetHabitsConfirmation = true
                    }) {
                        Label("Reset All Habit Streaks", systemImage: "arrow.counterclockwise.circle")
                            .foregroundColor(.daisyWarning)
                    }
                } header: {
                    Text("Habit Management")
                } footer: {
                    Text("Resets all habit streaks and completion history. Habits themselves are not deleted.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Danger Zone
                Section {
                    Button(action: {
                        showingDeleteAllConfirmation = true
                    }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundColor(.daisyError)
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Permanently deletes ALL tasks, habits, tags, and attachments. This action cannot be undone.")
                        .foregroundColor(.daisyError)
                }
            }
            .navigationTitle("Reset & Delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Logbook?", isPresented: $showingClearCompletedTasksConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Logbook", role: .destructive) {
                    clearCompletedTasks()
                }
            } message: {
                Text("This will permanently delete all logbook entries. This action cannot be undone.")
            }
            .alert("Reset All Habit Streaks?", isPresented: $showingResetHabitsConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Streaks", role: .destructive) {
                    resetAllHabits()
                }
            } message: {
                Text("This will reset all habit streaks and clear completion history. The habits themselves will not be deleted.")
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingFinalDeleteConfirmation = true
                }
            } message: {
                Text("This will permanently delete ALL tasks, habits, tags, and attachments. Are you sure?")
            }
            .alert("Final Confirmation", isPresented: $showingFinalDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This is your final warning. All data will be permanently deleted. This action CANNOT be undone.")
            }
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(error.userMessage)
            }
        }
        .applyAppearance(appearanceManager)
    }

    // MARK: - Actions

    private func clearCompletedTasks() {
        do {
            let descriptor = FetchDescriptor<Task>(
                predicate: #Predicate { $0.isCompleted == true }
            )
            let completedTasks = try modelContext.fetch(descriptor)

            for task in completedTasks {
                modelContext.delete(task)
            }

            try modelContext.save()
        } catch {
            self.error = .databaseError("Failed to clear completed tasks", underlyingError: error)
        }
    }

    private func resetAllHabits() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)

            for habit in habits {
                habit.currentStreak = 0
                habit.longestStreak = 0
                habit.lastCompletedDate = nil
                habit.completionEntries.removeAll()
                habit.streaks.removeAll()
                habit.skips.removeAll()
            }

            try modelContext.save()
        } catch {
            self.error = .databaseError("Failed to reset habits", underlyingError: error)
        }
    }

    private func deleteAllData() {
        // Dismiss first, then delete after a delay
        // This prevents SwiftData crash from views trying to access deleted objects
        dismiss()

        // Perform deletion after SwiftUI has cleaned up the view hierarchy
        // Use a longer delay to ensure all @Query observers have time to unsubscribe
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [modelContext] in
            do {
                // Delete task attachments first
                let taskAttachmentDescriptor = FetchDescriptor<TaskAttachment>()
                let taskAttachments = try modelContext.fetch(taskAttachmentDescriptor)
                for attachment in taskAttachments {
                    modelContext.delete(attachment)
                }

                // Delete habit attachments
                let habitAttachmentDescriptor = FetchDescriptor<HabitAttachment>()
                let habitAttachments = try modelContext.fetch(habitAttachmentDescriptor)
                for attachment in habitAttachments {
                    modelContext.delete(attachment)
                }

                // Delete habit subtasks
                let habitSubtaskDescriptor = FetchDescriptor<HabitSubtask>()
                let habitSubtasks = try modelContext.fetch(habitSubtaskDescriptor)
                for subtask in habitSubtasks {
                    modelContext.delete(subtask)
                }

                // Save attachments and subtasks deletion first
                try modelContext.save()

                // Delete task subtasks first (tasks with parentTask)
                let subtaskDescriptor = FetchDescriptor<Task>(
                    predicate: #Predicate { $0.parentTask != nil }
                )
                let subtasks = try modelContext.fetch(subtaskDescriptor)
                for subtask in subtasks {
                    modelContext.delete(subtask)
                }

                // Delete parent tasks (tasks without parentTask)
                let taskDescriptor = FetchDescriptor<Task>(
                    predicate: #Predicate { $0.parentTask == nil }
                )
                let tasks = try modelContext.fetch(taskDescriptor)
                for task in tasks {
                    modelContext.delete(task)
                }

                // Save tasks deletion
                try modelContext.save()

                // Delete all habits
                let habitDescriptor = FetchDescriptor<Habit>()
                let habits = try modelContext.fetch(habitDescriptor)
                for habit in habits {
                    modelContext.delete(habit)
                }

                // Save habits deletion
                try modelContext.save()

                // Delete all tags
                let tagDescriptor = FetchDescriptor<Tag>()
                let tags = try modelContext.fetch(tagDescriptor)
                for tag in tags {
                    modelContext.delete(tag)
                }

                // Delete all logbook entries
                let logEntryDescriptor = FetchDescriptor<TaskLogEntry>()
                let logEntries = try modelContext.fetch(logEntryDescriptor)
                for entry in logEntries {
                    modelContext.delete(entry)
                }

                try modelContext.save()
            } catch {
                // Log error - can't show alert since view is dismissed
                print("Failed to delete all data: \(error)")
            }
        }
    }
}

#Preview {
    ResetDeleteView()
        .modelContainer(for: [Task.self, Habit.self], inMemory: true)
        .environment(TaskManager(modelContext: ModelContext(try! ModelContainer(for: Task.self))))
        .environment(HabitManager(modelContext: ModelContext(try! ModelContainer(for: Habit.self))))
}
