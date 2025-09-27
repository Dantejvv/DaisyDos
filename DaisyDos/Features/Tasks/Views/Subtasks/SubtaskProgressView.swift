//
//  SubtaskProgressView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI

// MARK: - Progress Ring Component

struct SubtaskProgressRing: View {
    let task: Task
    let size: CGFloat
    let lineWidth: CGFloat

    private var progress: Double {
        task.subtaskCompletionPercentage
    }

    private var completedCount: Int {
        task.completedSubtaskCount
    }

    private var totalCount: Int {
        task.subtaskCount
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.daisyTextSecondary.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 2) {
                Text("\(completedCount)")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)

                Text("of \(totalCount)")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(completedCount) of \(totalCount) subtasks completed")
        .accessibilityValue("\(Int(progress * 100))% complete")
    }

    private var progressColor: Color {
        switch progress {
        case 0:
            return .daisyTextSecondary
        case 0..<0.5:
            return .daisyWarning
        case 0.5..<1.0:
            return .daisyTask
        case 1.0:
            return .daisySuccess
        default:
            return .daisyTask
        }
    }
}

// MARK: - Progress Bar Component

struct SubtaskProgressBar: View {
    let task: Task
    let height: CGFloat

    private var progress: Double {
        task.subtaskCompletionPercentage
    }

    private var segments: [SubtaskSegment] {
        task.subtasks.enumerated().map { index, subtask in
            SubtaskSegment(
                id: subtask.id,
                isCompleted: subtask.isCompleted,
                color: segmentColor(for: subtask, at: index)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress bar with segments
            HStack(spacing: 1) {
                ForEach(segments, id: \.id) { segment in
                    Rectangle()
                        .fill(segment.isCompleted ? segment.color : segment.color.opacity(0.3))
                        .frame(height: height)
                        .animation(.easeInOut(duration: 0.3), value: segment.isCompleted)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: height / 2))

            // Progress text
            HStack {
                Text("\(task.completedSubtaskCount) of \(task.subtaskCount) completed")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(progressColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Subtask progress")
        .accessibilityValue("\(task.completedSubtaskCount) of \(task.subtaskCount) completed, \(Int(progress * 100))% done")
    }

    private func segmentColor(for subtask: Task, at index: Int) -> Color {
        let colors: [Color] = [.daisyTask, .daisySuccess, .daisyCTA, .daisyHabit]
        return colors[index % colors.count]
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .daisyWarning
        case 0.5..<1.0: return .daisyTask
        case 1.0: return .daisySuccess
        default: return .daisyTextSecondary
        }
    }
}

// MARK: - Supporting Types

private struct SubtaskSegment {
    let id: UUID
    let isCompleted: Bool
    let color: Color
}

// MARK: - Progress Summary Component

struct SubtaskProgressSummary: View {
    let task: Task
    let style: SummaryStyle

    enum SummaryStyle {
        case compact, detailed, card
    }

    private var progress: Double {
        task.subtaskCompletionPercentage
    }

    var body: some View {
        switch style {
        case .compact:
            compactSummary
        case .detailed:
            detailedSummary
        case .card:
            cardSummary
        }
    }

    @ViewBuilder
    private var compactSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.bullet.circle")
                .foregroundColor(.daisyTextSecondary)
                .font(.caption)

            Text("\(task.completedSubtaskCount)/\(task.subtaskCount)")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

            if progress > 0 {
                ProgressView(value: progress)
                    .tint(progressColor)
                    .frame(width: 40)
            }
        }
    }

    @ViewBuilder
    private var detailedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Subtasks", systemImage: "list.bullet")
                    .font(.headline)

                Spacer()

                Text("\(task.completedSubtaskCount)/\(task.subtaskCount)")
                    .font(.headline.weight(.medium))
                    .foregroundColor(progressColor)
            }

            ProgressView(value: progress)
                .tint(progressColor)

