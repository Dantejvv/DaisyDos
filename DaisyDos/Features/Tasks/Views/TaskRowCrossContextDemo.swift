//
//  TaskRowCrossContextDemo.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

/// Cross-context validation view that demonstrates TaskRowView reusability
/// This validates the roadmap requirement: "Component works identically in all contexts"
struct TaskRowCrossContextDemo: View {
    @State private var selectedContext: DemoContext = .taskList
    @State private var sampleTasks: [Task] = []

    private let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Context selector
                contextSelector

                Divider()

                // Context demonstration
                switch selectedContext {
                case .taskList:
                    TaskListContext(tasks: sampleTasks)
                case .searchResults:
                    SearchResultsContext(tasks: sampleTasks)
                case .todayView:
                    TodayViewContext(tasks: sampleTasks)
                }

                Spacer()
            }
            .navigationTitle("TaskRowView Cross-Context Demo")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: setupSampleData)
        }
        .modelContainer(container)
    }

    // MARK: - Context Selector

    @ViewBuilder
    private var contextSelector: some View {
        Picker("Demo Context", selection: $selectedContext) {
            ForEach(DemoContext.allCases, id: \.self) { context in
                Text(context.displayName).tag(context)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Setup

    private func setupSampleData() {
        let context = container.mainContext
        let tagManager = TagManager(modelContext: context)

        // Create sample tags
        let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
        let personalTag = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")!
        let urgentTag = tagManager.createTag(name: "Urgent", sfSymbolName: "exclamationmark", colorName: "red")!

        // Create sample tasks
        let task1 = Task(
            title: "Complete Project Report",
            taskDescription: "Finish the quarterly project report with all metrics and analysis",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        _ = task1.addTag(workTag)
        _ = task1.addTag(urgentTag)

        let task2 = Task(
            title: "Buy Groceries",
            taskDescription: "Milk, eggs, bread, and vegetables for the week",
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 0, to: Date())
        )
        _ = task2.addTag(personalTag)

        let task3 = Task(
            title: "Review Pull Request",
            taskDescription: "Review and approve the authentication module changes",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )
        _ = task3.addTag(workTag)

        let task4 = Task(
            title: "Completed Task Example",
            taskDescription: "This task has been completed to show different states",
            priority: .low
        )
        task4.setCompleted(true)
        _ = task4.addTag(personalTag)

        // Add subtasks to demonstrate that feature
        _ = task1.createSubtask(title: "Gather data from teams")
        _ = task1.createSubtask(title: "Analyze metrics")
        let completedSubtask = task1.createSubtask(title: "Create charts")
        completedSubtask.setCompleted(true)

        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(task4)

        try! context.save()

        sampleTasks = [task1, task2, task3, task4]
    }
}

// MARK: - Demo Context Enum

enum DemoContext: CaseIterable {
    case taskList
    case searchResults
    case todayView

    var displayName: String {
        switch self {
        case .taskList: return "Task List"
        case .searchResults: return "Search Results"
        case .todayView: return "Today View"
        }
    }
}

// MARK: - Context Implementations

/// Demonstrates TaskRowView in a standard task list context
struct TaskListContext: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TaskRowView in Task List Context")
                .font(.headline)
                .padding(.horizontal)

            Text("Using .detailed display mode with full functionality")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            List {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(
                        task: task,
                        onToggleCompletion: {
                            print("Toggle completion: \\(task.title)")
                        },
                        onEdit: {
                            print("Edit: \\(task.title)")
                        },
                        onDelete: {
                            print("Delete: \\(task.title)")
                        },
                        onTagAssignment: {
                            print("Tag assignment: \\(task.title)")
                        },
                        displayMode: .detailed
                    )
                }
            }
            .listStyle(.plain)
        }
    }
}

/// Demonstrates TaskRowView in search results context
struct SearchResultsContext: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TaskRowView in Search Results Context")
                .font(.headline)
                .padding(.horizontal)

            Text("Using .compact display mode for dense results")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(tasks, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            onToggleCompletion: {
                                print("Toggle completion: \\(task.title)")
                            },
                            onEdit: {
                                print("Edit: \\(task.title)")
                            },
                            onDelete: {
                                print("Delete: \\(task.title)")
                            },
                            displayMode: .compact,
                            showsSubtasks: false,
                            showsTagButton: false
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// Demonstrates TaskRowView in Today view context
struct TodayViewContext: View {
    let tasks: [Task]

    var todaysTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TaskRowView in Today View Context")
                .font(.headline)
                .padding(.horizontal)

            Text("Using .today display mode optimized for daily overview")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(todaysTasks, id: \.id) { task in
                        TaskRowView(
                            task: task,
                            onToggleCompletion: {
                                print("Toggle completion: \\(task.title)")
                            },
                            onEdit: {
                                print("Edit: \\(task.title)")
                            },
                            onDelete: {
                                print("Delete: \\(task.title)")
                            },
                            onTagAssignment: {
                                print("Tag assignment: \\(task.title)")
                            },
                            displayMode: .today
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TaskRowCrossContextDemo()
}