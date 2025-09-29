//
//  TaskShareSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TaskShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    let task: Task
    let includeAttachments: Bool

    @State private var shareItems: [Any] = []
    @State private var isGeneratingContent = false
    @State private var errorMessage: String?

    init(task: Task, includeAttachments: Bool = false) {
        self.task = task
        self.includeAttachments = includeAttachments
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                headerView

                // Content Options
                ScrollView {
                    LazyVStack(spacing: 16) {
                        textSummarySection
                        if task.attachmentCount > 0 {
                            attachmentsSection
                        }
                        shareOptionsSection
                    }
                    .padding()
                }

                Spacer()

                // Share Button
                if !shareItems.isEmpty {
                    shareButton
                        .padding()
                }
            }
            .navigationTitle("Share Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isGeneratingContent {
                    loadingOverlay
                }
            }
            .onAppear {
                generateShareContent()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sharing")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)

                    Text(task.title)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.daisyText)
                        .lineLimit(3)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: task.priority.sfSymbol)
                        .font(.title2)
                        .foregroundColor(task.priority.color)

                    Text(task.priority.displayName)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

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
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Text Summary Section

    @ViewBuilder
    private var textSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Summary")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Title",
                    value: task.title,
                    icon: "text.alignleft"
                )

                if !task.taskDescription.isEmpty {
                    InfoRow(
                        label: "Description",
                        value: task.taskDescription,
                        icon: "text.alignleft",
                        isMultiline: true
                    )
                }

                if let dueDate = task.dueDate {
                    InfoRow(
                        label: "Due Date",
                        value: dueDate.formatted(date: .complete, time: .omitted),
                        icon: "calendar"
                    )
                }

                if task.hasSubtasks {
                    InfoRow(
                        label: "Subtasks",
                        value: "\(task.completedSubtaskCount) of \(task.subtaskCount) complete",
                        icon: "checklist"
                    )
                }

                InfoRow(
                    label: "Status",
                    value: task.isCompleted ? "Complete" : "In Progress",
                    icon: task.isCompleted ? "checkmark.circle" : "circle"
                )
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Attachments Section

    @ViewBuilder
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.daisyText)

                Spacer()

                Text("\(task.attachmentCount)")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }

            if includeAttachments {
                VStack(spacing: 8) {
                    ForEach(Array(task.attachments.prefix(3)), id: \.id) { attachment in
                        HStack {
                            attachment.displayIcon
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.daisyText)
                                    .lineLimit(1)

                                Text("\(attachment.attachmentType.displayName) • \(attachment.formattedFileSize)")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.daisySuccess)
                        }
                    }

                    if task.attachmentCount > 3 {
                        Text("+ \(task.attachmentCount - 3) more files will be included")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .foregroundColor(.daisyTextSecondary)

                    Text("Attachments will not be included in text share")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Share Options Section

    @ViewBuilder
    private var shareOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Options")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(spacing: 12) {
                ShareOptionCard(
                    title: "Text Summary",
                    subtitle: "Share task details as formatted text",
                    icon: "text.alignleft",
                    color: .daisyTask,
                    isSelected: !includeAttachments
                )

                if task.attachmentCount > 0 {
                    ShareOptionCard(
                        title: "With Attachments",
                        subtitle: "Include all files and documents",
                        icon: "paperclip",
                        color: Colors.Secondary.teal,
                        isSelected: includeAttachments
                    )
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Share Button

    @ViewBuilder
    private var shareButton: some View {
        if #available(iOS 16.0, *) {
            ShareLink(
                item: TaskShareData(task: task, includeAttachments: includeAttachments),
                preview: SharePreview(
                    task.title,
                    image: Image(systemName: task.priority.sfSymbol)
                )
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Task")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.daisyTask, in: RoundedRectangle(cornerRadius: 16))
            }
        } else {
            Button(action: shareTask) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Task")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.daisyTask, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Loading Overlay

    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.daisyTask)

                Text("Preparing content...")
                    .font(.headline)
                    .foregroundColor(.daisyText)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helper Methods

    private func generateShareContent() {
        isGeneratingContent = true

        _Concurrency.Task {
            var items: [Any] = []

            // Add text summary
            let textSummary = generateTextSummary()
            items.append(textSummary)

            // Add attachments if requested
            if includeAttachments {
                for attachment in task.attachments {
                    if let fileURL = attachment.fullFilePath,
                       FileManager.default.fileExists(atPath: fileURL.path) {
                        items.append(fileURL)
                    }
                }
            }

            await MainActor.run {
                shareItems = items
                isGeneratingContent = false
            }
        }
    }

    private func generateTextSummary() -> String {
        var summary = ""

        // Title
        summary += "📝 \(task.title)\n\n"

        // Priority
        let priorityEmoji = task.priority == .high ? "🔴" : task.priority == .medium ? "🟡" : "🟢"
        summary += "\(priorityEmoji) Priority: \(task.priority.displayName)\n"

        // Status
        let statusEmoji = task.isCompleted ? "✅" : "⏳"
        summary += "\(statusEmoji) Status: \(task.isCompleted ? "Complete" : "In Progress")\n"

        // Due date
        if let dueDate = task.dueDate {
            summary += "📅 Due: \(dueDate.formatted(date: .complete, time: .omitted))\n"
        }

        // Description
        if !task.taskDescription.isEmpty {
            summary += "\n📄 Description:\n\(task.taskDescription)\n"
        }

        // Subtasks
        if task.hasSubtasks {
            summary += "\n📋 Subtasks (\(task.completedSubtaskCount)/\(task.subtaskCount) complete):\n"
            for subtask in task.orderedSubtasks.prefix(10) {
                let checkbox = subtask.isCompleted ? "☑️" : "☐"
                summary += "\(checkbox) \(subtask.title)\n"
            }
            if task.subtaskCount > 10 {
                summary += "... and \(task.subtaskCount - 10) more subtasks\n"
            }
        }

        // Tags
        if !task.tags.isEmpty {
            summary += "\n🏷️ Tags: \(task.tags.map { $0.name }.joined(separator: ", "))\n"
        }

        // Attachments
        if task.attachmentCount > 0 {
            summary += "\n📎 \(task.attachmentCount) attachment\(task.attachmentCount == 1 ? "" : "s")"
            if !includeAttachments {
                summary += " (not included in this share)"
            }
            summary += "\n"
        }

        // Footer
        summary += "\n---\nShared from DaisyDos"

        return summary
    }

    private func shareTask() {
        // Fallback for iOS 15 and below
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: window.bounds.midX,
                y: window.bounds.midY,
                width: 0,
                height: 0
            )
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    let isMultiline: Bool

    init(label: String, value: String, icon: String, isMultiline: Bool = false) {
        self.label = label
        self.value = value
        self.icon = icon
        self.isMultiline = isMultiline
    }

    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.daisyText)
                    .lineLimit(isMultiline ? nil : 2)
            }

            if !isMultiline {
                Spacer()
            }
        }
    }
}

