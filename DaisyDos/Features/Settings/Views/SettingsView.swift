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

                    #if DEBUG
                    Button(action: { showingTestViews = true }) {
                        Label("Developer Tools", systemImage: "hammer.circle")
                    }
                    #endif

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
            #if DEBUG
            .sheet(isPresented: $showingTestViews) {
                DeveloperToolsView()
            }
            #endif
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

#if DEBUG
// MARK: - Developer Tools View

private struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    Text("Developer Tools")
                        .font(.largeTitle.bold())
                        .padding(.bottom, Spacing.small)

                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("Interactive Test Views")
                            .font(.title2.bold())

                        Text("Interactive test views have been moved to the test target for better code organization and reduced bundle size. They are available when running tests.")
                            .font(.body)
                            .foregroundColor(.secondary)

                        CardView {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Text("Available Test Views")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 4) {
                                    TestViewItem(name: "ModelTestView", description: "Test SwiftData models and relationships")
                                    TestViewItem(name: "ManagerTestView", description: "Test @Observable manager patterns")
                                    TestViewItem(name: "ErrorHandlingTestView", description: "Test error transformation system")
                                    TestViewItem(name: "DesignSystemTestView", description: "Test design system components")
                                    TestViewItem(name: "ComponentTestView", description: "Test reusable UI components")
                                    TestViewItem(name: "AccessibilityTestView", description: "Test accessibility compliance")
                                    TestViewItem(name: "PerformanceTestView", description: "Test performance monitoring")
                                    TestViewItem(name: "DynamicTypeTestView", description: "Test Dynamic Type scaling")
                                }
                            }
                        }

                        Text("Location")
                            .font(.title2.bold())

                        Text("Test views are now located in:")
                            .font(.body)

                        Text("DaisyDosTests/InteractiveTestViews/")
                            .font(.system(.body, design: .monospaced))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
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

private struct TestViewItem: View {
    let name: String
    let description: String

    var body: some View {
        HStack {
            Image(systemName: "hammer.circle")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Accessibility Developer View - Simplified for moved test views

private struct AccessibilityDeveloperView: View {
    var body: some View {
        NavigationStack {
            AccessibilityDashboardView()
        }
    }
}

// MARK: - Accessibility Dashboard

private struct AccessibilityDashboardView: View {
    @StateObject private var auditor = AccessibilityAuditor()
    @State private var quickValidation: AccessibilityQuickValidation?
    @State private var isRunningQuickCheck = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {

                // MARK: - Quick Status

                AccessibilityQuickStatusCard(
                    validation: quickValidation,
                    isLoading: isRunningQuickCheck
                )

                // MARK: - Compliance Score

                if let score = auditor.complianceScore {
                    AccessibilityComplianceCard(score: score)
                }

                // MARK: - Quick Actions

                AccessibilityQuickActionsCard(
                    onRunQuickCheck: runQuickValidation,
                    onRunFullAudit: runFullAudit,
                    onGenerateReport: generateComplianceReport,
                    isRunningAudit: auditor.isRunningAudit,
                    isRunningQuickCheck: isRunningQuickCheck
                )

                // MARK: - Recent Audit Results

                if !auditor.auditHistory.isEmpty {
                    AccessibilityAuditHistoryCard(history: Array(auditor.auditHistory.suffix(3)))
                }

                // MARK: - Accessibility Guidelines

                AccessibilityGuidelinesCard()
            }
            .padding(Spacing.medium)
        }
        .onAppear {
            runQuickValidation()
        }
    }

    private func runQuickValidation() {
        isRunningQuickCheck = true
        // Simulate quick validation for now
        quickValidation = nil
        isRunningQuickCheck = false
    }

    private func runFullAudit() {
        // Simulate full audit for now
        print("Full audit would run here")
    }

    private func generateComplianceReport() {
        let report = auditor.generateComplianceReport()
        // In a real implementation, this would export or display the report
        print("Generated compliance report with \(report.recommendations.count) recommendations")
    }
}

// MARK: - Accessibility Dashboard Cards

private struct AccessibilityQuickStatusCard: View {
    let validation: AccessibilityQuickValidation?
    let isLoading: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: "accessibility.fill")
                        .font(.title2)
                        .foregroundStyle(Colors.Secondary.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Status")
                            .font(.headline)

                        if let validation = validation {
                            Text(validation.overallStatus.description)
                                .font(.subheadline)
                                .foregroundStyle(validation.overallStatus.color)
                        } else if isLoading {
                            Text("Checking accessibility status...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Status unknown")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                if let validation = validation {
                    Divider()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                        StatusIndicator(
                            title: "Dynamic Type",
                            passed: validation.dynamicTypeSupport.passed,
                            score: validation.dynamicTypeSupport.score
                        )

                        StatusIndicator(
                            title: "Touch Targets",
                            passed: validation.touchTargetCompliance.passed,
                            score: validation.touchTargetCompliance.score
                        )

                        StatusIndicator(
                            title: "Contrast",
                            passed: validation.colorContrastCompliance.passed,
                            score: validation.colorContrastCompliance.score
                        )
                    }
                }
            }
        }
    }
}

