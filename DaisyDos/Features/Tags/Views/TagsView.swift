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

    var body: some View {
        NavigationStack {
            VStack {
                // Header stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Tags")
                            .font(.headline)
                        Text("\(tagManager.tagCount) of 30")
                            .font(.title2.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Usage")
                            .font(.headline)
                        Text("Track usage")
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                if tagManager.allTags.isEmpty {
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

                        Text("Tag creation will be available in future updates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Tag grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(tagManager.allTags) { tag in
                                TagCardView(tag: tag)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Add tag creation
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(true) // Disabled until implementation
                }
            }
        }
    }
}

// MARK: - Tag Card View

private struct TagCardView: View {
    let tag: Tag

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: tag.sfSymbolName)
                        .font(.title2)
                        .foregroundColor(Color(tag.colorName))

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
                        .foregroundColor(.secondary)
                    Text("Tasks: Coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "repeat.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Habits: Coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TagsView()
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}