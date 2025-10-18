//
//  DueDateTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Interactive test UI for Due Date functionality validation
//

#if DEBUG
import SwiftUI
import SwiftData

struct DueDateTestView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.modelContext) private var modelContext

    @State private var testSuite: DueDateTestSuite?
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    controlsSection

                    if let suite = testSuite, !suite.testResults.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Due Date Tests")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if testSuite == nil {
                testSuite = DueDateTestSuite(
                    modelContext: modelContext,
                    taskManager: taskManager
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due Date Functionality Test Suite")
                .font(.title2.weight(.semibold))

            Text("Automated tests for task due date features including creation, detection, filtering, sorting, and edge cases.")
                .font(.body)
                .foregroundColor(.daisyTextSecondary)

            HStack(spacing: 16) {
                Label("20 Tests", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Label("No Simulator", systemImage: "laptopcomputer")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Label("~2 sec", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button(action: runTests) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                    }
                    Text(isRunning ? "Running Tests..." : "Run All Tests")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.daisyTask)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRunning)

            if let suite = testSuite, !suite.testResults.isEmpty {
                Button(action: clearResults) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Results")
                    }
                    .font(.subheadline)
                    .foregroundColor(.daisyError)
                }
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary Cards
            summaryCards

            // Test Results List
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Results")
                    .font(.headline)

                if let suite = testSuite {
                    ForEach(Array(suite.testResults.enumerated()), id: \.offset) { index, result in
                        testResultRow(result: result)
                    }
                }
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Summary Cards

    @ViewBuilder
    private var summaryCards: some View {
        if let suite = testSuite {
            let passed = suite.testResults.filter { $0.passed }.count
            let failed = suite.testResults.count - passed
            let totalDuration = suite.testResults.reduce(0.0) { $0 + $1.duration }

            HStack(spacing: 12) {
                summaryCard(
                    title: "Passed",
                    value: "\(passed)",
                    icon: "checkmark.circle.fill",
                    color: .daisySuccess
                )

                summaryCard(
                    title: "Failed",
                    value: "\(failed)",
                    icon: "xmark.circle.fill",
                    color: .daisyError
                )

                summaryCard(
                    title: "Duration",
                    value: String(format: "%.2fs", totalDuration),
                    icon: "clock.fill",
                    color: .daisyTask
                )
            }
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3.weight(.semibold))

            Text(title)
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Test Result Row

    private func testResultRow(result: DueDateTestSuite.TestResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .daisySuccess : .daisyError)

                Text("Test \(result.testNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.daisyTextSecondary)

                Text(result.name.replacingOccurrences(of: "Test \\d+: ", with: "", options: .regularExpression))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%.3fs", result.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.daisyTextSecondary)
            }

            Text(result.message)
                .font(.caption)
                .foregroundColor(result.passed ? .daisyTextSecondary : .daisyError)
                .lineLimit(2)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func runTests() {
        guard let suite = testSuite else { return }

        isRunning = true

        // Run tests synchronously
        suite.runAllTests()
        isRunning = false
    }

    private func clearResults() {
        testSuite?.testResults.removeAll()
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    return DueDateTestView()
        .modelContainer(container)
        .environment(taskManager)
}
#endif