struct ShareOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(isSelected ? 0.3 : 0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(color)
            } else {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Task Share Data

@available(iOS 16.0, *)
struct TaskShareData: Transferable {
    let task: Task
    let includeAttachments: Bool

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.textRepresentation)
    }

    private var textRepresentation: String {
        // Generate the same text summary as in TaskShareSheet
        var summary = ""

        summary += "📝 \(task.title)\n\n"

        let priorityEmoji = task.priority == .high ? "🔴" : task.priority == .medium ? "🟡" : "🟢"
        summary += "\(priorityEmoji) Priority: \(task.priority.displayName)\n"

        let statusEmoji = task.isCompleted ? "✅" : "⏳"
        summary += "\(statusEmoji) Status: \(task.isCompleted ? "Complete" : "In Progress")\n"

        if let dueDate = task.dueDate {
            summary += "📅 Due: \(dueDate.formatted(date: .complete, time: .omitted))\n"
        }

        if !task.taskDescription.isEmpty {
            summary += "\n📄 Description:\n\(task.taskDescription)\n"
        }

        if task.hasSubtasks {
            summary += "\n📋 Subtasks (\(task.completedSubtaskCount)/\(task.subtaskCount) complete):\n"
            for subtask in task.orderedSubtasks.prefix(10) {
                let checkbox = subtask.isCompleted ? "☑️" : "☐"
                summary += "\(checkbox) \(subtask.title)\n"
            }
            if task.subtaskCount > 10 {
                summary += "... and \(task.subtaskCount - 10) more subtasks\n"
            }
        }

        if !task.tags.isEmpty {
            summary += "\n🏷️ Tags: \(task.tags.map { $0.name }.joined(separator: ", "))\n"
        }

        if task.attachmentCount > 0 {
            summary += "\n📎 \(task.attachmentCount) attachment\(task.attachmentCount == 1 ? "" : "s")"
            if !includeAttachments {
                summary += " (not included in this share)"
            }
            summary += "\n"
        }

        summary += "\n---\nShared from DaisyDos"

        return summary
    }
}

#Preview("Text Only") {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let tag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
    let task = Task(
        title: "Complete Quarterly Report",
        taskDescription: "Prepare comprehensive quarterly report with analysis and recommendations.",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
    )
    _ = task.addTag(tag)

    container.mainContext.insert(task)
    try! container.mainContext.save()

    return TaskShareSheet(task: task, includeAttachments: false)
        .modelContainer(container)
}

#Preview("With Attachments") {
    let container = try! ModelContainer(
        for: Task.self, Tag.self, TaskAttachment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let task = Task(title: "Project Documentation")
    _ = task.addAttachment(.sampleDocument)
    _ = task.addAttachment(.sampleImage)

    container.mainContext.insert(task)
    try! container.mainContext.save()

    return TaskShareSheet(task: task, includeAttachments: true)
        .modelContainer(container)
}