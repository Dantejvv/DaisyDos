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
    @Environment(LogbookManager.self) private var logbookManager
    @Environment(HabitNotificationManager.self) private var notificationManager: HabitNotificationManager?
    @State private var showingAbout = false
    @State private var showingTestViews = false
    @State private var showingPerformance = false
    @State private var showingNotificationSettings = false

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
                        .foregroundColor(.daisyTextSecondary)
                }

                Section("Notifications") {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Label("Habit Reminders", systemImage: "bell")
                            Spacer()
                            if let notificationManager = notificationManager {
                                Text(notificationManager.isPermissionGranted ? "Enabled" : "Disabled")
                                    .foregroundColor(.daisyTextSecondary)
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                    .foregroundColor(.daisyText)
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
                            .foregroundColor(.daisyTextSecondary)
                    }
                    HStack {
                        Label("Habits", systemImage: "repeat.circle")
                        Spacer()
                        Text("\(habitManager.habitCount)")
                            .foregroundColor(.daisyTextSecondary)
                    }
                    HStack {
                        Label("Tags", systemImage: "tag")
                        Spacer()
                        Text("\(tagManager.tagCount)")
                            .foregroundColor(.daisyTextSecondary)
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
                            .foregroundColor(.daisyTextSecondary)
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
            .sheet(isPresented: $showingNotificationSettings) {
                if notificationManager != nil {
                    HabitNotificationSettingsView()
                }
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
                        .foregroundColor(.daisyCTA)

                    Text("DaisyDos")
                        .font(.largeTitle.bold())

                    Text("A unified productivity app for tasks and habits")
                        .font(.body)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)

                    Text("DaisyDos combines task management and habit tracking in a single, privacy-first application. Built with SwiftUI and SwiftData, it focuses on simplicity, accessibility, and keeping your data private.")
                        .font(.body)
                        .foregroundColor(.daisyTextSecondary)
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
    @Environment(LogbookManager.self) private var logbookManager
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingHousekeepingAlert = false
    @State private var housekeepingResult = ""
    @State private var testDataResult = ""
    @State private var testSuite: LogbookTestSuite?
    @State private var showingTestResults = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    Text("Developer Tools")
                        .font(.largeTitle.bold())
                        .padding(.bottom, Spacing.small)

                    // MARK: - Feature Testing
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("Feature Testing")
                            .font(.title2.bold())

                        Text("Run automated test suites to validate core functionality.")
                            .font(.body)
                            .foregroundColor(.daisyTextSecondary)

                        // Due Date Testing
                        NavigationLink {
                            DueDateTestView()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Due Date Test Suite", systemImage: "calendar.badge.clock")
                                        .font(.headline)
                                        .foregroundColor(.daisyTask)

                                    Text("20 automated tests for due date functionality")
                                        .font(.caption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                            .padding()
                            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Logbook Testing
                        Text("Logbook Testing")
                            .font(.title3.bold())
                            .padding(.top, Spacing.medium)

                        Text("Test the automatic archival system without waiting 90 days.")
                            .font(.body)
                            .foregroundColor(.daisyTextSecondary)

                        CardView {
                            VStack(spacing: Spacing.medium) {
                                DaisyButton(
                                    title: "Run Automated Test Suite",
                                    style: .primary,
                                    icon: "play.circle.fill",
                                    isLoading: testSuite?.isRunning ?? false,
                                    action: runTestSuite
                                )

                                Text("Runs 12 automated tests covering all housekeeping scenarios. Check Xcode console for detailed output.")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)

                                Divider()

                                DaisyButton(
                                    title: "Create Test Tasks",
                                    style: .secondary,
                                    icon: "plus.circle",
                                    action: createTestTasks
                                )

                                Text("Creates completed tasks with dates: 30 days ago, 95 days ago (for archival), and 370 days ago (for deletion).")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)

                                Divider()

                                DaisyButton(
                                    title: "Run Housekeeping Now",
                                    style: .tertiary,
                                    icon: "arrow.clockwise",
                                    action: runHousekeeping
                                )

                                Text("Archives completed tasks older than 90 days into TaskLogEntry snapshots and deletes entries older than 365 days.")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        if !testDataResult.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: Spacing.small) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.daisySuccess)
                                        Text("Test Data Created")
                                            .font(.headline)
                                    }

                                    Text(testDataResult)
                                        .font(.caption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                        }

                        if !housekeepingResult.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: Spacing.small) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.daisySuccess)
                                        Text("Housekeeping Complete")
                                            .font(.headline)
                                    }

                                    Text(housekeepingResult)
                                        .font(.caption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                        }

                        if let suite = testSuite, !suite.testResults.isEmpty {
                            TestResultsCard(results: suite.testResults)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("Interactive Test Views")
                            .font(.title2.bold())

                        Text("Interactive test views have been moved to the test target for better code organization and reduced bundle size. They are available when running tests.")
                            .font(.body)
                            .foregroundColor(.daisyTextSecondary)

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
                            .background(Colors.Primary.backgroundTertiary)
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

    private func createTestTasks() {
        // Create tasks with old completion dates for testing
        let calendar = Calendar.current
        let now = Date()

        // Task 1: Recent (30 days ago) - should stay as Task
        let task1 = Task(
            title: "Recent Task (30 days old)",
            taskDescription: "This task should remain as a full Task object",
            priority: .medium,
            dueDate: nil
        )
        task1.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -30, to: now) {
            task1.completedDate = date
            task1.createdDate = calendar.date(byAdding: .day, value: -35, to: now) ?? date
        }
        modelContext.insert(task1)

        // Task 2: Medium age (60 days ago) - should stay visible and then be archived
        let task2 = Task(
            title: "Medium Task (60 days old)",
            taskDescription: "This task is visible but will be archived to TaskLogEntry after housekeeping",
            priority: .high,
            dueDate: nil
        )
        task2.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -60, to: now) {
            task2.completedDate = date
            task2.createdDate = calendar.date(byAdding: .day, value: -65, to: now) ?? date
        }
        modelContext.insert(task2)

        // Task 3: At the edge (85 days ago) - visible in 90-day filter
        let task3 = Task(
            title: "Edge Task (85 days old)",
            taskDescription: "At the edge of the 90-day window",
            priority: .medium,
            dueDate: nil
        )
        task3.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -85, to: now) {
            task3.completedDate = date
            task3.createdDate = calendar.date(byAdding: .day, value: -90, to: now) ?? date
        }
        modelContext.insert(task3)

        // IMPORTANT: These next tasks are hidden by the 90-day filter until housekeeping runs!
        // After housekeeping, they'll be archived as TaskLogEntry and become visible in longer period filters

        // Task 4: Should be archived (120 days ago)
        let task4 = Task(
            title: "Old Task (120 days old)",
            taskDescription: "Hidden until archived - will show after housekeeping",
            priority: .high,
            dueDate: nil
        )
        task4.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -120, to: now) {
            task4.completedDate = date
            task4.createdDate = calendar.date(byAdding: .day, value: -125, to: now) ?? date
        }
        modelContext.insert(task4)

        // Task 5: Should be deleted (370 days ago)
        let task5 = Task(
            title: "Ancient Task (370 days old)",
            taskDescription: "This will be deleted entirely after housekeeping",
            priority: .low,
            dueDate: nil
        )
        task5.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -370, to: now) {
            task5.completedDate = date
            task5.createdDate = calendar.date(byAdding: .day, value: -375, to: now) ?? date
            #if DEBUG
            print("📝 Created Ancient Task with completedDate: \(date)")
            #endif
        }
        modelContext.insert(task5)

        // Task 6: Parent task with subtask (100 days old) - test subtask indicators
        let parentTask = Task(
            title: "Parent Task (100 days old)",
            taskDescription: "Parent task with subtask - will be archived",
            priority: .medium,
            dueDate: nil
        )
        parentTask.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -100, to: now) {
            parentTask.completedDate = date
            parentTask.createdDate = calendar.date(byAdding: .day, value: -105, to: now) ?? date
        }
        modelContext.insert(parentTask)

        // Subtask (also 100 days old)
        let subtask = parentTask.createSubtask(title: "Subtask of Parent (100 days old)")
        subtask.setCompleted(true)
        if let date = calendar.date(byAdding: .day, value: -100, to: now) {
            subtask.completedDate = date
        }
        modelContext.insert(subtask)

        // Save all
        try? modelContext.save()

        testDataResult = """
        Created 7 test tasks:

        BEFORE Housekeeping (90-day filter):
        • 3 visible tasks (30, 60, 85 days old)
        • 4 hidden (too old for filter)

        AFTER Housekeeping:
        • 3 remain as Task objects
        • 3 archived to TaskLogEntry (120, 100 days)
        • 1 deleted (370 days)

        Switch to "This Year" filter to see all after housekeeping!
        """
    }

    private func runHousekeeping() {
        let result = logbookManager.performHousekeeping()
        switch result {
        case .success(let stats):
            housekeepingResult = """
            Housekeeping completed!
            • \(stats.tasksArchived) tasks archived to log entries
            • \(stats.tasksDeleted) old tasks deleted (365+ days)
            • \(stats.logsDeleted) old log entries deleted

            Check the Logbook tab to see the results.
            """
        case .failure(let error):
            housekeepingResult = "Housekeeping failed: \(error.userMessage)"
        }
    }

    private func runTestSuite() {
        testSuite = LogbookTestSuite(modelContext: modelContext, logbookManager: logbookManager)
        testSuite?.runAllTests()
    }
}