            HStack {
                Text(progressDescription)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Spacer()

                if progress == 1.0 {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.daisySuccess)
                }
            }
        }
    }

    @ViewBuilder
    private var cardSummary: some View {
        VStack(spacing: 16) {
            HStack {
                SubtaskProgressRing(task: task, size: 60, lineWidth: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subtask Progress")
                        .font(.headline)

                    Text(progressDescription)
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)

                    if task.isPartiallyComplete {
                        Text("In Progress")
                            .font(.caption)
                            .foregroundColor(.daisyTask)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.daisyTask.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()
            }

            if task.subtaskCount > 0 {
                SubtaskProgressBar(task: task, height: 8)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .daisyWarning
        case 0.5..<1.0: return .daisyTask
        case 1.0: return .daisySuccess
        default: return .daisyTextSecondary
        }
    }

    private var progressDescription: String {
        switch progress {
        case 0:
            return "Not started"
        case 0..<0.25:
            return "Just getting started"
        case 0.25..<0.5:
            return "Making progress"
        case 0.5..<0.75:
            return "Halfway there"
        case 0.75..<1.0:
            return "Nearly complete"
        case 1.0:
            return "All subtasks completed"
        default:
            return "\(Int(progress * 100))% complete"
        }
    }
}

// MARK: - Interactive Progress View

struct InteractiveSubtaskProgressView: View {
    let task: Task
    let onSubtaskTapped: (Task) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress summary
            Button(action: {
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    SubtaskProgressRing(task: task, size: 40, lineWidth: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Subtasks")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyText)

                        Text("\(task.completedSubtaskCount) of \(task.subtaskCount) completed")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.daisyTextSecondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.daisySurface)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Expandable subtask list
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(task.subtasks.prefix(5), id: \.id) { subtask in
                        Button(action: {
                            onSubtaskTapped(subtask)
                        }) {
                            HStack {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .daisySuccess : .daisyTextSecondary)

                                Text(subtask.title)
                                    .font(.subheadline)
                                    .strikethrough(subtask.isCompleted)
                                    .foregroundColor(subtask.isCompleted ? .daisyTextSecondary : .daisyText)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.daisySurface.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    if task.subtaskCount > 5 {
                        Text("+ \(task.subtaskCount - 5) more subtasks")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Subtask progress")
    }
}

#Preview("Progress Ring") {
    let task = Task(title: "Sample Task", priority: .medium)
    let subtask1 = Task(title: "Subtask 1", priority: .low)
    let subtask2 = Task(title: "Subtask 2", priority: .low)
    let subtask3 = Task(title: "Subtask 3", priority: .low)

    _ = task.addSubtask(subtask1)
    _ = task.addSubtask(subtask2)
    _ = task.addSubtask(subtask3)

    subtask1.setCompleted(true)
    subtask2.setCompleted(true)

    return VStack(spacing: 20) {
        SubtaskProgressRing(task: task, size: 80, lineWidth: 8)
        SubtaskProgressRing(task: task, size: 60, lineWidth: 6)
        SubtaskProgressRing(task: task, size: 40, lineWidth: 4)
    }
    .padding()
}

#Preview("Progress Bar") {
    let task = Task(title: "Sample Task", priority: .medium)
    let subtask1 = Task(title: "Subtask 1", priority: .low)
    let subtask2 = Task(title: "Subtask 2", priority: .low)
    let subtask3 = Task(title: "Subtask 3", priority: .low)
    let subtask4 = Task(title: "Subtask 4", priority: .low)

    _ = task.addSubtask(subtask1)
    _ = task.addSubtask(subtask2)
    _ = task.addSubtask(subtask3)
    _ = task.addSubtask(subtask4)

    subtask1.setCompleted(true)
    subtask3.setCompleted(true)

    return VStack(spacing: 20) {
        SubtaskProgressBar(task: task, height: 8)
        SubtaskProgressBar(task: task, height: 12)
    }
    .padding()
}

#Preview("Progress Summary") {
    let task = Task(title: "Build Mobile App", priority: .high)
    let subtask1 = Task(title: "Setup Project", priority: .medium)
    let subtask2 = Task(title: "Design UI", priority: .medium)
    let subtask3 = Task(title: "Implement Features", priority: .high)

    _ = task.addSubtask(subtask1)
    _ = task.addSubtask(subtask2)
    _ = task.addSubtask(subtask3)

    subtask1.setCompleted(true)

    return VStack(spacing: 20) {
        SubtaskProgressSummary(task: task, style: .compact)
        SubtaskProgressSummary(task: task, style: .detailed)
        SubtaskProgressSummary(task: task, style: .card)
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Interactive Progress") {
    let task = Task(title: "Build Mobile App", priority: .high)
    let subtask1 = Task(title: "Setup Xcode Project", priority: .medium)
    let subtask2 = Task(title: "Design User Interface", priority: .medium)
    let subtask3 = Task(title: "Implement Core Features", priority: .high)
    let subtask4 = Task(title: "Write Unit Tests", priority: .medium)

    _ = task.addSubtask(subtask1)
    _ = task.addSubtask(subtask2)
    _ = task.addSubtask(subtask3)
    _ = task.addSubtask(subtask4)

    subtask1.setCompleted(true)
    subtask2.setCompleted(true)

    return InteractiveSubtaskProgressView(task: task) { subtask in
        print("Tapped subtask: \(subtask.title)")
    }
    .padding()
    .background(Color.daisyBackground)
}