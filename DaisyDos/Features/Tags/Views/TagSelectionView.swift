//
//  TagSelectionView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TagSelectionView: View {
    @Environment(TagManager.self) private var tagManager
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Tag.name)]) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]

    @State private var searchText = ""
    @State private var showingCreateTag = false
    @State private var workingSelectedTags: [Tag] = []

    init(selectedTags: Binding<[Tag]>) {
        self._selectedTags = selectedTags
        self._workingSelectedTags = State(initialValue: selectedTags.wrappedValue)
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

    private var canSelectMoreTags: Bool {
        workingSelectedTags.count < 5
    }

    var body: some View {
        NavigationStack {
        VStack(alignment: .leading, spacing: 16) {
            // Search bar (moved to top)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.daisyTextSecondary)

                TextField("Search tags...", text: $searchText)
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))

            // Available tags section with counter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Available Tags")
                        .font(.headline)

                    Text("(\(workingSelectedTags.count)/5)")
                        .font(.headline)
                        .foregroundColor(workingSelectedTags.count == 5 ? .daisyWarning : .daisyTextSecondary)

                    Spacer()

                    Button(action: {
                        showingCreateTag = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                            Text("New")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.daisyTag)
                    }
                    .disabled(tagManager.remainingTagSlots <= 0)
                }

                if filteredTags.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "tag.slash" : "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.daisyTextSecondary)

                        Text(searchText.isEmpty ? "No tags available" : "No tags found")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)

                        if searchText.isEmpty && tagManager.canCreateNewTag {
                            Button("Create your first tag") {
                                showingCreateTag = true
                            }
                            .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    // Tags grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(filteredTags, id: \.id) { tag in
                            let isSelected = workingSelectedTags.contains(tag)

                            TagChipView(
                                tag: tag,
                                isSelected: isSelected,
                                onTap: {
                                    toggleTag(tag)
                                }
                            )
                            .disabled(!canSelectMoreTags && !isSelected)
                            .opacity((!canSelectMoreTags && !isSelected) ? 0.5 : 1.0)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.daisyTextSecondary)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    selectedTags = workingSelectedTags
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundColor(.daisyTask)
            }
        }
        .sheet(isPresented: $showingCreateTag) {
            TagCreationView()
        }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if workingSelectedTags.contains(tag) {
            removeTag(tag)
        } else {
            addTag(tag)
        }
    }

    private func addTag(_ tag: Tag) {
        guard canSelectMoreTags else { return }
        guard !workingSelectedTags.contains(tag) else { return }

        workingSelectedTags.append(tag)
    }

    private func removeTag(_ tag: Tag) {
        workingSelectedTags.removeAll { $0.id == tag.id }
    }
}

#Preview {
    @Previewable @State var selectedTags: [Tag] = []

    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create some sample tags
    let _ = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
    let _ = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")
    let _ = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "red")

    TagSelectionView(selectedTags: $selectedTags)
        .modelContainer(container)
        .environment(tagManager)
}