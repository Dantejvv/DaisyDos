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
                                TagCardView(tag: tag) {
                                    selectedTag = tag
                                    showingEditTag = true
                                }
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
}

// MARK: - Tag Card View

private struct TagCardView: View {
    let tag: Tag
    let onTap: () -> Void

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
            onTap()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    TagsView()
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}