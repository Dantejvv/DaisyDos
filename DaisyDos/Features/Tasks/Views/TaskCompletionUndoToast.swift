//
//  TaskCompletionUndoToast.swift
//  DaisyDos
//
//  Created by Claude Code on 10/13/25.
//  Task-specific undo toast - now uses generic CompletionUndoToast component
//

import SwiftUI
import SwiftData

// MARK: - Type Aliases (for backwards compatibility)

/// Type alias for TaskCompletionUndoToast using the generic component
typealias TaskCompletionUndoToast = CompletionUndoToast<Task>

/// Type alias for TaskCompletionToastManager using the generic component
/// Already defined in CompletionUndoToast.swift

/// Type alias for TaskCompletionToastContainer using the generic component
/// Already defined in CompletionUndoToast.swift

// MARK: - Preview

#Preview("Task Undo Toast") {
    struct PreviewWrapper: View {
        var body: some View {
            let container = try! ModelContainer(
                for: Task.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let task = Task(
                title: "Complete Quarterly Report",
                taskDescription: "Prepare comprehensive report",
                priority: .high,
                dueDate: Date()
            )
            context.insert(task)

            return VStack {
                Spacer()

                CompletionUndoToast(
                    entity: task,
                    config: .task(),
                    onUndo: {
                        print("Undo tapped")
                    },
                    isVisible: .constant(true)
                )
                .padding()

                Spacer()
            }
            .background(Color.daisyBackground)
            .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

#Preview("Task Toast Container") {
    CompletionToastContainer(config: .task()) {
        VStack {
            Text("Main Content")
                .font(.title)

            Button("Test Toast") {
                // This would trigger a toast in real usage
            }
            .padding()
        }
    }
}
