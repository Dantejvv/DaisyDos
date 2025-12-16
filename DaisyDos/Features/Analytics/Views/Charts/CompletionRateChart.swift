//
//  CompletionRateChart.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI
import Charts

struct CompletionRateChart: View {
    let data: [CompletionRateData]
    let totalHabits: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    Text("Habit completion status")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                // Percentage
                if let firstItem = data.first, data.count == 1 && firstItem.category == "No Habits" {
                    // Empty state indicator
                    Text("--")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.daisyTextSecondary)
                } else if let completedData = data.first(where: { $0.category == "Completed" }) {
                    Text(completedData.percentageText)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.green)
                } else {
                    Text("0%")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            // Chart
            if totalHabits == 0 || (data.count == 1 && data.first?.category == "No Habits") {
                emptyState
            } else {
                HStack(spacing: Spacing.large) {
                    // Pie Chart
                    chart
                        .frame(width: 120, height: 120)

                    // Legend
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        ForEach(data) { item in
                            LegendItem(
                                color: colorForCategory(item.category),
                                label: item.category,
                                count: item.count,
                                percentage: item.percentageText
                            )
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(Color.daisySurface)
        )
    }

    private var chart: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(colorForCategory(item.category))
            .cornerRadius(DesignSystem.cornerRadius * 0.5)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundColor(.daisyTextSecondary.opacity(0.5))

            Text("No habits today")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Text("Create some habits to track your progress")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Completed": return .green
        case "Pending": return .orange
        default: return .gray
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    let percentage: String

    var body: some View {
        HStack(spacing: Spacing.extraSmall) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption)
                .foregroundColor(.daisyText)

            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

            Text(percentage)
                .font(.caption.weight(.medium))
                .foregroundColor(color)
        }
    }
}

#Preview("With Data") {
    CompletionRateChart(
        data: [
            CompletionRateData(category: "Completed", count: 7, percentage: 0.7),
            CompletionRateData(category: "Pending", count: 3, percentage: 0.3)
        ],
        totalHabits: 10
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("All Completed") {
    CompletionRateChart(
        data: [
            CompletionRateData(category: "Completed", count: 10, percentage: 1.0)
        ],
        totalHabits: 10
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Empty State") {
    CompletionRateChart(
        data: [
            CompletionRateData(category: "No Habits", count: 0, percentage: 1.0)
        ],
        totalHabits: 0
    )
    .padding()
    .background(Color.daisyBackground)
}