// MARK: - Test Results Card

private struct TestResultsCard: View {
    let results: [LogbookTestSuite.TestResult]

    private var passed: Int {
        results.filter { $0.passed }.count
    }

    private var failed: Int {
        results.count - passed
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                headerView
                Divider()
                resultsListView
                footerView
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: failed == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(failed == 0 ? .daisySuccess : .daisyError)
            Text("Test Results")
                .font(.headline)
            Spacer()
            statsView
        }
    }

    private var statsView: some View {
        HStack(spacing: Spacing.small) {
            Label("\(passed)", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundColor(.daisySuccess)
            Label("\(failed)", systemImage: "xmark.circle")
                .font(.caption)
                .foregroundColor(.daisyError)
        }
    }

    private var resultsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    TestResultRow(result: result)
                    if index < results.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(maxHeight: 300)
    }

    private var footerView: some View {
        Text("Check Xcode console for detailed test output")
            .font(.caption2)
            .foregroundColor(.daisyTextSecondary)
    }
}

private struct TestResultRow: View {
    let result: LogbookTestSuite.TestResult

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .daisySuccess : .daisyError)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text("Test \(result.testNumber)")
                    .font(.caption)
                    .fontWeight(.bold)

                Text(result.message)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)

                Text("\(String(format: "%.3f", result.duration))s")
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
                    .opacity(0.7)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

