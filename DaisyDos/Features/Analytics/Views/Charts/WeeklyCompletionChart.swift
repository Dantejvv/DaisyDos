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

                    Text(chartSubtitle)
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
        Chart(aggregatedData) { dataPoint in
            BarMark(
                x: .value("Date", dataPoint.date, unit: chartUnit),
                y: .value("Completions", dataPoint.count)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(DesignSystem.cornerRadius * 0.5)
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
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

    private var chartSubtitle: String {
        switch period {
        case .sevenDays, .thirtyDays, .ninetyDays:
            return "Daily completions over \(period.displayName.lowercased())"
        case .year:
            return "Weekly completions this year"
        }
    }

    /// The calendar unit for bar width based on period
    private var chartUnit: Calendar.Component {
        switch period {
        case .sevenDays, .thirtyDays, .ninetyDays:
            return .day
        case .year:
            return .weekOfYear
        }
    }

    /// Aggregate data based on the period (weekly for year, daily otherwise)
    private var aggregatedData: [CompletionDataPoint] {
        switch period {
        case .sevenDays, .thirtyDays, .ninetyDays:
            return data
        case .year:
            return aggregateByWeek(data)
        }
    }

    /// Aggregate daily data points into weekly totals
    private func aggregateByWeek(_ dailyData: [CompletionDataPoint]) -> [CompletionDataPoint] {
        let calendar = Calendar.current
        var weeklyTotals: [Date: Int] = [:]

        for point in dailyData {
            // Get the start of the week for this date
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
            weeklyTotals[weekStart, default: 0] += point.count
        }

        return weeklyTotals
            .sorted { $0.key < $1.key }
            .map { CompletionDataPoint(date: $0.key, count: $0.value) }
    }

    /// X-axis values configuration based on period
    private var xAxisValues: AxisMarkValues {
        switch period {
        case .sevenDays:
            // Show all 7 days
            return .stride(by: .day, count: 1)
        case .thirtyDays:
            // Show ~6 labels evenly distributed
            return .stride(by: .day, count: 5)
        case .ninetyDays:
            // Show ~6 labels (every 2 weeks)
            return .stride(by: .day, count: 14)
        case .year:
            // Show monthly labels for weekly aggregated data
            return .stride(by: .month, count: 1)
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch period {
        case .sevenDays:
            formatter.dateFormat = "EEE"
        case .thirtyDays:
            formatter.dateFormat = "d"
        case .ninetyDays:
            formatter.dateFormat = "M/d"
        case .year:
            formatter.dateFormat = "MMM"
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
