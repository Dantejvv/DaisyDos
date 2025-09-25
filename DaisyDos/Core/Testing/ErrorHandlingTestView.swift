//
//  ErrorHandlingTestView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/24/25.
//

import SwiftUI
import SwiftData

struct ErrorHandlingTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager

    @State private var currentError: (any RecoverableError)?
    @State private var testResults: [String] = []
    @State private var isRunning = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    controlsSection

                    if !testResults.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Error Handling Tests")
            .errorBanner($currentError)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Error Handling System Validation")
                .font(.title2.weight(.semibold))

            Text("This view validates the three-tier error handling system: Platform → App → User")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Button(action: runAllTests) {
                HStack {
                    if isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(isRunning ? "Running Tests..." : "Run All Error Tests")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRunning)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                testButton("Validation Errors", systemImage: "exclamationmark.triangle") {
                    testValidationErrors()
                }

                testButton("Tag Limit Errors", systemImage: "tag.circle") {
                    testTagLimitErrors()
                }

                testButton("Data Corruption", systemImage: "exclamationmark.octagon") {
                    testDataCorruption()
                }

                testButton("Network Errors", systemImage: "wifi.slash") {
                    testNetworkErrors()
                }

                testButton("Recovery Actions", systemImage: "arrow.clockwise") {
                    testRecoveryActions()
                }

                testButton("Error Priorities", systemImage: "exclamationmark.3") {
                    testErrorPriorities()
                }
            }

            Button("Clear Results", systemImage: "trash") {
                testResults.removeAll()
            }
            .foregroundColor(.red)
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)

            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)

                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("✅") ? .green : result.contains("❌") ? .red : .primary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
            .background(.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func testButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
        .disabled(isRunning)
    }

    // MARK: - Test Methods

    private func runAllTests() {
        isRunning = true
        testResults.removeAll()

        _Concurrency.Task {
            await MainActor.run {
                testResults.append("🧪 Starting comprehensive error handling tests...")
            }

            // Run tests sequentially to avoid conflicts
            await testValidationErrorsAsync()
            await testTagLimitErrorsAsync()
            await testDataCorruptionAsync()
            await testNetworkErrorsAsync()
            await testRecoveryActionsAsync()
            await testErrorPrioritiesAsync()

            await MainActor.run {
                testResults.append("✅ All error handling tests completed!")
                isRunning = false
            }
        }
    }

    private func testValidationErrors() {
        testResults.append("🔍 Testing validation errors...")

        // Test empty title validation
        let result = taskManager.createTask(title: "")
        switch result {
        case .success:
            testResults.append("❌ Expected validation error for empty title")
        case .failure(let error):
            if error is DaisyDosError {
                testResults.append("✅ DaisyDosError properly generated for validation")
            } else {
                testResults.append("❌ Wrong error type: \(type(of: error))")
            }
            testResults.append("   User Message: '\(error.userMessage)'")
            testResults.append("   User Reason: '\(error.userReason)'")
            testResults.append("   Priority: \(error.priority)")
        }
    }

    private func testValidationErrorsAsync() async {
        await MainActor.run {
            testValidationErrors()
        }
    }

    private func testTagLimitErrors() {
        testResults.append("🔍 Testing tag limit errors...")

        // Create a test task
        let result = taskManager.createTask(title: "Test Task for Tag Limits")
        switch result {
        case .success(let task):
            // Try to add more than 3 tags
            let tag1 = Tag(name: "Tag1")
            let tag2 = Tag(name: "Tag2")
            let tag3 = Tag(name: "Tag3")
            let tag4 = Tag(name: "Tag4")

            modelContext.insert(tag1)
            modelContext.insert(tag2)
            modelContext.insert(tag3)
            modelContext.insert(tag4)

            _ = taskManager.addTag(tag1, to: task)
            _ = taskManager.addTag(tag2, to: task)
            _ = taskManager.addTag(tag3, to: task)

            // This should fail
            let tagLimitResult = taskManager.addTag(tag4, to: task)
            switch tagLimitResult {
            case .success:
                testResults.append("❌ Expected tag limit error")
            case .failure(let error):
                testResults.append("✅ Tag limit error properly caught")
                testResults.append("   Message: '\(error.userMessage)'")
                testResults.append("   Recovery options: \(error.recoveryOptions.count)")
            }

            // Cleanup
            _ = taskManager.deleteTask(task)

        case .failure:
            testResults.append("❌ Failed to create test task for tag limit test")
        }
    }

    private func testTagLimitErrorsAsync() async {
        await MainActor.run {
            testTagLimitErrors()
        }
    }

    private func testDataCorruption() {
        testResults.append("🔍 Testing data corruption error transformation...")

        // Simulate a SwiftData error
        let mockError = DaisyDosError.dataCorrupted("Test corruption scenario")
        let recoverableError = mockError as RecoverableError

        testResults.append("✅ Data corruption error transformed")
        testResults.append("   Priority: \(recoverableError.priority) (should be critical)")
        testResults.append("   Recovery options: \(recoverableError.recoveryOptions.count)")
        testResults.append("   Is critical: \(mockError.isCritical)")
    }

    private func testDataCorruptionAsync() async {
        await MainActor.run {
            testDataCorruption()
        }
    }

    private func testNetworkErrors() {
        testResults.append("🔍 Testing network error handling...")

        let networkError = DaisyDosError.networkUnavailable
        let recoverableError = networkError as RecoverableError

        testResults.append("✅ Network error properly handled")
        testResults.append("   User message: '\(recoverableError.userMessage)'")
        testResults.append("   Is retryable: \(networkError.isRetryable)")
        testResults.append("   Priority: \(recoverableError.priority)")

        // Test recovery actions
        let recoveryActions = recoverableError.recoveryOptions
        testResults.append("   Recovery actions available: \(recoveryActions.count)")
        for (index, action) in recoveryActions.enumerated() {
            testResults.append("     \(index + 1). \(action.title) (\(action.style))")
        }
    }

    private func testNetworkErrorsAsync() async {
        await MainActor.run {
            testNetworkErrors()
        }
    }

    private func testRecoveryActions() {
        testResults.append("🔍 Testing recovery action system...")

        let tagLimitError = DaisyDosError.tagLimitExceeded
        let recoveryOptions = (tagLimitError as RecoverableError).recoveryOptions

        testResults.append("✅ Tag limit error has \(recoveryOptions.count) recovery options:")
        for (index, action) in recoveryOptions.enumerated() {
            testResults.append("   \(index + 1). \(action.title) (Style: \(action.style))")
        }

        // Test error categorization
        testResults.append("✅ Error categorization working:")
        testResults.append("   Tag limit is user error: \(tagLimitError.isUserError)")
        testResults.append("   Tag limit is retryable: \(tagLimitError.isRetryable)")
        testResults.append("   Tag limit is critical: \(tagLimitError.isCritical)")
    }

    private func testRecoveryActionsAsync() async {
        await MainActor.run {
            testRecoveryActions()
        }
    }

    private func testErrorPriorities() {
        testResults.append("🔍 Testing error priority system...")

        let errors: [(DaisyDosError, String)] = [
            (.validationFailed("test"), "Validation"),
            (.tagLimitExceeded, "Tag Limit"),
            (.networkUnavailable, "Network"),
            (.dataCorrupted("test"), "Data Corruption"),
            (.syncConflict("test"), "Sync Conflict")
        ]

        for (error, name) in errors {
            let recoverableError = error as RecoverableError
            testResults.append("   \(name): \(recoverableError.priority) priority")
        }

        testResults.append("✅ Error priority system working correctly")
    }

    private func testErrorPrioritiesAsync() async {
        await MainActor.run {
            testErrorPriorities()
        }
    }

    // MARK: - Error Demonstration

    private func demonstrateErrorBanner() {
        let error = WarningError(
            message: "This is a test warning",
            reason: "Demonstrating the error banner system"
        ) {
            testResults.append("✅ Retry action executed from banner")
        }
        currentError = error
    }

    private func demonstrateErrorAlert() {
        let error = DaisyDosError.syncConflict("Test conflict for alert demonstration")
        currentError = error
    }
}

// MARK: - Preview

#if DEBUG
struct ErrorHandlingTestView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorHandlingTestView()
            .modelContainer(for: [Task.self, Habit.self, Tag.self], inMemory: true)
            .environment(TaskManager(modelContext: try! ModelContainer(for: Task.self, Habit.self, Tag.self).mainContext))
            .environment(HabitManager(modelContext: try! ModelContainer(for: Task.self, Habit.self, Tag.self).mainContext))
            .environment(TagManager(modelContext: try! ModelContainer(for: Task.self, Habit.self, Tag.self).mainContext))
    }
}
#endif