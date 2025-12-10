//
//  TagsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.dismiss) private var dismiss
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
                    // Tag grid with section header
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section header with counter
                            HStack {
                                Text("Your Tags")
                                    .font(.headline)
                                    .foregroundColor(.daisyText)

                                Text("(\(filteredTags.count) of 30)")
                                    .font(.subheadline)
                                    .foregroundColor(.daisyTextSecondary)

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredTags) { tag in
                                    TagCardView(
                                        tag: tag,
                                        onTap: {
                                            selectedTag = tag
                                            showingEditTag = true
                                        },
                                        onEdit: {
                                            selectedTag = tag
                                            showingEditTag = true
                                        },
                                        onDelete: {
                                            tagToDelete = tag
                                            showingDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
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
                    Text("This tag is used by \(tag.tasks?.count ?? 0) tasks and \(tag.habits?.count ?? 0) habits. Deleting it will remove it from all items.")
                } else {
                    Text("This will permanently delete the '\(tag.name)' tag.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(allTags.count >= 30)
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
            .errorAlert(error: Binding(
                get: { tagManager.lastError },
                set: { tagManager.lastError = $0 }
            ))
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
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tag header with icon and name
            HStack(spacing: 10) {
                // Icon with color background
                ZStack {
                    Circle()
                        .fill(tag.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: tag.sfSymbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tag.color)
                }

                Text(tag.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.daisyText)
                    .lineLimit(1)

                Spacer()
            }

            // Usage count
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)

                Text("\(tag.totalItemCount) items")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }

            // Description preview (if exists)
            if !tag.descriptionText.isEmpty {
                Text(tag.descriptionText)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // Color indicator bar at bottom
            Rectangle()
                .fill(tag.color)
                .frame(height: 3)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(
            Color.daisySurface
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.daisyTextSecondary.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.daisyError)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive, action: onDelete)
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