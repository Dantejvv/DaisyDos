//
//  StreakVisualizationView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import Charts
import SwiftData

struct StreakVisualizationView: View {
    // MARK: - Properties

    let habit: Habit
    let habitManager: HabitManager

    @State private var selectedStreak: ChartDataPoint?
    @State private var streakData: [ChartDataPoint] = []
    @State private var milestoneProgress: MilestoneProgress?

    // MARK: - Computed Properties

    private var currentStreak: Int {
        habitManager.calculateAccurateStreak(for: habit)
    }

    private var streakQuality: HabitStreak.StreakQuality {
        habitManager.getStreakQuality(for: habit)
    }

    private var maxStreakValue: Double {
        let maxStreak = max(streakData.map(\.value).max() ?? 0, Double(currentStreak))
        return max(maxStreak * 1.2, 10) // Minimum scale of 10 days
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with current streak
            streakHeader

            // Milestone Progress
            milestoneProgressView

            // Streak History Chart
            if !streakData.isEmpty {
                streakHistoryChart
                    .frame(height: 180)
            }

            // Streak Quality and Momentum
            streakMetrics
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadStreakData()
            loadMilestoneProgress()
        }
    }

    // MARK: - Streak Header

    @ViewBuilder
    private var streakHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.headline)
                    .foregroundColor(.daisyText)

                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    Text("\(currentStreak)")
                        .font(.title.weight(.bold))
                        .foregroundColor(.daisyText)

                    Text("days")
                        .font(.title3)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Spacer()

            // Streak Quality Badge
            streakQualityBadge
        }
    }

    @ViewBuilder
    private var streakQualityBadge: some View {
        VStack(spacing: 4) {
            Text(streakQuality.emoji)
                .font(.title2)

            Text(streakQuality.displayName)
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(streakQuality.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(streakQuality.color, lineWidth: 1)
        )
    }

    // MARK: - Milestone Progress

    @ViewBuilder
    private var milestoneProgressView: some View {
        if let milestone = milestoneProgress {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next Milestone")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyText)

                    Spacer()

                    Text("\(milestone.current)/\(milestone.nextMilestone)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.daisyBackground)
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * milestone.progress, height: 8)
                            .animation(.easeInOut(duration: 1.0), value: milestone.progress)

                        // Milestone marker
                        Circle()
                            .fill(.orange)
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * milestone.progress - 6)
                            .animation(.spring(duration: 1.0), value: milestone.progress)
                    }
                }
                .frame(height: 8)

                // Milestone type and celebration
                if let milestoneType = milestone.milestoneType {
                    Text("\(milestoneType.emoji) \(milestoneType.displayName)")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Streak History Chart

    @ViewBuilder
    private var streakHistoryChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Streak History")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            Chart(streakData, id: \.date) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Streak Length", dataPoint.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: streakGradientColors(for: dataPoint.value),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)

                if let selectedStreak = selectedStreak,
                   Calendar.current.isDate(dataPoint.date, inSameDayAs: selectedStreak.date) {
                    BarMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Streak Length", dataPoint.value)
                    )
                    .foregroundStyle(Color.daisyText.opacity(0.3))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0...maxStreakValue)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
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
            .animation(.easeInOut(duration: 0.5), value: streakData)

            // Selected streak info
            if let selectedStreak = selectedStreak {
                selectedStreakInfo(selectedStreak)
            }
        }
    }

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

    @ViewBuilder
    private func selectedStreakInfo(_ dataPoint: ChartDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak: \(Int(dataPoint.value)) days")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyText)

                Text(dataPoint.label)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
            }

            Spacer()

            if let quality = dataPoint.metadata["quality"] as? String {
                Text(quality)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.daisyBackground, in: Capsule())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Streak Metrics

    @ViewBuilder
    private var streakMetrics: some View {
        HStack {
            // Longest Streak
            metricCard(
                title: "Longest",
                value: "\(habit.longestStreak)",
                subtitle: "days",
                color: .daisySuccess
            )

            Spacer()

            // Average Streak Length
            metricCard(
                title: "Average",
                value: String(format: "%.1f", averageStreakLength),
                subtitle: "days",
                color: .daisyTask
            )

            Spacer()

            // Total Streaks
            metricCard(
                title: "Total",
                value: "\(streakData.count)",
                subtitle: "streaks",
                color: .daisyHabit
            )
        }
    }

    @ViewBuilder
    private func metricCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Computed Values

    private var averageStreakLength: Double {
        guard !streakData.isEmpty else { return 0.0 }
        return streakData.map(\.value).reduce(0, +) / Double(streakData.count)
    }

    // MARK: - Helper Methods

    private func loadStreakData() {
        streakData = habitManager.getChartData(for: habit, type: .streak, period: .year)
    }

    private func loadMilestoneProgress() {
        milestoneProgress = habitManager.getMilestoneProgress(for: habit)
    }

    private func streakGradientColors(for streakLength: Double) -> [Color] {
        switch streakLength {
        case 0..<7:
            return [.gray.opacity(0.3), .gray]
        case 7..<21:
            return [.blue.opacity(0.3), .blue]
        case 21..<50:
            return [.green.opacity(0.3), .green]
        case 50..<100:
            return [.orange.opacity(0.3), .orange]
        default:
            return [.red.opacity(0.3), .red]
        }
    }

    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geometry[plotFrame].origin

        let plotLocation = CGPoint(
            x: location.x - origin.x,
            y: location.y - origin.y
        )

        if let date: Date = proxy.value(atX: plotLocation.x) {
            let closestDataPoint = streakData.min { dataPoint1, dataPoint2 in
                abs(dataPoint1.date.timeIntervalSince(date)) < abs(dataPoint2.date.timeIntervalSince(date))
            }

            selectedStreak = closestDataPoint
        }
    }
}

// MARK: - Preview

#Preview("Streak Visualization") {
    StreakVisualizationPreview()
}

struct StreakVisualizationPreview: View {
    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, HabitCompletion.self, HabitStreak.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let habitManager = HabitManager(modelContext: context)

        // Create sample habit
        let habit = Habit(
            title: "Daily Reading",
            habitDescription: "Read for 30 minutes every day",
            recurrenceRule: .daily()
        )
        habit.currentStreak = 23
        habit.longestStreak = 45
        context.insert(habit)

        // Add sample streaks
        let calendar = Calendar.current
        let streakDates = [
            (calendar.date(byAdding: .month, value: -6, to: Date())!, 12),
            (calendar.date(byAdding: .month, value: -4, to: Date())!, 8),
            (calendar.date(byAdding: .month, value: -3, to: Date())!, 45), // Longest streak
            (calendar.date(byAdding: .month, value: -1, to: Date())!, 23)  // Current streak
        ]

        for (startDate, length) in streakDates {
            let streak = HabitStreak(habit: habit, startDate: startDate)
            streak.length = length
            streak.isActive = length == 23 // Current streak is active
            habit.streaks.append(streak)
        }

        // Add recent completions for current streak
        for i in 0..<23 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let completion = HabitCompletion(
                    habit: habit,
                    completedDate: date,
                    mood: HabitCompletion.Mood.allCases.randomElement() ?? .neutral
                )
                context.insert(completion)
            }
        }

        try! context.save()

        return ScrollView {
            VStack(spacing: 20) {
                StreakVisualizationView(
                    habit: habit,
                    habitManager: habitManager
                )
            }
            .padding()
        }
        .modelContainer(container)
        .background(Color.daisyBackground)
    }
}