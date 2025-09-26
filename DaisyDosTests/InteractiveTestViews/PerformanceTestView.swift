//
//  PerformanceTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

/// Comprehensive performance testing interface for validating app performance
/// Includes stress tests, memory monitoring, and response time validation
/// Available in DEBUG builds for developers and QA testing
struct PerformanceTestView: View {
    @Environment(PerformanceMonitor.self) private var performanceMonitor
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager

    @State private var isRunningTests = false
    @State private var testResults: [TestResult] = []
    @State private var currentTest = ""
    @State private var testProgress: Double = 0.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {

                    // MARK: - Performance Summary

                    PerformanceSummaryCard()

                    // MARK: - Test Controls

                    TestControlsSection(
                        isRunningTests: $isRunningTests,
                        currentTest: $currentTest,
                        testProgress: $testProgress,
                        onRunTests: runPerformanceTests
                    )

                    // MARK: - Test Results

                    if !testResults.isEmpty {
                        TestResultsSection(results: testResults)
                    }

                    // MARK: - Manual Tests

                    ManualTestsSection()

                    // MARK: - Performance Data

                    PerformanceDataSection()
                }
                .padding()
            }
            .navigationTitle("Performance Testing")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Test Execution

    private func runPerformanceTests() {
        guard !isRunningTests else { return }

        isRunningTests = true
        testResults = []
        testProgress = 0.0

        _Concurrency.Task {
            await runAllPerformanceTests()
            await MainActor.run {
                isRunningTests = false
                testProgress = 1.0
                currentTest = "Tests completed"
            }
        }
    }

    private func runAllPerformanceTests() async {
        let tests: [(String, () async -> TestResult)] = [
            ("Launch Time Validation", testLaunchTime),
            ("Memory Usage Stress Test", testMemoryUsage),
            ("Task Manager Performance", testTaskManagerPerformance),
            ("UI Response Time Test", testUIResponseTimes),
            ("Large Dataset Performance", testLargeDatasetPerformance),
            ("Memory Leak Detection", testMemoryLeaks)
        ]

        for (index, (testName, testFunction)) in tests.enumerated() {
            await MainActor.run {
                currentTest = testName
                testProgress = Double(index) / Double(tests.count)
            }

            let result = await testFunction()
            await MainActor.run {
                testResults.append(result)
            }

            // Brief pause between tests
            try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }

    // MARK: - Individual Tests

    private func testLaunchTime() async -> TestResult {
        let summary = performanceMonitor.getPerformanceSummary()
        let passed = summary.launchTimeMeetsTarget && summary.launchTime > 0

        return TestResult(
            testName: "Launch Time Validation",
            passed: passed,
            duration: summary.launchTime,
            details: "Launch time: \(String(format: "%.2f", summary.launchTime))s (target: <2.0s)",
            recommendation: passed ? "Launch time meets target" : "Consider optimizing app startup sequence"
        )
    }

    private func testMemoryUsage() async -> TestResult {
        let startMemory = MemoryMonitor.getDetailedMemoryInfo()

        // Simulate memory-intensive operations
        var tempData: [[String]] = []
        for i in 0..<1000 {
            tempData.append(Array(repeating: "Test data \(i)", count: 100))
        }

        let peakMemory = MemoryMonitor.getDetailedMemoryInfo()
        tempData.removeAll() // Clean up

        let endMemory = MemoryMonitor.getDetailedMemoryInfo()
        let memoryDelta = peakMemory.residentSizeMB - startMemory.residentSizeMB
        let memoryRecovered = peakMemory.residentSizeMB - endMemory.residentSizeMB

        let passed = memoryDelta < 50.0 && memoryRecovered > memoryDelta * 0.8

        return TestResult(
            testName: "Memory Usage Stress Test",
            passed: passed,
            duration: 0, // Not time-based
            details: "Memory delta: +\(String(format: "%.1f", memoryDelta))MB, Recovered: \(String(format: "%.1f", memoryRecovered))MB",
            recommendation: passed ? "Memory management is healthy" : "Consider reviewing memory allocation patterns"
        )
    }

    private func testTaskManagerPerformance() async -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create test tasks
        var createdTasks: [Task] = []
        for i in 0..<100 {
            if let task = taskManager.createTaskSafely(title: "Performance Test Task \(i)") {
                createdTasks.append(task)
            }
        }

        // Perform operations
        let searchResults = taskManager.searchTasksSafely(query: "Performance")
        let allTasks = taskManager.allTasks
        let _ = taskManager.completedTaskCount

        // Clean up
        for task in createdTasks {
            let _ = taskManager.deleteTaskSafely(task)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        let passed = duration < 1.0 && searchResults.count == 100 && allTasks.count >= 100

        return TestResult(
            testName: "Task Manager Performance",
            passed: passed,
            duration: duration,
            details: "Created 100 tasks, searched, retrieved all (\(allTasks.count)), cleaned up",
            recommendation: passed ? "Task manager performance is good" : "Consider optimizing task operations"
        )
    }

    private func testUIResponseTimes() async -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Simulate UI operations
        await MainActor.run {
            performanceMonitor.trackUIResponse(eventType: "Test Button", startTime: startTime)
            performanceMonitor.trackUIResponse(eventType: "Test Navigation", startTime: startTime)
            performanceMonitor.trackUIResponse(eventType: "Test List Operation", startTime: startTime)
        }

        let summary = performanceMonitor.getPerformanceSummary()
        let passed = summary.uiResponseMeetsTarget

        return TestResult(
            testName: "UI Response Time Test",
            passed: passed,
            duration: summary.averageUIResponseTime,
            details: "Average UI response: \(String(format: "%.0f", summary.averageUIResponseTime * 1000))ms (target: <100ms)",
            recommendation: passed ? "UI responsiveness is good" : "Consider optimizing UI operations"
        )
    }

    private func testLargeDatasetPerformance() async -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create large dataset
        var largeTasks: [Task] = []
        for i in 0..<500 {
            if let task = taskManager.createTaskSafely(title: "Large Dataset Task \(i)") {
                largeTasks.append(task)
            }
        }

        // Test operations on large dataset
        let searchTime = await measureSearchTime()
        let filterTime = await measureFilterTime()

        // Clean up
        for task in largeTasks {
            let _ = taskManager.deleteTaskSafely(task)
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let passed = searchTime < 0.5 && filterTime < 0.5 && totalTime < 5.0

        return TestResult(
            testName: "Large Dataset Performance",
            passed: passed,
            duration: totalTime,
            details: "500 tasks: Search \(String(format: "%.2f", searchTime))s, Filter \(String(format: "%.2f", filterTime))s",
            recommendation: passed ? "Large dataset handling is efficient" : "Consider implementing pagination or virtual scrolling"
        )
    }

    private func measureSearchTime() async -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = taskManager.searchTasksSafely(query: "Large")
        return CFAbsoluteTimeGetCurrent() - startTime
    }

    private func measureFilterTime() async -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = taskManager.pendingTasks
        return CFAbsoluteTimeGetCurrent() - startTime
    }

    private func testMemoryLeaks() async -> TestResult {
        let history = performanceMonitor.memoryUsageHistory
        let warnings = MemoryMonitor.detectMemoryLeaks(in: history)

        let passed = warnings.filter { $0.severity == .high }.isEmpty

        return TestResult(
            testName: "Memory Leak Detection",
            passed: passed,
            duration: 0,
            details: "\(warnings.count) potential issues found (\(warnings.filter { $0.severity == .high }.count) high severity)",
            recommendation: passed ? "No critical memory leaks detected" : "Review memory usage patterns for potential leaks"
        )
    }
}

