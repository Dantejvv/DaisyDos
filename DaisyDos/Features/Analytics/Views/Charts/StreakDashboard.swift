//
//  StreakDashboard.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI

struct StreakDashboard: View {
    let streaks: [StreakData]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                    Text("Top Streaks")
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    Text("Your most consistent habits")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }

            // Streak List
            if streaks.isEmpty {
                emptyState
            } else {
                VStack(spacing: Spacing.small) {
                    ForEach(streaks) { streak in
                        StreakRow(streak: streak)
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(Color.daisySurface)
        )
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "flame")
                .font(.largeTitle)
                .foregroundColor(.daisyTextSecondary.opacity(0.5))

            Text("No active streaks")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Text("Start completing habits daily to build streaks")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

struct StreakRow: View {
    let streak: StreakData

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(
                        Color.daisyTextSecondary.opacity(0.2),
                        lineWidth: 3
                    )

                Circle()
                    .trim(from: 0, to: streak.progress)
                    .stroke(
                        streakColor.gradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(streak.currentStreak)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.daisyText)
            }
            .frame(width: 44, height: 44)

            // Habit info
            VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                Text(streak.habitName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
                    .lineLimit(1)

                HStack(spacing: Spacing.extraSmall) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("\(streak.currentStreak) day\(streak.currentStreak == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    if streak.longestStreak > streak.currentStreak {
                        Text("• Best: \(streak.longestStreak)")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }

            Spacer()

            // Next milestone
            VStack(alignment: .trailing, spacing: Spacing.extraSmall) {
                Text("\(streak.nextMilestone)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(streakColor)

                Text("goal")
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius * 0.5)
                .fill(Color.daisyBackground)
        )
    }

    private var streakColor: Color {
        switch streak.currentStreak {
        case 0: return .gray
        case 1..<7: return .blue
        case 7..<30: return .green
        case 30..<100: return .orange
        default: return .purple
        }
    }
}

#Preview("With Streaks") {
    StreakDashboard(streaks: [
        StreakData(
            id: UUID(),
            habitName: "Morning Exercise",
            currentStreak: 25,
            longestStreak: 30,
            progress: 0.7,
            nextMilestone: 30
        ),
        StreakData(
            id: UUID(),
            habitName: "Read for 30 minutes",
            currentStreak: 12,
            longestStreak: 15,
            progress: 0.5,
            nextMilestone: 14
        ),
        StreakData(
            id: UUID(),
            habitName: "Meditation",
            currentStreak: 7,
            longestStreak: 10,
            progress: 1.0,
            nextMilestone: 14
        )
    ])
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Empty State") {
    StreakDashboard(streaks: [])
        .padding()
        .background(Color.daisyBackground)
}
