//
//  HabitHeatmapView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct HabitHeatmapView: View {
    // MARK: - Properties

    let habit: Habit
    let habitManager: HabitManager
    let dateRange: ClosedRange<Date>

    @State private var heatmapData: [HeatmapDataPoint] = []
    @State private var selectedDay: HeatmapDataPoint?

    // MARK: - Computed Properties

    private let calendar = Calendar.current
    private let daysInWeek = 7

    private var calendarGrid: [[HeatmapDay]] {
        generateCalendarGrid()
    }

    private var weekdays: [String] {
        calendar.veryShortWeekdaySymbols
    }

    private var months: [(name: String, xPosition: CGFloat)] {
        generateMonthLabels()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            heatmapHeader

            // Heatmap Calendar
            VStack(alignment: .leading, spacing: 8) {
                // Month labels
                monthLabelsView

                // Calendar grid with weekday labels
                HStack(alignment: .top, spacing: 4) {
                    // Weekday labels
                    weekdayLabelsView

                    // Heatmap grid
                    heatmapGridView
                }
            }

            // Legend and selected day info
            heatmapFooter
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadHeatmapData()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var heatmapHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Completion History")
                .font(.headline)
                .foregroundColor(.daisyText)

            Text("Daily completion pattern over time")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    // MARK: - Month Labels

    @ViewBuilder
    private var monthLabelsView: some View {
        GeometryReader { geometry in
            ForEach(months, id: \.name) { month in
                Text(month.name)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
                    .position(x: month.xPosition, y: 8)
            }
        }
        .frame(height: 16)
        .padding(.leading, 32) // Account for weekday labels
    }

    // MARK: - Weekday Labels

    @ViewBuilder
    private var weekdayLabelsView: some View {
        VStack(spacing: 2) {
            // Empty space for month labels
            Color.clear
                .frame(height: 10)

            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
                    .frame(width: 24, height: 10)
            }
        }
    }

    // MARK: - Heatmap Grid

    @ViewBuilder
    private var heatmapGridView: some View {
        LazyHGrid(rows: Array(repeating: GridItem(.fixed(10), spacing: 2), count: daysInWeek), spacing: 2) {
            ForEach(calendarGrid.flatMap { $0 }, id: \.date) { day in
                HeatmapCell(
                    day: day,
                    isSelected: selectedDay?.date == day.date
                ) {
                    selectedDay = day.dataPoint
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedDay)
    }

    // MARK: - Footer

    @ViewBuilder
    private var heatmapFooter: some View {
        HStack {
            // Selected day info or overall stats
            if let selectedDay = selectedDay {
                selectedDayInfo(selectedDay)
            } else {
                overallStatsInfo
            }

            Spacer()

            // Intensity legend
            intensityLegend
        }
    }

    @ViewBuilder
    private func selectedDayInfo(_ dataPoint: HeatmapDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateFormatter.mediumDate.string(from: dataPoint.date))
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyText)

            if dataPoint.isCompleted {
                Text("\(dataPoint.completionCount) completion\(dataPoint.completionCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.daisySuccess)
            } else {
                Text("No completions")
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
    }

    @ViewBuilder
    private var overallStatsInfo: some View {
        let totalCompletions = heatmapData.reduce(0) { $0 + $1.completionCount }
        let completedDays = heatmapData.filter { $0.isCompleted }.count
        let totalDays = heatmapData.count

        VStack(alignment: .leading, spacing: 2) {
            Text("\(totalCompletions) total completions")
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyText)

            Text("\(completedDays)/\(totalDays) days")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    @ViewBuilder
    private var intensityLegend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)

            HStack(spacing: 2) {
                ForEach(0..<5) { intensity in
                    Rectangle()
                        .fill(heatmapColor(for: Double(intensity) / 4.0))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                }
            }

            Text("More")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    // MARK: - Helper Methods

    private func loadHeatmapData() {
        heatmapData = habitManager.getHeatmapData(for: habit, dateRange: dateRange)
    }

    private func generateCalendarGrid() -> [[HeatmapDay]] {
        var grid: [[HeatmapDay]] = []
        var currentWeek: [HeatmapDay] = []

        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound

        // Find the start of the first week (Sunday)
        let firstWeekday = calendar.component(.weekday, from: startDate)
        let daysBack = firstWeekday - 1
        let gridStartDate = calendar.date(byAdding: .day, value: -daysBack, to: startDate) ?? startDate

        var currentDate = gridStartDate

        while currentDate <= endDate {
            let dataPoint = heatmapData.first { calendar.isDate($0.date, inSameDayAs: currentDate) }

            let day = HeatmapDay(
                date: currentDate,
                dataPoint: dataPoint,
                isInRange: currentDate >= startDate && currentDate <= endDate
            )

            currentWeek.append(day)

            if currentWeek.count == daysInWeek {
                grid.append(currentWeek)
                currentWeek = []
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Add remaining days to complete the last week
        if !currentWeek.isEmpty {
            while currentWeek.count < daysInWeek {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                let day = HeatmapDay(
                    date: currentDate,
                    dataPoint: nil,
                    isInRange: false
                )
                currentWeek.append(day)
            }
            grid.append(currentWeek)
        }

        return grid
    }

    private func generateMonthLabels() -> [(name: String, xPosition: CGFloat)] {
        var labels: [(name: String, xPosition: CGFloat)] = []
        let cellWidth: CGFloat = 12 // 10 + 2 spacing
        var currentMonth = -1
        var weekIndex = 0
        var lastLabelPosition: CGFloat = -50 // Start with negative to ensure first label shows

        for week in calendarGrid {
            if let firstDay = week.first {
                let month = calendar.component(.month, from: firstDay.date)
                if month != currentMonth {
                    currentMonth = month
                    let monthName = DateFormatter.shortMonth.string(from: firstDay.date)
                    let xPosition = CGFloat(weekIndex) * cellWidth + cellWidth / 2

                    // Only add label if it's far enough from the last one to avoid overlap
                    if xPosition - lastLabelPosition >= 35 { // Minimum spacing of ~35pts
                        labels.append((name: monthName, xPosition: xPosition))
                        lastLabelPosition = xPosition
                    }
                }
            }
            weekIndex += 1
        }

        return labels
    }

    private func heatmapColor(for intensity: Double) -> Color {
        switch intensity {
        case 0:
            return Color.daisyBackground
        case 0.01..<0.3:
            return Color.daisyHabit.opacity(0.2)
        case 0.3..<0.6:
            return Color.daisyHabit.opacity(0.5)
        case 0.6..<0.9:
            return Color.daisyHabit.opacity(0.7)
        default:
            return Color.daisyHabit
        }
    }
}

// MARK: - Supporting Types

struct HeatmapDay {
    let date: Date
    let dataPoint: HeatmapDataPoint?
    let isInRange: Bool

    var intensity: Double {
        dataPoint?.intensity ?? 0.0
    }

    var isCompleted: Bool {
        dataPoint?.isCompleted ?? false
    }
}

struct HeatmapCell: View {
    let day: HeatmapDay
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: 10, height: 10)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        isSelected ? Color.daisyText : Color.clear,
                        lineWidth: isSelected ? 1 : 0
                    )
            )
            .opacity(day.isInRange ? 1.0 : 0.3)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .onTapGesture {
                if day.isInRange {
                    onTap()
                }
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Tap to see details")
            .accessibilityAddTraits(.isButton)
            .accessibilityElement(children: .ignore)
    }

    private var cellColor: Color {
        switch day.intensity {
        case 0:
            return Color.daisyBackground
        case 0.01..<0.3:
            return Color.daisyHabit.opacity(0.2)
        case 0.3..<0.6:
            return Color.daisyHabit.opacity(0.5)
        case 0.6..<0.9:
            return Color.daisyHabit.opacity(0.7)
        default:
            return Color.daisyHabit
        }
    }

    private var accessibilityLabel: String {
        let dateString = DateFormatter.accessibilityDate.string(from: day.date)
        if day.isCompleted {
            return "\(dateString), completed"
        } else {
            return "\(dateString), not completed"
        }
    }
}

