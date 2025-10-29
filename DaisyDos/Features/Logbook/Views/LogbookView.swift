//
//  LogbookView.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Main logbook view showing completed tasks and statistics
//

import SwiftUI
import SwiftData

struct LogbookView: View {
    @Environment(LogbookManager.self) private var logbookManager
    @Environment(NavigationManager.self) private var navigationManager

    // Direct SwiftData query for real-time updates
    // Only show root tasks (no subtasks) to keep logbook organized
    @Query(
        filter: #Predicate<Task> { $0.isCompleted && $0.parentTask == nil },
        sort: \Task.completedDate,
        order: .reverse
    ) private var completedTasks: [Task]

    @Query(sort: \TaskLogEntry.completedDate, order: .reverse)
    private var archivedEntries: [TaskLogEntry]

    @State private var selectedPeriod: LogPeriod = .last30Days
    @State private var searchText = ""
    @State private var isSearchPresented = false

    // MARK: - Period Enum

    enum LogPeriod: String, CaseIterable, Identifiable {
        case last7Days = "7 Days"
        case last30Days = "30 Days"
        case last90Days = "90 Days"
        case thisYear = "This Year"
        case allTime = "All Time"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .thisYear:
                let now = Date()
                let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: now))!
                return Calendar.current.dateComponents([.day], from: startOfYear, to: now).day ?? 365
            case .allTime: return Int.max
            }
        }

        var dateRange: (start: Date, end: Date) {
            let end = Date()
            if self == .allTime {
                // All time - use distant past
                return (Date.distantPast, end)
            } else {
                let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
                return (start, end)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent(manager: logbookManager)
                .navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search completions...")
                .navigationTabCleanup(
                    navigationManager: navigationManager,
                    currentTab: .logbook,
                    searchText: $searchText,
                    isSearchPresented: $isSearchPresented
                )
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(manager: LogbookManager) -> some View {
        VStack(spacing: 0) {
            // Period selector
            periodPicker

            // Completions list
            completionsList(manager: manager)
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack {
            Text("Period:")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Spacer()

            Menu {
                Text("Filter by Period")
                    .font(.headline)

                Divider()

                ForEach(LogPeriod.allCases) { period in
                    Button(action: {
                        selectedPeriod = period
                    }) {
                        HStack {
                            Text(period.rawValue)
                            if selectedPeriod == period {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedPeriod.rawValue)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.daisyTask)
            }
        }
        .padding()
        .accessibilityLabel("Time period selector: \(selectedPeriod.rawValue)")
    }

    // MARK: - Completions List

    @ViewBuilder
    private func completionsList(manager: LogbookManager) -> some View {
        let completions = getCompletions(manager: manager)

        if completions.isEmpty && !searchText.isEmpty {
            // No search results state
            SearchEmptyStateView(searchText: searchText)
        } else if completions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("\(completions.count) \(completions.count == 1 ? "Task" : "Tasks") Completed")
                            .font(.headline)
                            .foregroundColor(.daisyText)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Task list
                    ForEach(Array(completions.enumerated()), id: \.offset) { _, completion in
                        if let task = completion as? Task {
                            // Recent completion (0-90 days) - full TaskRowView with navigation
                            NavigationLink(destination: TaskDetailView(task: task, isLogbookMode: true)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Task row with inline subtask indicator
                                    HStack(spacing: 8) {
                                        // Completion checkmark
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.daisySuccess)

                                        VStack(alignment: .leading, spacing: 4) {
                                            // Title
                                            Text(task.title)
                                                .font(.body)
                                                .strikethrough()
                                                .foregroundColor(.daisyTextSecondary)
                                                .lineLimit(2)

                                            // Parent task reference if subtask
                                            if task.parentTask != nil, let parentTitle = task.parentTask?.title {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "folder")
                                                        .font(.caption2)
                                                    Text(parentTitle)
                                                        .font(.caption2)
                                                        .lineLimit(1)
                                                }
                                                .foregroundColor(Colors.Primary.textTertiary)
                                            }

                                            // Metadata (priority, tags, dates)
                                            if let completedDate = task.completedDate {
                                                HStack(spacing: 8) {
                                                    Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.caption)
                                                        .foregroundColor(Colors.Primary.textTertiary)

                                                    if !task.tags.isEmpty {
                                                        Text("•")
                                                            .font(.caption2)
                                                            .foregroundColor(Colors.Primary.textTertiary)

                                                        Text(task.tags.map { $0.name }.joined(separator: ", "))
                                                            .font(.caption)
                                                            .foregroundColor(Colors.Primary.textTertiary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                            }
                                        }

                                        Spacer()

                                        // Priority indicator
                                        task.priority.indicatorView()
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .opacity(0.9)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .accessibilityLabel(task.parentTask != nil ? "Subtask: \(task.title). View details" : "View details for \(task.title)")
                        } else if let logEntry = completion as? TaskLogEntry {
                            // Archived completion (91-365 days) - lightweight LogEntryRow (read-only)
                            LogEntryRow(entry: logEntry)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("No Completed Tasks")
                    .font(.title2.bold())

                Text("Complete tasks to see them here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func getCompletions(manager: LogbookManager) -> [Any] {
        let range = selectedPeriod.dateRange

        // Filter tasks from @Query (real-time updates)
        // Show all completed tasks within the selected period
        let recentTasks: [Task]
        if searchText.isEmpty {
            recentTasks = completedTasks
                .filter { task in
                    guard let date = task.completedDate else { return false }
                    return date >= range.start && date <= range.end
                }
        } else {
            let query = searchText.lowercased()
            recentTasks = completedTasks
                .filter { task in
                    guard let date = task.completedDate else { return false }
                    let matchesDate = date >= range.start && date <= range.end
                    let matchesSearch = task.title.lowercased().contains(query) ||
                                      task.taskDescription.lowercased().contains(query)
                    return matchesDate && matchesSearch
                }
        }

        // Filter archived entries from @Query (real-time updates)
        let filteredArchived: [TaskLogEntry]
        if searchText.isEmpty {
            filteredArchived = archivedEntries
                .filter { entry in
                    entry.completedDate >= range.start && entry.completedDate <= range.end
                }
        } else {
            let query = searchText.lowercased()
            filteredArchived = archivedEntries
                .filter { entry in
                    let matchesDate = entry.completedDate >= range.start && entry.completedDate <= range.end
                    let matchesSearch = entry.title.lowercased().contains(query) ||
                                       entry.taskDescription.lowercased().contains(query) ||
                                       entry.tagNames.contains { $0.lowercased().contains(query) }
                    return matchesDate && matchesSearch
                }
        }

        // Combine and sort by completion date
        return (recentTasks as [Any] + filteredArchived as [Any])
            .sorted { a, b in
                let dateA = (a as? Task)?.completedDate ?? (a as? TaskLogEntry)?.completedDate ?? Date.distantPast
                let dateB = (b as? Task)?.completedDate ?? (b as? TaskLogEntry)?.completedDate ?? Date.distantPast
                return dateA > dateB
            }
    }

}

// MARK: - Preview

#Preview("Logbook View") {
    let container = try! ModelContainer(
        for: Task.self, TaskLogEntry.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    // Create sample completed tasks
    for i in 1...5 {
        let task = Task(
            title: "Completed Task \(i)",
            taskDescription: "This is a sample completed task",
            priority: Priority.allCases.randomElement()!,
            dueDate: Calendar.current.date(byAdding: .day, value: -i, to: Date())
        )
        task.setCompleted(true)
        context.insert(task)
    }

    // Create sample log entries
    for i in 1...3 {
        let entry = TaskLogEntry(
            originalTaskId: UUID(),
            title: "Archived Task \(i)",
            taskDescription: "This is an archived task",
            completedDate: Calendar.current.date(byAdding: .day, value: -(95 + i), to: Date())!,
            createdDate: Calendar.current.date(byAdding: .day, value: -(100 + i), to: Date())!,
            dueDate: nil,
            priority: Priority.allCases.randomElement()!,
            wasOverdue: false,
            subtaskCount: 0,
            completedSubtaskCount: 0,
            wasSubtask: false,
            parentTaskTitle: nil,
            tagNames: ["Sample"],
            completionDuration: 86400
        )
        context.insert(entry)
    }

    try! context.save()

    return LogbookView()
        .modelContainer(container)
}