// MARK: - Supporting Views

private struct PerformanceSummaryCard: View {
    @Environment(PerformanceMonitor.self) private var performanceMonitor

    var body: some View {
        let summary = performanceMonitor.getPerformanceSummary()

        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Performance Summary")
                .font(.daisyTitle)

            HStack {
                VStack(alignment: .leading) {
                    Text("Launch Time")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.2f", summary.launchTime))s")
                        .font(.daisyBody)
                        .foregroundColor(summary.launchTimeMeetsTarget ? .green : .red)
                }

                Spacer()

                VStack(alignment: .center) {
                    Text("Memory")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.1f", summary.currentMemoryUsage))MB")
                        .font(.daisyBody)
                        .foregroundColor(summary.memoryMeetsTarget ? .green : .red)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("UI Response")
                        .font(.daisySubtitle)
                    Text("\(String(format: "%.0f", summary.averageUIResponseTime * 1000))ms")
                        .font(.daisyBody)
                        .foregroundColor(summary.uiResponseMeetsTarget ? .green : .red)
                }
            }

            HStack {
                Image(systemName: summary.overallHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(summary.overallHealthy ? .green : .orange)

                Text(summary.overallHealthy ? "All systems healthy" : "Some performance issues detected")
                    .font(.daisyBody)
                    .foregroundColor(summary.overallHealthy ? .green : .orange)

                Spacer()
            }
        }
        .asCard()
    }
}