// MARK: - Date Formatter Extensions

private extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let shortMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    static let accessibilityDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}

// MARK: - Preview

#Preview("Heatmap - 3 Months") {
    HabitHeatmapPreview(monthsBack: 3)
}

#Preview("Heatmap - 6 Months") {
    HabitHeatmapPreview(monthsBack: 6)
}

#Preview("Heatmap - 1 Year") {
    HabitHeatmapPreview(monthsBack: 12)
}

struct HabitHeatmapPreview: View {
    let monthsBack: Int

    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, HabitCompletion.self, HabitStreak.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let habitManager = HabitManager(modelContext: context)

        // Create sample habit
        let habit = Habit(
            title: "Daily Exercise",
            habitDescription: "30 minutes of physical activity",
            recurrenceRule: .daily()
        )
        context.insert(habit)

        // Add sample completions with varying patterns
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -monthsBack, to: endDate) ?? endDate

        for i in 0..<(monthsBack * 30) {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                // Simulate realistic completion patterns
                let weekday = calendar.component(.weekday, from: date)
                let isWeekend = weekday == 1 || weekday == 7
                let baseRate = isWeekend ? 60 : 80 // Lower completion on weekends

                if Int.random(in: 0...100) < baseRate {
                    let completion = HabitCompletion(
                        habit: habit,
                        completedDate: date,
                        mood: HabitCompletion.Mood.allCases.randomElement() ?? .neutral
                    )
                    context.insert(completion)
                }
            }
        }

        try! context.save()

        let dateRange = startDate...endDate

        return ScrollView(.horizontal, showsIndicators: false) {
            HabitHeatmapView(
                habit: habit,
                habitManager: habitManager,
                dateRange: dateRange
            )
            .padding()
        }
        .modelContainer(container)
        .background(Color.daisyBackground)
    }
}