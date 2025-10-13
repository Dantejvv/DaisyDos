//
//  TodayView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager
    @Environment(TaskCompletionToastManager.self) private var toastManager

    // SwiftData query for automatic updates when tasks change
    @Query(
        filter: #Predicate<Task> { task in
            task.isCompleted == false
        },
        sort: [SortDescriptor(\Task.createdDate, order: .reverse)]
    ) private var allIncompleteTasks: [Task]

    // Filter to only root tasks
    private var todaysTasks: [Task] {
        allIncompleteTasks.filter { $0.parentTask == nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Today's Summary

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Overview")
                                .font(.title2.bold())
                            Spacer()
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.daisyTask)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tasks Today")
                                    .font(.headline)
                                Text("\(todaysTasks.filter { !$0.isCompleted }.count) pending")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Completed")
                                    .font(.headline)
                                Text("\(todaysTasks.filter { $0.isCompleted }.count)")
                                    .foregroundColor(.daisySuccess)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Habits Today")
                                    .font(.headline)
                                Text("Ready to track")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Streak")
                                    .font(.headline)
                                Text("Coming soon")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))

                    // MARK: - Today's Tasks

                    if !todaysTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Tasks")
                                    .font(.title2.bold())
                                Spacer()
                                Button("View All") {
                                    // TODO: Navigate to tasks tab
                                }
                                .foregroundColor(.daisyTask)
                            }

                            VStack(spacing: 8) {
                                ForEach(todaysTasks.prefix(5)) { task in
                                    HStack {
                                        Button(action: {
                                            toggleTaskCompletion(task)
                                        }) {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(task.isCompleted ? .daisySuccess : .daisyTextSecondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Text(task.title)
                                            .foregroundColor(task.isCompleted ? .daisyTextSecondary : .daisyText)
                                            .strikethrough(task.isCompleted)

                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))

                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.daisyTextSecondary)

                            Text("No tasks for today")
                                .font(.title2.bold())

                            Text("Start your day by adding some tasks!")
                                .foregroundColor(.daisyTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Quick Actions

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2.bold())

                        HStack(spacing: 16) {
                            Button(action: {
                                // TODO: Add task action
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.daisyTask)
                                    Text("Add Task")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                // TODO: Add habit action
                            }) {
                                VStack {
                                    Image(systemName: "repeat.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.daisyTask)
                                    Text("Add Habit")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helper Methods

    private func toggleTaskCompletion(_ task: Task) {
        if task.hasSubtasks {
            let result = taskManager.toggleSubtaskCompletion(
                task,
                strategy: .hybrid,
                propagateToParent: true
            )
            if case .failure(let error) = result {
                print("Failed to toggle task completion: \(error)")
            } else if task.isCompleted {
                // Show undo toast if task was completed
                toastManager.showCompletionToast(for: task) {
                    _ = taskManager.toggleTaskCompletionSafely(task)
                }
            }
        } else {
            _ = taskManager.toggleTaskCompletionSafely(task)

            // Show undo toast if task was completed (not uncompleted)
            if task.isCompleted {
                toastManager.showCompletionToast(for: task) {
                    _ = taskManager.toggleTaskCompletionSafely(task)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TodayView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}