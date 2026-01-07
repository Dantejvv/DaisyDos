//
//  ImportExportManager.swift
//  DaisyDos
//
//  Created by Claude Code on 11/12/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
class ImportExportManager {
    private let modelContext: ModelContext

    // MARK: - Export Format
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "json"
        case csv = "csv"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .json: return "JSON"
            case .csv: return "CSV"
            }
        }

        var fileExtension: String {
            rawValue
        }

        var utType: UTType {
            switch self {
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
    }

    // MARK: - Export Data Structure
    struct ExportData: Codable {
        let exportDate: Date
        let version: String
        let tasks: [TaskExport]
        let habits: [HabitExport]
        let tags: [TagExport]

        struct TaskExport: Codable {
            let id: String
            let title: String
            let taskDescription: String?
            let isCompleted: Bool
            let priority: String
            let dueDate: Date?
            let startDate: Date?
            let alertDate: Date?
            let createdAt: Date
            let completedAt: Date?
            let tags: [String]
            let subtasks: [SubtaskExport]
            let hasAttachments: Bool
            let attachmentCount: Int
            let recurrenceRule: RecurrenceRuleExport?
        }

        struct HabitExport: Codable {
            let id: String
            let title: String
            let habitDescription: String?
            let priority: String
            let createdAt: Date
            let tags: [String]
            let subtasks: [SubtaskExport]
            let hasAttachments: Bool
            let attachmentCount: Int
            let recurrenceRule: RecurrenceRuleExport?
            let currentStreak: Int
            let longestStreak: Int
            let completionCount: Int
        }

        struct SubtaskExport: Codable {
            let id: String
            let title: String
            let isCompleted: Bool
            let order: Int
        }

        struct TagExport: Codable {
            let id: String
            let name: String
            let icon: String
            let color: String
        }

        struct RecurrenceRuleExport: Codable {
            let frequency: String
            let interval: Int
            let daysOfWeek: [Int]?
        }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export

    func exportData(format: ExportFormat) -> Result<URL, DaisyDosError> {
        do {
            // Fetch all data
            let tasks = try fetchTasks()
            let habits = try fetchHabits()
            let tags = try fetchTags()

            // Convert to export format
            let exportData = createExportData(tasks: tasks, habits: habits, tags: tags)

            // Generate file content
            let fileContent: Data
            let fileName: String

            switch format {
            case .json:
                fileContent = try JSONEncoder().encode(exportData)
                fileName = "DaisyDos_Export_\(dateFormatter.string(from: Date())).json"

            case .csv:
                let csvContent = generateCSV(from: exportData)
                guard let csvData = csvContent.data(using: .utf8) else {
                    return .failure(.exportFailed("Failed to encode CSV data"))
                }
                fileContent = csvData
                fileName = "DaisyDos_Export_\(dateFormatter.string(from: Date())).csv"
            }

            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)

            try fileContent.write(to: tempURL)

            return .success(tempURL)
        } catch let error as DaisyDosError {
            return .failure(error)
        } catch {
            return .failure(.exportFailed("Failed to export data: \(error.localizedDescription)"))
        }
    }

    // MARK: - Import

    func importData(from url: URL) -> Result<ImportSummary, DaisyDosError> {
        do {
            let data = try Data(contentsOf: url)
            let exportData = try JSONDecoder().decode(ExportData.self, from: data)

            var importedTasks = 0
            var importedHabits = 0
            var importedTags = 0

            // Import tags first (as they're referenced by tasks and habits)
            for tagExport in exportData.tags {
                if importTag(from: tagExport) {
                    importedTags += 1
                }
            }

            // Import tasks
            for taskExport in exportData.tasks {
                if importTask(from: taskExport) {
                    importedTasks += 1
                }
            }

            // Import habits
            for habitExport in exportData.habits {
                if importHabit(from: habitExport) {
                    importedHabits += 1
                }
            }

            try modelContext.save()

            return .success(ImportSummary(
                tasksImported: importedTasks,
                habitsImported: importedHabits,
                tagsImported: importedTags
            ))
        } catch let error as DecodingError {
            return .failure(.importFailed("Invalid file format: \(error.localizedDescription)"))
        } catch {
            return .failure(.importFailed("Failed to import data: \(error.localizedDescription)"))
        }
    }

    struct ImportSummary {
        let tasksImported: Int
        let habitsImported: Int
        let tagsImported: Int
    }

    // MARK: - Private Helpers

    private func fetchTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>()
        return try modelContext.fetch(descriptor)
    }

    private func fetchHabits() throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>()
        return try modelContext.fetch(descriptor)
    }

    private func fetchTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>()
        return try modelContext.fetch(descriptor)
    }

    private func createExportData(tasks: [Task], habits: [Habit], tags: [Tag]) -> ExportData {
        ExportData(
            exportDate: Date(),
            version: "1.0",
            tasks: tasks.map { convertTaskToExport($0) },
            habits: habits.map { convertHabitToExport($0) },
            tags: tags.map { convertTagToExport($0) }
        )
    }

    private func convertTaskToExport(_ task: Task) -> ExportData.TaskExport {
        ExportData.TaskExport(
            id: task.id.uuidString,
            title: task.title,
            taskDescription: task.taskDescription,
            isCompleted: task.isCompleted,
            priority: task.priority.rawValue,
            dueDate: task.dueDate,
            startDate: nil, // Not currently in model
            alertDate: task.reminderDate, // Absolute reminder date/time
            createdAt: task.createdDate,
            completedAt: task.completedDate,
            tags: (task.tags ?? []).map { $0.name },
            subtasks: (task.subtasks ?? []).map { ExportData.SubtaskExport(
                id: $0.id.uuidString,
                title: $0.title,
                isCompleted: $0.isCompleted,
                order: $0.subtaskOrder
            )},
            hasAttachments: !(task.attachments ?? []).isEmpty,
            attachmentCount: (task.attachments ?? []).count,
            recurrenceRule: task.recurrenceRule.map { convertRecurrenceRuleToExport($0) }
        )
    }

    private func convertHabitToExport(_ habit: Habit) -> ExportData.HabitExport {
        ExportData.HabitExport(
            id: habit.id.uuidString,
            title: habit.title,
            habitDescription: habit.habitDescription,
            priority: habit.priority.rawValue,
            createdAt: habit.createdDate,
            tags: (habit.tags ?? []).map { $0.name },
            subtasks: (habit.subtasks ?? []).map { ExportData.SubtaskExport(
                id: $0.id.uuidString,
                title: $0.title,
                isCompleted: $0.isCompleted,
                order: $0.subtaskOrder
            )},
            hasAttachments: !(habit.attachments ?? []).isEmpty,
            attachmentCount: (habit.attachments ?? []).count,
            recurrenceRule: habit.recurrenceRule.map { convertRecurrenceRuleToExport($0) },
            currentStreak: habit.currentStreak,
            longestStreak: habit.longestStreak,
            completionCount: (habit.completionEntries ?? []).count
        )
    }

    private func convertTagToExport(_ tag: Tag) -> ExportData.TagExport {
        ExportData.TagExport(
            id: tag.id.uuidString,
            name: tag.name,
            icon: tag.sfSymbolName,
            color: tag.colorName
        )
    }

    private func convertRecurrenceRuleToExport(_ rule: RecurrenceRule) -> ExportData.RecurrenceRuleExport {
        ExportData.RecurrenceRuleExport(
            frequency: rule.frequency.rawValue,
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek.map { Array($0) }
        )
    }

    private func generateCSV(from exportData: ExportData) -> String {
        var csv = "Type,ID,Title,Description,Status,Priority,Created,Tags\n"

        for task in exportData.tasks {
            let row = [
                "Task",
                task.id,
                escapeCSV(task.title),
                escapeCSV(task.taskDescription ?? ""),
                task.isCompleted ? "Completed" : "Active",
                task.priority,
                dateFormatter.string(from: task.createdAt),
                escapeCSV(task.tags.joined(separator: ", "))
            ].joined(separator: ",")
            csv += row + "\n"
        }

        for habit in exportData.habits {
            let row = [
                "Habit",
                habit.id,
                escapeCSV(habit.title),
                escapeCSV(habit.habitDescription ?? ""),
                "Streak: \(habit.currentStreak)",
                habit.priority,
                dateFormatter.string(from: habit.createdAt),
                escapeCSV(habit.tags.joined(separator: ", "))
            ].joined(separator: ",")
            csv += row + "\n"
        }

        return csv
    }

    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func importTag(from export: ExportData.TagExport) -> Bool {
        // Check if tag already exists
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.name == export.name }
        )
        if (try? modelContext.fetch(descriptor).first) != nil {
            return false // Skip duplicate
        }

        let tag = Tag(
            name: export.name,
            sfSymbolName: export.icon,
            colorName: export.color
        )
        modelContext.insert(tag)
        return true
    }

    private func importTask(from export: ExportData.TaskExport) -> Bool {
        // Note: Attachments are not recreated as they're stored separately

        let task = Task(
            title: export.title,
            taskDescription: export.taskDescription ?? "",
            priority: Priority(rawValue: export.priority) ?? .none,
            dueDate: export.dueDate
        )

        // Restore completion state
        task.isCompleted = export.isCompleted
        task.completedDate = export.completedAt

        // Restore creation date
        task.createdDate = export.createdAt

        // Restore recurrence rule if present
        if let recurrenceExport = export.recurrenceRule {
            task.recurrenceRule = RecurrenceRule(
                frequency: RecurrenceRule.Frequency(rawValue: recurrenceExport.frequency) ?? .daily,
                interval: recurrenceExport.interval,
                daysOfWeek: recurrenceExport.daysOfWeek.map { Set($0) }
            )
        }

        modelContext.insert(task)

        // Restore tags by finding existing tags with matching names
        var taskTags: [Tag] = []
        for tagName in export.tags {
            let descriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.name == tagName }
            )
            if let existingTag = try? modelContext.fetch(descriptor).first {
                taskTags.append(existingTag)
            }
        }
        if !taskTags.isEmpty {
            task.tags = taskTags
        }

        // Restore subtasks
        if !export.subtasks.isEmpty {
            var subtasks: [Task] = []
            for subtaskExport in export.subtasks {
                let subtask = Task(title: subtaskExport.title)
                subtask.isCompleted = subtaskExport.isCompleted
                subtask.subtaskOrder = subtaskExport.order
                modelContext.insert(subtask)
                subtasks.append(subtask)
            }
            task.subtasks = subtasks
        }

        return true
    }

    private func importHabit(from export: ExportData.HabitExport) -> Bool {
        // Note: Completion history is not recreated, only streak counts are preserved

        let habit = Habit(
            title: export.title,
            priority: Priority(rawValue: export.priority) ?? .none
        )

        // Restore description
        habit.habitDescription = export.habitDescription ?? ""

        // Restore creation date
        habit.createdDate = export.createdAt

        // Restore streak data
        habit.currentStreak = export.currentStreak
        habit.longestStreak = export.longestStreak

        // Restore recurrence rule if present
        if let recurrenceExport = export.recurrenceRule {
            habit.recurrenceRule = RecurrenceRule(
                frequency: RecurrenceRule.Frequency(rawValue: recurrenceExport.frequency) ?? .daily,
                interval: recurrenceExport.interval,
                daysOfWeek: recurrenceExport.daysOfWeek.map { Set($0) }
            )
        }

        modelContext.insert(habit)

        // Restore tags by finding existing tags with matching names
        var habitTags: [Tag] = []
        for tagName in export.tags {
            let descriptor = FetchDescriptor<Tag>(
                predicate: #Predicate { $0.name == tagName }
            )
            if let existingTag = try? modelContext.fetch(descriptor).first {
                habitTags.append(existingTag)
            }
        }
        if !habitTags.isEmpty {
            habit.tags = habitTags
        }

        // Restore subtasks
        if !export.subtasks.isEmpty {
            var subtasks: [HabitSubtask] = []
            for subtaskExport in export.subtasks {
                let subtask = HabitSubtask(title: subtaskExport.title)
                subtask.isCompletedToday = subtaskExport.isCompleted
                subtask.subtaskOrder = subtaskExport.order
                modelContext.insert(subtask)
                subtasks.append(subtask)
            }
            habit.subtasks = subtasks
        }

        return true
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter
    }
}
