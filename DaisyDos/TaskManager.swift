//
//  TaskManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Observable
class TaskManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var completedTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == true
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var pendingTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == false
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var todaysTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.createdDate >= today && task.createdDate < tomorrow
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func createTask(title: String) -> Task {
        let task = Task(title: title)
        modelContext.insert(task)

        do {
            try modelContext.save()
        } catch {
            print("Failed to create task: \(error)")
        }

        return task
    }

    func updateTask(_ task: Task, title: String? = nil, isCompleted: Bool? = nil) {
        if let title = title {
            task.title = title
        }
        if let isCompleted = isCompleted {
            task.isCompleted = isCompleted
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to update task: \(error)")
        }
    }

    func toggleTaskCompletion(_ task: Task) {
        task.toggleCompletion()

        do {
            try modelContext.save()
        } catch {
            print("Failed to toggle task completion: \(error)")
        }
    }

    func deleteTask(_ task: Task) {
        modelContext.delete(task)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete task: \(error)")
        }
    }

    func deleteTasks(_ tasks: [Task]) {
        for task in tasks {
            modelContext.delete(task)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete tasks: \(error)")
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: Tag, to task: Task) -> Bool {
        let success = task.addTag(tag)
        if success {
            do {
                try modelContext.save()
            } catch {
                print("Failed to add tag to task: \(error)")
                return false
            }
        }
        return success
    }

    func removeTag(_ tag: Tag, from task: Task) {
        task.removeTag(tag)

        do {
            try modelContext.save()
        } catch {
            print("Failed to remove tag from task: \(error)")
        }
    }

    // MARK: - Search and Filtering

    func searchTasks(query: String) -> [Task] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allTasks
        }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.title.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func tasksWithTag(_ tag: Tag) -> [Task] {
        // For now, fetch all tasks and filter in memory since @Predicate with contains is complex
        return allTasks.filter { task in
            task.tags.contains { $0.id == tag.id }
        }
    }

    // MARK: - Statistics

    var taskCount: Int {
        allTasks.count
    }

    var completedTaskCount: Int {
        completedTasks.count
    }

    var pendingTaskCount: Int {
        pendingTasks.count
    }

    var completionRate: Double {
        guard taskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(taskCount)
    }
}