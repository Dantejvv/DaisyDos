//
//  TagsSection.swift
//  DaisyDos
//
//  Standardized tags section for Add/Edit/Detail views
//  Displays selected tags with add/remove functionality
//

import SwiftUI
import SwiftData

/// A standardized section for displaying and managing tags.
///
/// Features:
/// - Empty state with "Add Tags" button
/// - Populated state with tag chips
/// - WrappingHStack layout for chips
/// - Add button (when under max limit)
/// - Remove functionality per tag
/// - Read-only mode support
/// - Consistent styling
///
/// Example:
/// ```swift
/// TagsSection(
///     selectedTags: $selectedTags,
///     maxTags: 3,
///     isReadOnly: false,
///     onAddTags: {
///         showingTagSelection = true
///     }
/// )
/// ```
struct TagsSection: View {
    @Binding var selectedTags: [Tag]
    let maxTags: Int
    let isReadOnly: Bool
    let accentColor: Color
    let onAddTags: () -> Void

    init(
        selectedTags: Binding<[Tag]>,
        maxTags: Int = 3,
        isReadOnly: Bool = false,
        accentColor: Color = .daisyTask,
        onAddTags: @escaping () -> Void
    ) {
        self._selectedTags = selectedTags
        self.maxTags = maxTags
        self.isReadOnly = isReadOnly
        self.accentColor = accentColor
        self.onAddTags = onAddTags
    }

    private var canAddMore: Bool {
        selectedTags.count < maxTags && !isReadOnly
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if selectedTags.isEmpty {
                // Empty state - "Add Tags" button
                emptyState
            } else {
                // Populated state - Tag chips with add button
                populatedState
            }
        }
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.daisyText)

            if !isReadOnly {
                Button(action: onAddTags) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                        Text("Add Tags")
                    }
                    .font(.body)
                    .foregroundColor(accentColor)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add tags")
            } else {
                Text("No tags")
                    .font(.body)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .padding(16)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var populatedState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.daisyText)

            WrappingHStack(spacing: 8) {
                ForEach(selectedTags, id: \.id) { tag in
                    TagChipView(
                        tag: tag,
                        isSelected: false,
                        isRemovable: !isReadOnly,
                        onRemove: {
                            removeTag(tag)
                        }
                    )
                }

                if canAddMore {
                    Button(action: onAddTags) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add more tags")
                }
            }
        }
        .padding(16)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func removeTag(_ tag: Tag) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTags.removeAll { $0.id == tag.id }
        }
    }
}

#Preview {
    @Previewable @State var emptyTags: [Tag] = []
    @Previewable @State var someTags: [Tag] = []

    // Note: Preview won't work perfectly without a real ModelContext,
    // but shows the structure
    VStack(spacing: 20) {
        // Empty state
        TagsSection(
            selectedTags: $emptyTags,
            onAddTags: { print("Add tags tapped") }
        )

        // Read-only empty state
        TagsSection(
            selectedTags: $emptyTags,
            isReadOnly: true,
            onAddTags: { print("Add tags tapped") }
        )

        Text("Preview: Tag chips would appear in populated state")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
    }
    .padding()
}
