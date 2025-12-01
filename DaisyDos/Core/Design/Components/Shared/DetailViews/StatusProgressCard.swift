//
//  StatusProgressCard.swift
//  DaisyDos
//
//  Created by Claude Code on 1/11/25.
//  Reusable status and progress card for detail views
//

import SwiftUI

// MARK: - Status Progress Card

struct StatusProgressCard<Content: View>: View {
    let statusSections: Content
    let hasSubtasks: Bool
    let completedSubtaskCount: Int
    let totalSubtaskCount: Int
    let accentColor: Color

    init(
        hasSubtasks: Bool,
        completedSubtaskCount: Int,
        totalSubtaskCount: Int,
        accentColor: Color,
        @ViewBuilder statusSections: () -> Content
    ) {
        self.hasSubtasks = hasSubtasks
        self.completedSubtaskCount = completedSubtaskCount
        self.totalSubtaskCount = totalSubtaskCount
        self.accentColor = accentColor
        self.statusSections = statusSections()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status")
                .font(.headline)
                .foregroundColor(.daisyText)

            statusSections

            // Progress bar for subtasks
            if hasSubtasks {
                let progress = totalSubtaskCount > 0 ? Double(completedSubtaskCount) / Double(totalSubtaskCount) : 0.0

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.daisyTextSecondary.opacity(0.2))
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progress == 1.0 ? Color.daisySuccess : accentColor)
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(progress * 100))% Complete")
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Status Section Component

struct StatusSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let text: String
    let isLastSection: Bool

    init(title: String, icon: String, iconColor: Color, text: String, isLastSection: Bool = false) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.text = text
        self.isLastSection = isLastSection
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                    Text(text)
                        .font(.subheadline.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isLastSection {
                Divider()
                    .frame(height: 40)
            }
        }
    }
}

// MARK: - Subtask Status Section

struct SubtaskStatusSection: View {
    let hasSubtasks: Bool
    let completedCount: Int
    let totalCount: Int
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Subtasks")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
            if hasSubtasks {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .foregroundColor(accentColor)
                    Text("\(completedCount)/\(totalCount)")
                        .font(.subheadline.weight(.medium))
                }
            } else {
                Text("None")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Status Progress Card") {
    VStack(spacing: 20) {
        // Task style (2 sections)
        StatusProgressCard(
            hasSubtasks: true,
            completedSubtaskCount: 2,
            totalSubtaskCount: 5,
            accentColor: .daisyTask
        ) {
            HStack(spacing: 20) {
                // Completion
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.daisySuccess)
                        Text("Complete")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 40)

                SubtaskStatusSection(
                    hasSubtasks: true,
                    completedCount: 2,
                    totalCount: 5,
                    accentColor: .daisyTask
                )
            }
        }

        // Habit style (3 sections)
        StatusProgressCard(
            hasSubtasks: true,
            completedSubtaskCount: 3,
            totalSubtaskCount: 3,
            accentColor: .daisyHabit
        ) {
            HStack(spacing: 20) {
                // Today
                StatusSection(
                    title: "Today",
                    icon: "checkmark.circle.fill",
                    iconColor: .daisySuccess,
                    text: "Complete"
                )

                // Streak
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("15")
                            .font(.subheadline.weight(.medium))
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 40)

                SubtaskStatusSection(
                    hasSubtasks: true,
                    completedCount: 3,
                    totalCount: 3,
                    accentColor: .daisyHabit
                )
            }
        }
    }
    .padding()
}
