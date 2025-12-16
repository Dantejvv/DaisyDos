//
//  WeeklyCompletionChart.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI
import Charts

struct WeeklyCompletionChart: View {
    let data: [CompletionDataPoint]
    let period: AnalyticsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                    Text("Habit Completions")
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    Text("Daily completions over \(period.displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                // Total completions
                if !data.isEmpty {
                    VStack(alignment: .trailing, spacing: Spacing.extraSmall) {
                        Text("\(totalCompletions)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.accentColor)

                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }

            // Chart
            if data.isEmpty {
                emptyState
            } else {
                chart
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(Color.daisySurface)
        )
    }

    private var chart: some View {
        Chart(data) { dataPoint in
            BarMark(
                x: .value("Date", dataPoint.date, unit: .day),
                y: .value("Completions", dataPoint.count)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(DesignSystem.cornerRadius * 0.5)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisDate(date))
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.daisyTextSecondary.opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.daisyTextSecondary.opacity(0.2))
            }
        }
        .frame(height: 200)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.daisyTextSecondary.opacity(0.5))

            Text("No completions yet")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Text("Complete some habits to see your progress here")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var totalCompletions: Int {
        data.reduce(0) { $0 + $1.count }
    }

    private var xAxisStride: Int {
        switch period {
        case .sevenDays: return 1
        case .thirtyDays: return 5
        case .ninetyDays: return 15
        case .year: return 30
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch period {
        case .sevenDays:
            formatter.dateFormat = "EEE"
        case .thirtyDays:
            formatter.dateFormat = "M/d"
        case .ninetyDays, .year:
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

#Preview("With Data") {
    let calendar = Calendar.current
    let today = Date()
    let sampleData = (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        return CompletionDataPoint(date: date, count: Int.random(in: 1...10))
    }.reversed()

    return WeeklyCompletionChart(
        data: Array(sampleData),
        period: .sevenDays
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Empty State") {
    WeeklyCompletionChart(
        data: [],
        period: .sevenDays
    )
    .padding()
    .background(Color.daisyBackground)
}
