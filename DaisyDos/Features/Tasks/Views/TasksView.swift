//
//  TasksView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(TagManager.self) private var tagManager
    @Query(sort: \Task.createdDate, order: .reverse) private var allTasks: [Task]
    @State private var searchText = ""
    @State private var showingAddTask = false

    var body: some View {
        NavigationStack {
            VStack {
                if allTasks.isEmpty {
                    // Empty state when no tasks exist at all
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No Tasks Yet")
                            .font(.title2.bold())

                        Text("Start organizing your work by creating your first task.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Show search bar and tasks when we have tasks
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search tasks...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Task list or search results
                    if filteredTasks.isEmpty && !searchText.isEmpty {
                        // Show "no search results" state
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)

                            Text("No results for '\(searchText)'")
                                .font(.title2.bold())

                            Text("Try adjusting your search terms")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    } else {
                        // Show task list
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRowView(task: task)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }

    private var filteredTasks: [Task] {
        if searchText.isEmpty {
            return allTasks
        } else {
            return taskManager.searchTasksSafely(query: searchText)
        }
    }
}


#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TasksView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}