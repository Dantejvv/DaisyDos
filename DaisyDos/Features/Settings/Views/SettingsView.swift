//
//  SettingsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(LocalOnlyModeManager.self) private var localOnlyModeManager
    @Environment(PerformanceMonitor.self) private var performanceMonitor
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager
    @State private var showingAbout = false
    @State private var showingTestViews = false
    @State private var showingPerformance = false

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    HStack {
                        Label("Local-Only Mode", systemImage: "lock.shield")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .disabled(true)
                    }
                    Text("DaisyDos keeps your data private by default.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Performance") {
                    PerformanceStatusRow(performanceMonitor: performanceMonitor)

                    Button(action: { showingPerformance = true }) {
                        Label("Performance Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section("Data Overview") {
                    HStack {
                        Label("Tasks", systemImage: "list.bullet")
                        Spacer()
                        Text("\(taskManager.taskCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Habits", systemImage: "repeat.circle")
                        Spacer()
                        Text("\(habitManager.habitCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Tags", systemImage: "tag")
                        Spacer()
                        Text("\(tagManager.tagCount)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("App Information") {
                    Button(action: { showingAbout = true }) {
                        Label("About DaisyDos", systemImage: "questionmark.circle")
                    }

                    Button(action: { showingTestViews = true }) {
                        Label("Developer Tools", systemImage: "hammer.circle")
                    }

                    HStack {
                        Label("Version", systemImage: "apps.iphone")
                        Spacer()
                        Text("1.0.0 Beta")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingTestViews) {
                DeveloperToolsView()
            }
            .sheet(isPresented: $showingPerformance) {
                PerformanceDashboardView()
            }
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "flower")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text("DaisyDos")
                        .font(.largeTitle.bold())

                    Text("A unified productivity app for tasks and habits")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("DaisyDos combines task management and habit tracking in a single, privacy-first application. Built with SwiftUI and SwiftData, it focuses on simplicity, accessibility, and keeping your data private.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Developer Tools View

private struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                ModelTestView()
                    .tabItem {
                        Label("Models", systemImage: "hammer.circle")
                    }

                ManagerTestView()
                    .tabItem {
                        Label("Managers", systemImage: "gearshape.circle")
                    }

                ErrorHandlingTestView()
                    .tabItem {
                        Label("Errors", systemImage: "exclamationmark.triangle.fill")
                    }

                DesignSystemTestView()
                    .tabItem {
                        Label("Design", systemImage: "paintpalette.fill")
                    }

                ComponentTestView()
                    .tabItem {
                        Label("Components", systemImage: "square.stack.3d.up.fill")
                    }

                PerformanceTestView()
                    .tabItem {
                        Label("Performance", systemImage: "speedometer")
                    }
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return SettingsView()
        .modelContainer(container)
        .environment(LocalOnlyModeManager())
        .environment(PerformanceMonitor.shared)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}

// MARK: - Performance Dashboard Components

/// Performance status row for Settings view
private struct PerformanceStatusRow: View {
    let performanceMonitor: PerformanceMonitor

    var body: some View {
        let summary = performanceMonitor.getPerformanceSummary()

        HStack {
            Label("Performance Status", systemImage: "speedometer")
            Spacer()

            HStack(spacing: 8) {
                // Launch time indicator
                Circle()
                    .fill(summary.launchTimeMeetsTarget ? .green : .red)
                    .frame(width: 8, height: 8)

                // Memory indicator
                Circle()
                    .fill(summary.memoryMeetsTarget ? .green : .red)
                    .frame(width: 8, height: 8)

                // UI response indicator
                Circle()
                    .fill(summary.uiResponseMeetsTarget ? .green : .red)
                    .frame(width: 8, height: 8)

                Text(summary.overallHealthy ? "Good" : "Issues")
                    .font(.caption)
                    .foregroundColor(summary.overallHealthy ? .green : .orange)
            }
        }
    }
}

/// Main performance dashboard view
private struct PerformanceDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PerformanceMonitor.self) private var performanceMonitor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    PerformanceOverviewCard()
                    PerformanceMetricsCard()
                    PerformanceAlertsCard()
                    PerformanceActionsCard()
                }
                .padding()
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func PerformanceOverviewCard() -> some View {
        let summary = performanceMonitor.getPerformanceSummary()

        return VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Performance Overview")
                .font(.daisyTitle)

            HStack {
                VStack(alignment: .leading) {
                    Text("Launch Time")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.2f", summary.launchTime))s")
                        .font(.daisyBody.weight(.semibold))
                        .foregroundColor(summary.launchTimeMeetsTarget ? .green : .red)
                    Text("Target: <2.0s")
                        .font(.daisyCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .center) {
                    Text("Memory Usage")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.1f", summary.currentMemoryUsage))MB")
                        .font(.daisyBody.weight(.semibold))
                        .foregroundColor(summary.memoryMeetsTarget ? .green : .red)
                    Text("Peak: \(String(format: "%.1f", summary.peakMemoryUsage))MB")
                        .font(.daisyCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("UI Response")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.0f", summary.averageUIResponseTime * 1000))ms")
                        .font(.daisyBody.weight(.semibold))
                        .foregroundColor(summary.uiResponseMeetsTarget ? .green : .red)
                    Text("Target: <100ms")
                        .font(.daisyCaption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: summary.overallHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(summary.overallHealthy ? .green : .orange)

                Text(summary.overallHealthy ? "All performance metrics are healthy" : "Some performance issues detected")
                    .font(.daisyBody)
                    .foregroundColor(summary.overallHealthy ? .green : .orange)
            }
        }
        .asCard()
    }

    private func PerformanceMetricsCard() -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Detailed Metrics")
                .font(.daisyTitle)

            VStack(alignment: .leading, spacing: Spacing.small) {
                MetricRow(
                    title: "Memory Snapshots",
                    value: "\(performanceMonitor.memoryUsageHistory.count)",
                    icon: "memorychip"
                )

                MetricRow(
                    title: "UI Response Events",
                    value: "\(performanceMonitor.uiResponseTimes.count)",
                    icon: "hand.tap"
                )

                MetricRow(
                    title: "Performance Alerts",
                    value: "\(performanceMonitor.performanceAlerts.count)",
                    icon: "bell"
                )

                let currentMemory = MemoryMonitor.getDetailedMemoryInfo()
                MetricRow(
                    title: "Memory Efficiency",
                    value: "\(MemoryMonitor.calculateEfficiencyScore(for: currentMemory))%",
                    icon: "gauge.high"
                )
            }
        }
        .asCard()
    }

    private func PerformanceAlertsCard() -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Recent Alerts")
                .font(.daisyTitle)

            if performanceMonitor.performanceAlerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("No performance alerts")
                        .font(.daisyBody)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ForEach(performanceMonitor.performanceAlerts.suffix(5).reversed(), id: \.id) { alert in
                    HStack {
                        Circle()
                            .fill(alert.severity.color)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.message)
                                .font(.daisyBody)
                                .lineLimit(2)
                            Text(alert.timestamp, format: .dateTime.hour().minute().second())
                                .font(.daisyCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .asCard()
    }

    private func PerformanceActionsCard() -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Performance Actions")
                .font(.daisyTitle)

            VStack(spacing: Spacing.small) {
                DaisyButton.secondary("Export Performance Data") {
                    let csvData = performanceMonitor.exportPerformanceData()
                    print("📊 Performance Data Export:\n\(csvData)")
                }

                DaisyButton.secondary("Clear Performance Alerts") {
                    performanceMonitor.clearAlerts()
                }

                DaisyButton.destructive("Reset All Performance Data") {
                    performanceMonitor.resetAllData()
                }
            }
        }
        .asCard()
    }
}

/// Helper view for metric rows
private struct MetricRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.daisyBody)

            Spacer()

            Text(value)
                .font(.daisyBody.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}