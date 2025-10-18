//
//  TaskDescriptionScrollTest.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//

import SwiftUI
import SwiftData

/// Interactive test view for validating ScrollableDescriptionView in TaskDetailView
/// Tests various description lengths and newline scenarios
struct TaskDescriptionScrollTest: View {
    @Environment(\.modelContext) private var modelContext
    @State private var taskManager: TaskManager?
    @State private var testTasks: [Task] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let taskManager = taskManager {
                        // Test 1: Short description (should not scroll)
                        if let shortTask = testTasks.first {
                            NavigationLink {
                                TaskDetailView(task: shortTask)
                                    .environment(taskManager)
                            } label: {
                                TestCard(
                                    title: "Test 1: Short Description",
                                    description: "Should NOT scroll - content fits naturally",
                                    task: shortTask
                                )
                            }
                        }

                        // Test 2: Long description (should scroll)
                        if testTasks.count > 1 {
                            NavigationLink {
                                TaskDetailView(task: testTasks[1])
                                    .environment(taskManager)
                            } label: {
                                TestCard(
                                    title: "Test 2: Long Description",
                                    description: "SHOULD scroll - exceeds 200pt max height",
                                    task: testTasks[1]
                                )
                            }
                        }

                        // Test 3: Multiple newlines
                        if testTasks.count > 2 {
                            NavigationLink {
                                TaskDetailView(task: testTasks[2])
                                    .environment(taskManager)
                            } label: {
                                TestCard(
                                    title: "Test 3: Multiple Newlines",
                                    description: "SHOULD scroll - many blank lines vertically",
                                    task: testTasks[2]
                                )
                            }
                        }

                        // Test 4: Very long single paragraph
                        if testTasks.count > 3 {
                            NavigationLink {
                                TaskDetailView(task: testTasks[3])
                                    .environment(taskManager)
                            } label: {
                                TestCard(
                                    title: "Test 4: Very Long Single Paragraph",
                                    description: "SHOULD scroll - continuous text wrapping",
                                    task: testTasks[3]
                                )
                            }
                        }
                    } else {
                        ProgressView("Initializing test tasks...")
                    }
                }
                .padding()
            }
            .navigationTitle("Description Scroll Tests")
            .background(Color.daisyBackground)
            .onAppear {
                setupTestData()
            }
        }
    }

    private func setupTestData() {
        let manager = TaskManager(modelContext: modelContext)
        self.taskManager = manager

        // Create test tasks
        var tasks: [Task] = []

        // Test 1: Short description
        let shortTask = Task(
            title: "Short Description Task",
            taskDescription: "This is a short description that should fit without scrolling.",
            priority: .medium
        )
        modelContext.insert(shortTask)
        tasks.append(shortTask)

        // Test 2: Long description
        let longTask = Task(
            title: "Long Description Task",
            taskDescription: """
            This is a very long description that should definitely require scrolling.

            It contains multiple paragraphs with detailed information about the task.

            Here's another paragraph explaining more context about what needs to be done.

            And another paragraph with implementation details and considerations.

            We're adding even more content to ensure this exceeds the 200 point maximum height.

            This paragraph discusses the expected outcomes and success criteria.

            Additional notes about dependencies and related tasks can be found here.

            Finally, some closing remarks about timeline and priorities.

            This should definitely be scrollable now with visible scroll indicators!
            """,
            priority: .high
        )
        modelContext.insert(longTask)
        tasks.append(longTask)

        // Test 3: Multiple newlines
        let newlineTask = Task(
            title: "Multiple Newlines Task",
            taskDescription: """
            First line of content.




            Second line with many blank lines above.




            Third line also separated by newlines.




            Fourth line continuing the pattern.




            Fifth line.




            Sixth line.




            Seventh line at the bottom.
            """,
            priority: .low
        )
        modelContext.insert(newlineTask)
        tasks.append(newlineTask)

        // Test 4: Very long single paragraph
        let singleParaTask = Task(
            title: "Long Single Paragraph Task",
            taskDescription: """
            This is a very long single paragraph that contains a lot of continuous text without any paragraph breaks. The purpose is to test how the ScrollableDescriptionView handles text that wraps many times due to length rather than explicit newlines. This kind of content is common when users paste information from other sources or when they're writing detailed instructions. We want to make sure the scroll functionality works smoothly even when the content is all in one continuous block. The fade indicators should appear at the top and bottom when scrolling. Users should be able to scroll through the entire content easily. The scroll indicators should be visible to signal that there's more content available. This text continues to add more length to really test the scrolling behavior thoroughly. We're approaching the end of this very long paragraph that should definitely trigger the scrolling functionality in the detail view.
            """,
            priority: .medium
        )
        modelContext.insert(singleParaTask)
        tasks.append(singleParaTask)

        try? modelContext.save()
        self.testTasks = tasks
    }
}

// MARK: - Supporting Views

struct TestCard: View {
    let title: String
    let description: String
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.daisyTextSecondary)
            }

            HStack(spacing: 8) {
                task.priority.indicatorView()
                    .font(.caption)

                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    return TaskDescriptionScrollTest()
        .modelContainer(container)
}
