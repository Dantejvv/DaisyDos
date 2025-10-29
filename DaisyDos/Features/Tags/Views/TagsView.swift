//
//  TagsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(TagManager.self) private var tagManager
    @Query(sort: [SortDescriptor(\Tag.name)]) private var allTags: [Tag]

    @State private var showingCreateTag = false
    @State private var selectedTag: Tag?
    @State private var showingEditTag = false
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var tagToDelete: Tag?
    @State private var showingDeleteConfirmation = false
    @State private var showingUndoToast = false
    @State private var deletedTag: Tag?
    @State private var undoTimer: Timer?
    @State private var isMultiSelectMode = false
    @State private var selectedTags: Set<Tag.ID> = []
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack {
                if allTags.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "tag.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No Tags Yet")
                            .font(.title2.bold())

                        Text("Create tags to organize your tasks and habits. Use colors and icons to make them visually distinctive!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Tap the + button to create your first tag!")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else if filteredTags.isEmpty && !searchText.isEmpty {
                    // No search results state
                    SearchEmptyStateView(searchText: searchText)

                } else {
                    // Tag grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredTags) { tag in
                                TagCardView(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag.id),
                                    isMultiSelectMode: isMultiSelectMode,
                                    onTap: {
                                        if isMultiSelectMode {
                                            toggleTagSelection(tag)
                                        } else {
                                            selectedTag = tag
                                            showingEditTag = true
                                        }
                                    },
                                    onEdit: {
                                        if !isMultiSelectMode {
                                            selectedTag = tag
                                            showingEditTag = true
                                        }
                                    },
                                    onDelete: {
                                        if !isMultiSelectMode {
                                            tagToDelete = tag
                                            showingDeleteConfirmation = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Tags")
            .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search tags...")
            .sheet(isPresented: $showingCreateTag) {
                TagCreationView()
            }
            .sheet(item: $selectedTag) { tag in
                TagEditView(tag: tag)
            }
            .confirmationDialog(
                "Delete Tag",
                isPresented: $showingDeleteConfirmation,
                presenting: tagToDelete
            ) { tag in
                if tag.isInUse {
                    Button("Remove from \(tag.totalItemCount) items and delete", role: .destructive) {
                        deleteTag(tag, force: true)
                    }
                    Button("Cancel", role: .cancel) { }
                } else {
                    Button("Delete", role: .destructive) {
                        deleteTag(tag, force: false)
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } message: { tag in
                if tag.isInUse {
                    Text("This tag is used by \(tag.tasks.count) tasks and \(tag.habits.count) habits. Deleting it will remove it from all items.")
                } else {
                    Text("This will permanently delete the '\(tag.name)' tag.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !allTags.isEmpty {
                        Button(isMultiSelectMode ? "Done" : "Select") {
                            withAnimation {
                                isMultiSelectMode.toggle()
                                if !isMultiSelectMode {
                                    selectedTags.removeAll()
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    if !allTags.isEmpty && !isMultiSelectMode {
                        Text("\(allTags.count) of 30 tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isMultiSelectMode {
                            Menu {
                                Button("Select All") {
                                    selectedTags = Set(allTags.map(\.id))
                                }
                                .disabled(selectedTags.count == allTags.count)

                                Button("Select None") {
                                    selectedTags.removeAll()
                                }
                                .disabled(selectedTags.isEmpty)
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        } else {
                            Button(action: {
                                showingCreateTag = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .disabled(allTags.count >= 30)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isMultiSelectMode && !selectedTags.isEmpty {
                    bulkActionToolbar
                }
            }
            .overlay(alignment: .bottom) {
                if showingUndoToast, let deletedTag = deletedTag {
                    UndoToastView(tagName: deletedTag.name) {
                        undoDelete()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert(
                "Delete \(selectedTags.count) Tags",
                isPresented: $showingBulkDeleteConfirmation
            ) {
                Button("Delete \(selectedTags.count) Tags", role: .destructive) {
                    bulkDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedTags.count) selected tags? This will remove them from all tasks and habits.")
            }
        }
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        } else {
            return allTags.filter { tag in
                tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Bulk Action Toolbar

    @ViewBuilder
    private var bulkActionToolbar: some View {
        BulkActionToolbar(selectedCount: selectedTags.count) {
            // Bulk delete
            Button(action: {
                showingBulkDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyError)
        }
    }

    // MARK: - Helper Methods

    private func toggleTagSelection(_ tag: Tag) {
        selectedTags.toggleMembership(tag.id)
    }

    private func bulkDelete() {
        let tagsToDelete = allTags.filter { selectedTags.contains($0.id) }
        for tag in tagsToDelete {
            tagManager.forceDeleteTag(tag)
        }
        selectedTags.removeAll()
        isMultiSelectMode = false
    }

    // MARK: - Tag Deletion Methods

    private func deleteTag(_ tag: Tag, force: Bool) {
        let success = force ? {
            tagManager.forceDeleteTag(tag)
            return true
        }() : tagManager.deleteTag(tag)

        if success {
            // Store for undo
            deletedTag = tag
            showingUndoToast = true

            // Start undo timer
            undoTimer?.invalidate()
            undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                withAnimation {
                    showingUndoToast = false
                    deletedTag = nil
                }
            }
        }
    }

    private func undoDelete() {
        guard let tag = deletedTag else { return }

        undoTimer?.invalidate()
        undoTimer = nil

        // Recreate the tag with description
        if let _ = tagManager.createTag(name: tag.name, sfSymbolName: tag.sfSymbolName, colorName: tag.colorName, tagDescription: tag.descriptionText) {
            withAnimation {
                showingUndoToast = false
                deletedTag = nil
            }
        }
    }
}

// MARK: - Tag Card View

private struct TagCardView: View {
    let tag: Tag
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag header
            HStack(spacing: 8) {
                Image(systemName: tag.sfSymbolName)
                    .font(.title2)
                    .foregroundColor(tag.color)

                Text(tag.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()
            }
        }
        .padding()
        .background(
            Group {
                if isMultiSelectMode && isSelected {
                    HStack(spacing: 0) {
                        // Left border accent
                        Rectangle()
                            .fill(Color.daisyTag)
                            .frame(width: 6)

                        // Background tint
                        Color.daisyTag.opacity(0.15)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Color.daisySurface
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isMultiSelectMode && isSelected ? Color.daisyTag : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            if !isMultiSelectMode {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }

                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.daisyError)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isMultiSelectMode {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}

// MARK: - Undo Toast View

private struct UndoToastView: View {
    let tagName: String
    let onUndo: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tag deleted")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Text("'\(tagName)' was removed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button("Undo") {
                onUndo()
            }
            .foregroundColor(.daisyCTA)
            .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.8))
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

#Preview {
    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    TagsView()
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}