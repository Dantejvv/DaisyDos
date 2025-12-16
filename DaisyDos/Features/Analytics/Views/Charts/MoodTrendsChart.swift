//
//  MoodTrendsChart.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI
import Charts

struct MoodTrendsChart: View {
    let data: [MoodDataPoint]
    let period: AnalyticsPeriod
    let averageMood: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.extraSmall) {
                    Text("Mood Trends")
                        .font(.headline)
                        .foregroundColor(.daisyText)

                    Text("Average mood during completions")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                // Average mood indicator
                if !data.isEmpty {
                    VStack(alignment: .trailing, spacing: Spacing.extraSmall) {
                        HStack(spacing: Spacing.extraSmall) {
                            Text(moodEmoji(for: averageMood))
                                .font(.title3)

                            Text(String(format: "%.1f", averageMood))
                                .font(.title3.weight(.bold))
                                .foregroundColor(colorForMood(averageMood))
                        }

                        Text(moodLabel(for: averageMood))
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
        Chart {
            ForEach(data) { dataPoint in
                // Line
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.averageMood)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                // Area under line
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.averageMood)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.accentColor.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Mood", dataPoint.averageMood)
                )
                .foregroundStyle(colorForMood(dataPoint.averageMood))
                .symbolSize(50)
            }

            // Average line
            RuleMark(y: .value("Average", averageMood))
                .foregroundStyle(Color.daisyTextSecondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Avg")
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                        .padding(.horizontal, Spacing.extraSmall)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.daisySurface)
                        )
                }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisValueLabel {
                    if let moodValue = value.as(Int.self) {
                        Text(moodEmoji(for: Double(moodValue)))
                            .font(.caption)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.daisyTextSecondary.opacity(0.2))
            }
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
        .frame(height: 200)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "face.smiling")
                .font(.largeTitle)
                .foregroundColor(.daisyTextSecondary.opacity(0.5))

            Text("No mood data yet")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Text("Track your mood when completing habits to see trends")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    private func moodEmoji(for mood: Double) -> String {
        switch mood {
        case 4.5...5.0: return "😄"
        case 3.5..<4.5: return "🙂"
        case 2.5..<3.5: return "😐"
        case 1.5..<2.5: return "😔"
        default: return "😢"
        }
    }

    private func moodLabel(for mood: Double) -> String {
        switch mood {
        case 4.5...5.0: return "Very Happy"
        case 3.5..<4.5: return "Happy"
        case 2.5..<3.5: return "Neutral"
        case 1.5..<2.5: return "Sad"
        default: return "Very Sad"
        }
    }

    private func colorForMood(_ mood: Double) -> Color {
        switch mood {
        case 4.5...5.0: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
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
        return MoodDataPoint(date: date, averageMood: Double.random(in: 2.5...4.5))
    }.reversed()

    return MoodTrendsChart(
        data: Array(sampleData),
        period: .sevenDays,
        averageMood: 3.7
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Empty State") {
    MoodTrendsChart(
        data: [],
        period: .sevenDays,
        averageMood: 3.0
    )
    .padding()
    .background(Color.daisyBackground)
}
