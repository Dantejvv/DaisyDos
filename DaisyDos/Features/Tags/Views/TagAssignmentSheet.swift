//
//  TagAssignmentSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TagAssignmentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selectedTags: [Tag]
    let onSave: ([Tag]) -> Void

    @State private var workingTags: [Tag] = []

    var hasChanges: Bool {
        Set(workingTags.map(\.id)) != Set(selectedTags.map(\.id))
    }

    var body: some View {
        NavigationStack {
            TagSelectionView(selectedTags: $workingTags)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(workingTags)
                            dismiss()
                        }
                        .disabled(!hasChanges)
                    }
                }
        }
        .onAppear {
            workingTags = selectedTags
        }
    }
}

// MARK: - Convenience Extensions

extension TagAssignmentSheet {
    static func forTask(
        task: Task,
        onSave: @escaping ([Tag]) -> Void
    ) -> TagAssignmentSheet {
        let binding = Binding<[Tag]>(
            get: { task.tags },
            set: { _ in }
        )

        return TagAssignmentSheet(
            title: "Task Tags",
            selectedTags: binding,
            onSave: onSave
        )
    }

    static func forHabit(
        habit: Habit,
        onSave: @escaping ([Tag]) -> Void
    ) -> TagAssignmentSheet {
        let binding = Binding<[Tag]>(
            get: { habit.tags },
            set: { _ in }
        )

        return TagAssignmentSheet(
            title: "Habit Tags",
            selectedTags: binding,
            onSave: onSave
        )
    }
}

#Preview {
    @Previewable @State var selectedTags: [Tag] = []

    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create some sample tags
    let tag1 = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
    _ = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")

    selectedTags.append(tag1)

    return TagAssignmentSheet(
        title: "Select Tags",
        selectedTags: $selectedTags,
        onSave: { _ in }
    )
    .modelContainer(container)
    .environment(tagManager)
}