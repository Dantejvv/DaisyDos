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
                                .foregroundColor(.blue)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tasks Today")
                                    .font(.headline)
                                Text("\(taskManager.todaysTasks.filter { !$0.isCompleted }.count) pending")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Completed")
                                    .font(.headline)
                                Text("\(taskManager.todaysTasks.filter { $0.isCompleted }.count)")
                                    .foregroundColor(Color(.systemGreen))
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Habits Today")
                                    .font(.headline)
                                Text("Ready to track")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Streak")
                                    .font(.headline)
                                Text("Coming soon")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                    // MARK: - Today's Tasks

                    if !taskManager.todaysTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Tasks")
                                    .font(.title2.bold())
                                Spacer()
                                Button("View All") {
                                    // TODO: Navigate to tasks tab
                                }
                                .foregroundColor(.blue)
                            }

                            VStack(spacing: 8) {
                                ForEach(taskManager.todaysTasks.prefix(5)) { task in
                                    HStack {
                                        Button(action: {
                                            taskManager.toggleTaskCompletionSafely(task)
                                        }) {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(task.isCompleted ? Color(.systemGreen) : .secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Text(task.title)
                                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                                            .strikethrough(task.isCompleted)

                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)

                            Text("No tasks for today")
                                .font(.title2.bold())

                            Text("Start your day by adding some tasks!")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
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
                                        .foregroundColor(.blue)
                                    Text("Add Task")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                // TODO: Add habit action
                            }) {
                                VStack {
                                    Image(systemName: "repeat.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    Text("Add Habit")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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