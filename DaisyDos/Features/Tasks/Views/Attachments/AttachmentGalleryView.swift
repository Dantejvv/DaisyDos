//
//  AttachmentGalleryView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import SwiftUI
import SwiftData

struct AttachmentGalleryView: View {
    @Environment(TaskManager.self) private var taskManager

    let task: Task
    let onAttachmentTap: (TaskAttachment) -> Void
    let onAddAttachment: () -> Void
    let onShareAttachment: (TaskAttachment) -> Void

    @State private var viewMode: ViewMode = .grid
    @State private var showingDeleteConfirmation: TaskAttachment?
    @State private var searchText = ""

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"

        var icon: String {
            switch self {
            case .grid:
                return "square.grid.2x2"
            case .list:
                return "list.bullet"
            }
        }
    }

    private var filteredAttachments: [TaskAttachment] {
        if searchText.isEmpty {
            return task.attachments.sorted { $0.createdDate > $1.createdDate }
        } else {
            return task.attachments.filter { attachment in
                attachment.displayName.localizedCaseInsensitiveContains(searchText) ||
                attachment.attachmentType.displayName.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.createdDate > $1.createdDate }
        }
    }

    private var attachmentsByType: [(TaskAttachment.AttachmentType, [TaskAttachment])] {
        let grouped = Dictionary(grouping: filteredAttachments) { $0.attachmentType }
        return TaskAttachment.AttachmentType.allCases.compactMap { type in
            guard let attachments = grouped[type], !attachments.isEmpty else { return nil }
            return (type, attachments)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            if filteredAttachments.isEmpty {
                emptyStateView
            } else {
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewMode == .grid {
                            gridContent
                        } else {
                            listContent
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search attachments...")
            }
        }
        .alert(
            "Delete Attachment",
            isPresented: .constant(showingDeleteConfirmation != nil),
            presenting: showingDeleteConfirmation
        ) { attachment in
            Button("Delete", role: .destructive) {
                deleteAttachment(attachment)
            }
            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = nil
            }
        } message: { attachment in
            Text("Are you sure you want to delete '\(attachment.displayName)'? This action cannot be undone.")
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.daisyText)

                if !filteredAttachments.isEmpty {
                    Text("\(filteredAttachments.count) \(filteredAttachments.count == 1 ? "file" : "files")")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Spacer()

            if !task.attachments.isEmpty {
                // View mode toggle
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // Add button
            Button(action: onAddAttachment) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.daisyTask)
            }
            .accessibilityLabel("Add attachment")
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Grid Content

    @ViewBuilder
    private var gridContent: some View {
        ForEach(attachmentsByType, id: \.0) { type, attachments in
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack {
                    Label(type.displayName, systemImage: type.sfSymbol)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(type.color)

                    Spacer()

                    Text("\(attachments.count)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
                }

                // Grid of attachments
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(attachments, id: \.id) { attachment in
                        AttachmentPreviewCard(
                            attachment: attachment,
                            displayMode: .grid,
                            onTap: { onAttachmentTap(attachment) },
                            onDelete: { showingDeleteConfirmation = attachment },
                            onShare: { onShareAttachment(attachment) }
                        )
                    }
                }
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        ForEach(attachmentsByType, id: \.0) { type, attachments in
            VStack(spacing: 0) {
                // Section header
                HStack {
                    Label(type.displayName, systemImage: type.sfSymbol)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(type.color)

                    Spacer()

                    Text("\(attachments.count)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.regularMaterial, in: Capsule())
                }
                .padding()

                // List of attachments
                LazyVStack(spacing: 0) {
                    ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                        AttachmentPreviewCard(
                            attachment: attachment,
                            displayMode: .list,
                            onTap: { onAttachmentTap(attachment) },
                            onDelete: { showingDeleteConfirmation = attachment },
                            onShare: { onShareAttachment(attachment) }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        if index < attachments.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            if searchText.isEmpty {
                // No attachments state
                VStack(spacing: 12) {
                    Image(systemName: "paperclip.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.daisyTextSecondary)

                    Text("No Attachments")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.daisyText)

                    Text("Add photos, documents, or other files to keep everything organized with your task.")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: onAddAttachment) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Attachment")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.daisyTask, in: Capsule())
                    }
                    .accessibilityLabel("Add first attachment")
                }
            } else {
                // No search results state
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.daisyTextSecondary)

                    Text("No Results")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.daisyText)

                    Text("No attachments match '\(searchText)'")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helper Properties

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 16)
        ]
    }

    // MARK: - Helper Methods

    private func deleteAttachment(_ attachment: TaskAttachment) {
        let result = taskManager.removeAttachment(attachment, from: task)
        if case .failure(let error) = result {
            // Handle error - in a real implementation, this would trigger error presentation
            print("Failed to delete attachment: \(error.userMessage)")
        }
        showingDeleteConfirmation = nil
    }
}


#Preview {
    let container = try! ModelContainer(
        for: Task.self, TaskAttachment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    // Create sample task with attachments
    let task = Task(title: "Sample Task with Attachments")
    _ = task.addAttachment(.sampleImage)
    _ = task.addAttachment(.sampleDocument)

    container.mainContext.insert(task)
    try! container.mainContext.save()

    return AttachmentGalleryView(
        task: task,
        onAttachmentTap: { _ in },
        onAddAttachment: {},
        onShareAttachment: { _ in }
    )
    .modelContainer(container)
    .environment(taskManager)
    .padding()
}

#Preview("Empty State") {
    let container = try! ModelContainer(
        for: Task.self, TaskAttachment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)
    let task = Task(title: "Task with No Attachments")

    container.mainContext.insert(task)
    try! container.mainContext.save()

    return AttachmentGalleryView(
        task: task,
        onAttachmentTap: { _ in },
        onAddAttachment: {},
        onShareAttachment: { _ in }
    )
    .modelContainer(container)
    .environment(taskManager)
    .padding()
}