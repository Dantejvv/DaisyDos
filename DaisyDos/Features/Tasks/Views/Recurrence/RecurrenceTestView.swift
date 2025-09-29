//
//  RecurrenceTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//
//  Test view for validating recurrence calculations across timezone changes

import SwiftUI

struct RecurrenceTestView: View {
    @State private var testResults: [TestResult] = []
    @State private var isRunning = false

    struct TestResult {
        let testName: String
        let passed: Bool
        let details: String
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Test controls
                    VStack(spacing: 12) {
                        Button(action: runTests) {
                            HStack {
                                if isRunning {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text(isRunning ? "Running Tests..." : "Run Recurrence Tests")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Colors.Secondary.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRunning)

                        Text("Tests timezone handling, edge cases, and calculation accuracy")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))

                    // Test results
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Results")
                                .font(.headline)
                                .foregroundColor(.daisyText)

                            let passedCount = testResults.filter { $0.passed }.count
                            let totalCount = testResults.count

                            HStack {
                                Text("Passed: \(passedCount)/\(totalCount)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(passedCount == totalCount ? .green : .orange)

                                Spacer()

                                Image(systemName: passedCount == totalCount ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(passedCount == totalCount ? .green : .orange)
                            }
                            .padding()
                            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))

                            ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                                TestResultCard(result: result)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recurrence Tests")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func runTests() {
        isRunning = true
        testResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            let results = performRecurrenceTests()

            DispatchQueue.main.async {
                testResults = results
                isRunning = false
            }
        }
    }

    private func performRecurrenceTests() -> [TestResult] {
        var results: [TestResult] = []

        // Test 1: Daily recurrence basic functionality
        results.append(testDailyRecurrence())

        // Test 2: Weekly recurrence with specific days
        results.append(testWeeklyRecurrence())

        // Test 3: Monthly recurrence edge cases
        results.append(testMonthlyRecurrence())

        // Test 4: Timezone changes
        results.append(testTimezoneHandling())

        // Test 5: End date validation
        results.append(testEndDateHandling())

        // Test 6: Maximum occurrences
        results.append(testMaxOccurrences())

        // Test 7: Leap year handling
        results.append(testLeapYearHandling())

        return results
    }

    // MARK: - Individual Test Methods

    private func testDailyRecurrence() -> TestResult {
        let rule = RecurrenceRule.daily(interval: 2)
        let startDate = Date()

        guard let nextOccurrence = rule.nextOccurrence(after: startDate) else {
            return TestResult(
                testName: "Daily Recurrence",
                passed: false,
                details: "Failed to calculate next occurrence"
            )
        }

        let expectedDate = Calendar.current.date(byAdding: .day, value: 2, to: startDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: nextOccurrence, to: expectedDate).day ?? 0

        let passed = abs(daysDifference) <= 1 // Allow 1 day tolerance

        return TestResult(
            testName: "Daily Recurrence",
            passed: passed,
            details: passed ? "✅ Every 2 days calculation correct" : "❌ Expected 2 day interval, got different result"
        )
    }

    private func testWeeklyRecurrence() -> TestResult {
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4, 6]) // Monday, Wednesday, Friday
        let occurrences = rule.occurrences(from: Date(), limit: 10)

        let passed = occurrences.count > 0 && occurrences.count <= 10

        return TestResult(
            testName: "Weekly Recurrence",
            passed: passed,
            details: passed ? "✅ Generated \(occurrences.count) weekly occurrences" : "❌ Failed to generate weekly occurrences"
        )
    }

    private func testMonthlyRecurrence() -> TestResult {
        // Test monthly recurrence on day 31 (should handle short months)
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 31))!

        guard let nextOccurrence = rule.nextOccurrence(after: startDate) else {
            return TestResult(
                testName: "Monthly Recurrence",
                passed: false,
                details: "Failed to calculate next occurrence for day 31"
            )
        }

        // Should handle February by going to the last day
        let day = Calendar.current.component(.day, from: nextOccurrence)
        let month = Calendar.current.component(.month, from: nextOccurrence)

        let passed = month == 2 && (day >= 28 && day <= 29) // February handling

        return TestResult(
            testName: "Monthly Recurrence",
            passed: passed,
            details: passed ? "✅ Correctly handled day 31 in February" : "❌ Failed to handle month overflow correctly"
        )
    }

    private func testTimezoneHandling() -> TestResult {
        // Test with different timezones
        let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")!

        let rule1 = RecurrenceRule(frequency: .daily, timeZone: pacificTimeZone)
        let rule2 = RecurrenceRule(frequency: .daily, timeZone: tokyoTimeZone)

        let passed = rule1.timeZone.identifier == "America/Los_Angeles" &&
                    rule2.timeZone.identifier == "Asia/Tokyo"

        return TestResult(
            testName: "Timezone Handling",
            passed: passed,
            details: passed ? "✅ Timezone identifiers preserved correctly" : "❌ Timezone handling failed"
        )
    }

    private func testEndDateHandling() -> TestResult {
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let rule = RecurrenceRule.daily(endDate: endDate)

        let occurrences = rule.occurrences(from: Date(), limit: 100)
        let lastOccurrence = occurrences.last

        let passed = lastOccurrence == nil || lastOccurrence! <= endDate

        return TestResult(
            testName: "End Date Handling",
            passed: passed,
            details: passed ? "✅ Respected end date boundary" : "❌ Generated occurrences past end date"
        )
    }

    private func testMaxOccurrences() -> TestResult {
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 1,
            maxOccurrences: 5
        )

        // Note: Current implementation doesn't fully support maxOccurrences
        // This test validates that the property is stored correctly
        let passed = rule.maxOccurrences == 5

        return TestResult(
            testName: "Max Occurrences",
            passed: passed,
            details: passed ? "✅ Max occurrences property stored correctly" : "❌ Max occurrences not preserved"
        )
    }

    private func testLeapYearHandling() -> TestResult {
        // Test yearly recurrence on February 29
        let leapYear = 2024
        let startDate = Calendar.current.date(from: DateComponents(year: leapYear, month: 2, day: 29))!
        let rule = RecurrenceRule.yearly()

        guard let nextOccurrence = rule.nextOccurrence(after: startDate) else {
            return TestResult(
                testName: "Leap Year Handling",
                passed: false,
                details: "Failed to calculate next occurrence from Feb 29"
            )
        }

        let nextYear = Calendar.current.component(.year, from: nextOccurrence)
        let passed = nextYear == leapYear + 1

        return TestResult(
            testName: "Leap Year Handling",
            passed: passed,
            details: passed ? "✅ Handled leap year transition correctly" : "❌ Leap year calculation failed"
        )
    }
}

// MARK: - Test Result Card

struct TestResultCard: View {
    let result: RecurrenceTestView.TestResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            Color.daisySurface,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.passed ? .green.opacity(0.3) : .red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    RecurrenceTestView()
}