private struct TestControlsSection: View {
    @Binding var isRunningTests: Bool
    @Binding var currentTest: String
    @Binding var testProgress: Double
    let onRunTests: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Performance Tests")
                .font(.daisyTitle)

            if isRunningTests {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(currentTest)
                            .font(.daisyBody)
                    }

                    ProgressView(value: testProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            } else {
                DaisyButton.primary("Run Performance Tests") {
                    onRunTests()
                }
            }
        }
        .asCard()
    }
}

private struct TestResultsSection: View {
    let results: [TestResult]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Test Results")
                .font(.daisyTitle)

            ForEach(results) { result in
                TestResultRow(result: result)
            }

            // Summary
            let passedCount = results.filter { $0.passed }.count
            let totalCount = results.count

            HStack {
                Text("Summary: \(passedCount)/\(totalCount) tests passed")
                    .font(.daisyBody.weight(.semibold))
                    .foregroundColor(passedCount == totalCount ? .green : .orange)

                Spacer()

                Image(systemName: passedCount == totalCount ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(passedCount == totalCount ? .green : .orange)
            }
        }
        .asCard()
    }
}

private struct TestResultRow: View {
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
            HStack {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .green : .red)

                Text(result.testName)
                    .font(.daisyBody.weight(.medium))

                Spacer()

                if result.duration > 0 {
                    Text("\(String(format: "%.2f", result.duration))s")
                        .font(.daisyCaption)
                        .foregroundColor(.secondary)
                }
            }

            Text(result.details)
                .font(.daisyCaption)
                .foregroundColor(.secondary)

            if !result.recommendation.isEmpty {
                Text("💡 \(result.recommendation)")
                    .font(.daisyCaption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}

private struct ManualTestsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Manual Performance Tests")
                .font(.daisyTitle)

            Text("Use these buttons to manually test specific performance scenarios:")
                .font(.daisyBody)
                .foregroundColor(.secondary)

            VStack(spacing: Spacing.small) {
                DaisyButton.secondary("Test Button Response Time") {
                    // Button tap is automatically tracked
                }

                DaisyButton.secondary("Test Memory Usage") {
                    let _ = MemoryMonitor.getDetailedMemoryInfo()
                }

                DaisyButton.secondary("Trigger Memory Snapshot") {
                    let _ = PerformanceMonitor.shared.getCurrentMemoryUsage()
                }
            }
        }
        .asCard()
    }
}

private struct PerformanceDataSection: View {
    @Environment(PerformanceMonitor.self) private var performanceMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Performance Data")
                .font(.daisyTitle)

            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Memory History: \(performanceMonitor.memoryUsageHistory.count) snapshots")
                    .font(.daisyBody)

                Text("UI Events: \(performanceMonitor.uiResponseTimes.count) recorded")
                    .font(.daisyBody)

                Text("Performance Alerts: \(performanceMonitor.performanceAlerts.count)")
                    .font(.daisyBody)
            }

            HStack {
                DaisyButton.tertiary("Export Data") {
                    let csvData = performanceMonitor.exportPerformanceData()
                    print("Performance Data CSV:\n\(csvData)")
                }

                Spacer()

                DaisyButton.destructive("Clear Data") {
                    performanceMonitor.resetAllData()
                }
            }
        }
        .asCard()
    }
}

// MARK: - Data Structures

struct TestResult: Identifiable {
    let id = UUID()
    let testName: String
    let passed: Bool
    let duration: TimeInterval
    let details: String
    let recommendation: String
}

// MARK: - Preview

#if DEBUG
#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return PerformanceTestView()
        .modelContainer(container)
        .environment(PerformanceMonitor.shared)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}
#endif