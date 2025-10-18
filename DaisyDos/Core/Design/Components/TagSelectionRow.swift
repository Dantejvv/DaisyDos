//
//  TagSelectionRow.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Reusable tag selection UI for Tasks and Habits
//

import SwiftUI

/// A horizontal scrollable tag selection row with add/remove functionality
struct TagSelectionRow: View {
    @Binding var selectedTags: [Tag]
    let accentColor: Color
    let onShowTagSelection: () -> Void

    private let maxTags = 3

    init(
        selectedTags: Binding<[Tag]>,
        accentColor: Color = .daisyTask,
        onShowTagSelection: @escaping () -> Void
    ) {
        self._selectedTags = selectedTags
        self.accentColor = accentColor
        self.onShowTagSelection = onShowTagSelection
    }

    var body: some View {
        if selectedTags.isEmpty {
            Button("Add Tags") {
                onShowTagSelection()
            }
            .foregroundColor(accentColor)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.id) { tag in
                            TagChipView(
                                tag: tag,
                                isSelected: true,
                                isRemovable: true,
                                onRemove: {
                                    selectedTags.removeAll { $0.id == tag.id }
                                }
                            )
                        }

                        if selectedTags.count < maxTags {
                            Button(action: onShowTagSelection) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(accentColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add more tags")
                        }
                    }
                    .padding(.horizontal, 4)
                }

                if selectedTags.count == maxTags {
                    Text("Maximum tags reached (\(maxTags)/\(maxTags))")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var tags: [Tag] = []

    Form {
        Section("Tags") {
            TagSelectionRow(
                selectedTags: $tags,
                accentColor: .daisyTask,
                onShowTagSelection: { }
            )
        }
    }
}
