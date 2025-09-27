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
    @State private var tagToDelete: Tag?
    @State private var showingDeleteConfirmation = false
    @State private var showingUndoToast = false
    @State private var deletedTag: Tag?
    @State private var undoTimer: Timer?

    var body: some View {
        NavigationStack {
            VStack {
                // Header stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Tags")
                            .font(.headline)
                        Text("\(allTags.count) of 30")
                            .font(.title2.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Usage")
                            .font(.headline)
                        Text("Track usage")
                            .font(.title2.bold())
                            .foregroundColor(.daisyTag)
                    }
                }
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                if allTags.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "tag.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.daisyTextSecondary)

                        Text("No Tags Yet")
                            .font(.title2.bold())

                        Text("Create tags to organize your tasks and habits. Use colors and icons to make them visually distinctive!")
                            .foregroundColor(.daisyTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Tag creation will be available in future updates.")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.daisyTextSecondary)
                        TextField("Search tags...", text: $searchText)
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Tag grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredTags) { tag in
                                TagCardView(tag: tag, onEdit: {
                                    selectedTag = tag
                                    showingEditTag = true
                                }, onDelete: {
                                    tagToDelete = tag
                                    showingDeleteConfirmation = true
                                })
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Tags")
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

        // Recreate the tag
        if let _ = tagManager.createTag(name: tag.name, sfSymbolName: tag.sfSymbolName, colorName: tag.colorName) {
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
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: tag.sfSymbolName)
                        .font(.title2)
                        .foregroundColor(tag.color)

                    Text(tag.name)
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Usage stats placeholder
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    Text("Tasks: \(tag.tasks.count)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                HStack {
                    Image(systemName: "repeat.circle")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    Text("Habits: \(tag.habits.count)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
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