private struct TestViewItem: View {
    let name: String
    let description: String

    var body: some View {
        HStack {
            Image(systemName: "hammer.circle")
                .font(.caption)
                .foregroundStyle(Color.daisyCTA)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(Color.daisyTextSecondary)
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
        #if DEBUG
        print("Full audit would run here")
        #endif
    }

    private func generateComplianceReport() {
        let report = auditor.generateComplianceReport()
        // In a real implementation, this would export or display the report
        #if DEBUG
        print("Generated compliance report with \(report.recommendations.count) recommendations")
        #endif
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
                        .foregroundStyle(Color.daisyCTA)

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
                                .foregroundStyle(Color.daisyTextSecondary)
                        } else {
                            Text("Status unknown")
                                .font(.subheadline)
                                .foregroundStyle(Color.daisyTextSecondary)
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
                            .foregroundStyle(Color.daisyTextSecondary)
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
                        .foregroundStyle(Color.daisyTextSecondary)
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

                ForEach(Array(history.enumerated()), id: \.offset) { index, session in

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
                                .foregroundStyle(Color.daisyTextSecondary)

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
                .foregroundStyle(Color.daisyCTA)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundStyle(Color.daisyTextSecondary)
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
                    .fill(summary.launchTimeMeetsTarget ? Color.daisySuccess : Color.daisyError)
                    .frame(width: 8, height: 8)

                // Memory indicator
                Circle()
                    .fill(summary.memoryMeetsTarget ? Color.daisySuccess : Color.daisyError)
                    .frame(width: 8, height: 8)

                // UI response indicator
                Circle()
                    .fill(summary.uiResponseMeetsTarget ? Color.daisySuccess : Color.daisyError)
                    .frame(width: 8, height: 8)

                Text(summary.overallHealthy ? "Good" : "Issues")
                    .font(.caption)
                    .foregroundColor(summary.overallHealthy ? .daisySuccess : .daisyWarning)
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
                        .foregroundColor(summary.launchTimeMeetsTarget ? .daisySuccess : .red)
                    Text("Target: <2.0s")
                        .font(.daisyCaption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                VStack(alignment: .center) {
                    Text("Memory Usage")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.1f", summary.currentMemoryUsage))MB")
                        .font(.daisyBody.weight(.semibold))
                        .foregroundColor(summary.memoryMeetsTarget ? .daisySuccess : .red)
                    Text("Peak: \(String(format: "%.1f", summary.peakMemoryUsage))MB")
                        .font(.daisyCaption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("UI Response")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.0f", summary.averageUIResponseTime * 1000))ms")
                        .font(.daisyBody.weight(.semibold))
                        .foregroundColor(summary.uiResponseMeetsTarget ? .daisySuccess : .red)
                    Text("Target: <100ms")
                        .font(.daisyCaption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            HStack {
                Image(systemName: summary.overallHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(summary.overallHealthy ? .daisySuccess : .daisyWarning)

                Text(summary.overallHealthy ? "All performance metrics are healthy" : "Some performance issues detected")
                    .font(.daisyBody)
                    .foregroundColor(summary.overallHealthy ? .daisySuccess : .daisyWarning)
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
                        .foregroundColor(.daisySuccess)
                    Text("No performance alerts")
                        .font(.daisyBody)
                        .foregroundColor(.daisyTextSecondary)
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
                                .foregroundColor(.daisyTextSecondary)
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
                    #if DEBUG
                    print("📊 Performance Data Export:\n\(csvData)")
                    #endif
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
                .foregroundColor(.daisyCTA)
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