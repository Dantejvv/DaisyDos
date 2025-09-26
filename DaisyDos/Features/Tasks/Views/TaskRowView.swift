//
//  TaskRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TaskRowView: View {
    let task: Task

    @Environment(TaskManager.self) private var taskManager
    @State private var showingTagAssignment = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task header with completion toggle
            HStack {
                Button(action: {
                    task.toggleCompletion()
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? Color(.systemGreen) : .gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)

                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Priority indicator
                if task.priority != .medium {
                    task.priority.indicatorView()
                        .font(.caption)
                }
            }

            // Tags section
            if !task.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(task.tags, id: \.id) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Due date and metadata
            HStack {
                if let dueDate = task.dueDate {
                    Label(
                        dueDate.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(task.hasOverdueStatus ? .red : .secondary)
                }

                if task.hasSubtasks {
                    Label("\(task.completedSubtaskCount)/\(task.subtaskCount)", systemImage: "checklist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    showingTagAssignment = true
                }) {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Assign tags")
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingTagAssignment) {
            TagAssignmentSheet.forTask(task: task) { newTags in
                // Update task tags
                for tag in task.tags {
                    if !newTags.contains(tag) {
                        task.removeTag(tag)
                    }
                }

                for tag in newTags {
                    if !task.tags.contains(tag) {
                        _ = task.addTag(tag)
                    }
                }

            }
        }
    }
}


#Preview {
    struct TaskRowViewPreview: View {
        let container = try! ModelContainer(
            for: Task.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        init() {
            let context = container.mainContext
            let taskManager = TaskManager(modelContext: context)
            let tagManager = TagManager(modelContext: context)

            // Create sample tags and task
            let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
            let personalTag = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")!

            let task = Task(title: "Sample Task", taskDescription: "This is a sample task description", priority: .high)
            context.insert(task)

            _ = task.addTag(workTag)
            _ = task.addTag(personalTag)

            try! context.save()
        }

        var body: some View {
            let context = container.mainContext
            let taskManager = TaskManager(modelContext: context)
            let tagManager = TagManager(modelContext: context)
            let task = (try? context.fetch(FetchDescriptor<Task>()).first) ?? Task(title: "Sample")

            TaskRowView(task: task)
                .modelContainer(container)
                .environment(taskManager)
                .environment(tagManager)
                .padding()
        }
    }

    return TaskRowViewPreview()
}