private struct StatusIndicator: View {
    let title: String
    let passed: Bool
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(passed ? Colors.Accent.success : Colors.Accent.warning)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}

private struct AccessibilityComplianceCard: View {
    let score: AccessibilityComplianceScore

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Compliance Score")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(score.overallScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(scoreColor)

                        Text("Overall Score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        if score.criticalIssues > 0 {
                            Label("\(score.criticalIssues) Critical", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Colors.Accent.error)
                        }

                        if score.warnings > 0 {
                            Label("\(score.warnings) Warnings", systemImage: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(Colors.Accent.warning)
                        }
                    }
                }

                if score.lastAuditDate != Date.distantPast {
                    Text("Last audit: \(score.lastAuditDate, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var scoreColor: Color {
        switch score.overallScore {
        case 90...100: return Colors.Accent.success
        case 70...89: return Colors.Accent.warning
        default: return Colors.Accent.error
        }
    }
}

private struct AccessibilityQuickActionsCard: View {
    let onRunQuickCheck: () -> Void
    let onRunFullAudit: () -> Void
    let onGenerateReport: () -> Void
    let isRunningAudit: Bool
    let isRunningQuickCheck: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Quick Actions")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.small) {
                    DaisyButton(
                        title: "Quick Check",
                        style: .secondary,
                        size: .small,
                        icon: "checkmark.circle",
                        isLoading: isRunningQuickCheck,
                        action: onRunQuickCheck
                    )

                    DaisyButton(
                        title: "Full Audit",
                        style: .primary,
                        size: .small,
                        icon: "magnifyingglass.circle",
                        isLoading: isRunningAudit,
                        action: onRunFullAudit
                    )

                    DaisyButton(
                        title: "Export Report",
                        style: .tertiary,
                        size: .small,
                        icon: "square.and.arrow.up",
                        action: onGenerateReport
                    )

                    DaisyButton(
                        title: "View Guidelines",
                        style: .tertiary,
                        size: .small,
                        icon: "book",
                        action: {}
                    )
                }
            }
        }
    }
}

private struct AccessibilityAuditHistoryCard: View {
    let history: [AccessibilityAuditSession]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Recent Audits")
                    .font(.headline)

                ForEach(history.indices, id: \.self) { index in
                    let session = history[index]

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.timestamp, format: .dateTime.month().day().hour().minute())
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if let score = session.overallScore {
                                Text("Score: \(score.value) (\(score.grade.rawValue))")
                                    .font(.caption)
                                    .foregroundStyle(score.grade.color)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(session.results.count) rules")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            let issues = session.results.reduce(0) { $0 + $1.issues.count }
                            if issues > 0 {
                                Text("\(issues) issues")
                                    .font(.caption)
                                    .foregroundStyle(Colors.Accent.error)
                            }
                        }
                    }
                    .padding(.vertical, 2)

                    if index < history.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct AccessibilityGuidelinesCard: View {
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Accessibility Guidelines")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    GuidelineItem(
                        icon: "eye",
                        text: "Test with VoiceOver enabled regularly"
                    )

                    GuidelineItem(
                        icon: "textformat.size",
                        text: "Support all Dynamic Type sizes (XS to AX5)"
                    )

                    GuidelineItem(
                        icon: "hand.tap",
                        text: "Ensure minimum 44×44pt touch targets"
                    )

                    GuidelineItem(
                        icon: "circle.lefthalf.filled",
                        text: "Maintain WCAG AA contrast ratios"
                    )

                    GuidelineItem(
                        icon: "keyboard",
                        text: "Support keyboard and Switch Control navigation"
                    )
                }
            }
        }
    }
}

private struct GuidelineItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Colors.Secondary.blue)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
#endif

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
                    .fill(summary.launchTimeMeetsTarget ? Color(.systemGreen) : Color(.systemRed))
                    .frame(width: 8, height: 8)

                // Memory indicator
                Circle()
                    .fill(summary.memoryMeetsTarget ? Color(.systemGreen) : Color(.systemRed))
                    .frame(width: 8, height: 8)

                // UI response indicator
                Circle()
                    .fill(summary.uiResponseMeetsTarget ? Color(.systemGreen) : Color(.systemRed))
                    .frame(width: 8, height: 8)

                Text(summary.overallHealthy ? "Good" : "Issues")
                    .font(.caption)
                    .foregroundColor(summary.overallHealthy ? Color(.systemGreen) : Color(.systemOrange))
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
                        .foregroundColor(summary.launchTimeMeetsTarget ? Color(.systemGreen) : .red)
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
                        .foregroundColor(summary.memoryMeetsTarget ? Color(.systemGreen) : .red)
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
                        .foregroundColor(summary.uiResponseMeetsTarget ? Color(.systemGreen) : .red)
                    Text("Target: <100ms")
                        .font(.daisyCaption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: summary.overallHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(summary.overallHealthy ? Color(.systemGreen) : Color(.systemOrange))

                Text(summary.overallHealthy ? "All performance metrics are healthy" : "Some performance issues detected")
                    .font(.daisyBody)
                    .foregroundColor(summary.overallHealthy ? Color(.systemGreen) : Color(.systemOrange))
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
                        .foregroundColor(Color(.systemGreen))
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