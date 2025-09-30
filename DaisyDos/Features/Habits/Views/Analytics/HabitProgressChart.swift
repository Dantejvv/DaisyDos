//
//  HabitProgressChart.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import Charts
import SwiftData

struct HabitProgressChart: View {
    // MARK: - Properties

    let habit: Habit
    let timeframe: AnalyticsTimeframe
    let habitManager: HabitManager

    @State private var selectedDataPoint: ChartDataPoint?
    @State private var chartData: [ChartDataPoint] = []

    // MARK: - Computed Properties

    private var period: AnalyticsPeriod {
        switch timeframe {
        case .week: return .week
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        }
    }

    private var chartTitle: String {
        "Completion Trend - \(timeframe.displayName)"
    }

    private var yAxisMax: Double {
        let maxValue = chartData.map(\.value).max() ?? 1.0
        return max(maxValue * 1.2, 1.0) // Add 20% padding
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header
            chartHeader

            // Main Chart
            chartView
                .frame(height: 200)

            // Chart Legend and Stats
            chartFooter
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadChartData()
        }
        .onChange(of: timeframe) { _, _ in
            loadChartData()
        }
    }

    // MARK: - Chart Header

    @ViewBuilder
    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chartTitle)
                .font(.headline)
                .foregroundColor(.daisyText)

            Text("Weekly completion frequency")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        Chart(chartData, id: \.date) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Completions", dataPoint.value)
            )
            .foregroundStyle(Color.daisyHabit)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Completions", dataPoint.value)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [Color.daisyHabit.opacity(0.3), Color.daisyHabit.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            if let selectedDataPoint = selectedDataPoint,
               Calendar.current.isDate(dataPoint.date, inSameDayAs: selectedDataPoint.date) {
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Completions", dataPoint.value)
                )
                .foregroundStyle(Color.daisyHabit)
                .symbolSize(64)
            }
        }
        .chartYScale(domain: 0...yAxisMax)
        .chartXAxis {
            AxisMarks(values: .stride(by: timeAxisStride)) { _ in
                AxisGridLine()
                AxisValueLabel(format: timeAxisFormat)
            }
        }
        .chartYAxis {
            AxisMarks(format: IntegerFormatStyle<Int>())
        }
        .chartBackground { _ in
            Color.daisyBackground.opacity(0.1)
        }
        .chartOverlay { proxy in
            chartOverlay(proxy: proxy)
        }
        .animation(.easeInOut(duration: 0.5), value: chartData)
    }

    // MARK: - Chart Overlay for Interaction

    @ViewBuilder
    private func chartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleChartTap(location: location, geometry: geometry, proxy: proxy)
                }
        }
    }

    // MARK: - Chart Footer

    @ViewBuilder
    private var chartFooter: some View {
        HStack {
            // Selected Data Point Info
            if let selectedDataPoint = selectedDataPoint {
                selectedDataPointInfo(selectedDataPoint)
            } else {
                overallStatsInfo
            }

            Spacer()

            // Trend Indicator
            trendIndicator
        }
    }

    @ViewBuilder
    private func selectedDataPointInfo(_ dataPoint: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dataPoint.label)
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyText)

            Text("\(Int(dataPoint.value)) completions")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    @ViewBuilder
    private var overallStatsInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Average: \(averageCompletions, specifier: "%.1f")")
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyText)

            Text("Total: \(totalCompletions)")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    @ViewBuilder
    private var trendIndicator: some View {
        let trend = habitManager.getCompletionTrend(for: habit, period: period)

        HStack(spacing: 4) {
            Text(trend.emoji)
                .font(.caption)

            Text(trend.displayName)
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.daisyBackground, in: Capsule())
    }

    // MARK: - Computed Values

    private var averageCompletions: Double {
        guard !chartData.isEmpty else { return 0.0 }
        return chartData.map(\.value).reduce(0, +) / Double(chartData.count)
    }

    private var totalCompletions: Int {
        Int(chartData.map(\.value).reduce(0, +))
    }

    private var timeAxisStride: Calendar.Component {
        switch timeframe {
        case .week: return .day
        case .month: return .weekOfYear
        case .quarter: return .month
        case .year: return .month
        }
    }

    private var timeAxisFormat: Date.FormatStyle {
        switch timeframe {
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        case .quarter: return .dateTime.month(.abbreviated)
        case .year: return .dateTime.month(.abbreviated)
        }
    }

    // MARK: - Methods

    private func loadChartData() {
        chartData = habitManager.getChartData(for: habit, type: .completion, period: period)
    }

    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geometry[plotFrame].origin

        // Convert tap location to plot area coordinates
        let plotLocation = CGPoint(
            x: location.x - origin.x,
            y: location.y - origin.y
        )

        // Get the date value at the tap location
        if let date: Date = proxy.value(atX: plotLocation.x) {
            // Find the closest data point
            let closestDataPoint = chartData.min { dataPoint1, dataPoint2 in
                abs(dataPoint1.date.timeIntervalSince(date)) < abs(dataPoint2.date.timeIntervalSince(date))
            }

            selectedDataPoint = closestDataPoint
        }
    }
}

// MARK: - Preview

#Preview("Progress Chart - Week") {
    HabitProgressChartPreview(timeframe: .week)
}

#Preview("Progress Chart - Month") {
    HabitProgressChartPreview(timeframe: .month)
}

#Preview("Progress Chart - Year") {
    HabitProgressChartPreview(timeframe: .year)
}

struct HabitProgressChartPreview: View {
    let timeframe: AnalyticsTimeframe

    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, HabitCompletion.self, HabitStreak.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let habitManager = HabitManager(modelContext: context)

        // Create sample habit with completions
        let habit = Habit(
            title: "Morning Exercise",
            habitDescription: "30 minutes of cardio to start the day",
            recurrenceRule: .daily()
        )
        habit.currentStreak = 12
        habit.longestStreak = 21
        context.insert(habit)

        // Add sample completions over time
        let calendar = Calendar.current
        for i in 0..<30 {
            if Int.random(in: 0...100) < 75 { // 75% completion rate
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                let completion = HabitCompletion(
                    habit: habit,
                    completedDate: date,
                    mood: HabitCompletion.Mood.allCases.randomElement() ?? .neutral
                )
                context.insert(completion)
            }
        }

        try! context.save()

        return VStack(spacing: 20) {
            HabitProgressChart(
                habit: habit,
                timeframe: timeframe,
                habitManager: habitManager
            )
        }
        .modelContainer(container)
        .padding()
        .background(Color.daisyBackground)
    }
}