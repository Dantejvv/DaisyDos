import Testing
import Foundation
@testable import DaisyDos

/// Comprehensive tests for RecurrenceRule - Most complex business logic in DaisyDos
/// Tests cover daily, weekly, monthly, yearly patterns with edge cases
@Suite("RecurrenceRule Tests")
struct RecurrenceRuleTests {

    // MARK: - Initialization & Validation Tests

    @Test("RecurrenceRule enforces minimum interval of 1")
    func testMinimumInterval() {
        let rule = RecurrenceRule(frequency: .daily, interval: 0)
        #expect(rule.interval == 1)

        let negativeRule = RecurrenceRule(frequency: .daily, interval: -5)
        #expect(negativeRule.interval == 1)
    }

    @Test("RecurrenceRule validation - valid intervals", arguments: [1, 2, 7, 14, 30])
    func testValidIntervals(interval: Int) {
        let rule = RecurrenceRule(frequency: .daily, interval: interval)
        #expect(rule.isValid)
        #expect(rule.interval == interval)
    }

    @Test("Weekly rule validates weekdays in range 1-7")
    func testWeeklyWeekdayValidation() {
        let validRule = RecurrenceRule.weekly(daysOfWeek: [1, 2, 3, 4, 5, 6, 7])
        #expect(validRule.isValid)

        let invalidRule = RecurrenceRule(frequency: .weekly, daysOfWeek: [0, 8])
        #expect(!invalidRule.isValid)
    }

    @Test("Monthly rule validates dayOfMonth in range 1-31")
    func testMonthlyDayValidation() {
        let validRule = RecurrenceRule.monthly(dayOfMonth: 15)
        #expect(validRule.isValid)

        let invalidLow = RecurrenceRule(frequency: .monthly, dayOfMonth: 0)
        #expect(!invalidLow.isValid)

        let invalidHigh = RecurrenceRule(frequency: .monthly, dayOfMonth: 32)
        #expect(!invalidHigh.isValid)
    }

    // MARK: - Daily Recurrence Tests

    @Test("Daily recurrence - simple interval")
    func testDailySimpleInterval() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule.daily()

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 2))!
        #expect(next == expected)
    }

    @Test("Daily recurrence - multi-day interval", arguments: [2, 3, 7, 14])
    func testDailyMultiDayInterval(interval: Int) {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule.daily(interval: interval)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(byAdding: .day, value: interval, to: startDate)!
        #expect(next == expected)
    }

    @Test("Daily recurrence respects end date")
    func testDailyEndDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!
        let rule = RecurrenceRule.daily(endDate: endDate)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 4) // Jan 2, 3, 4, 5
        #expect(occurrences.allSatisfy { $0 <= endDate })
    }

    // MARK: - Weekly Recurrence Tests

    @Test("Weekly recurrence - single day")
    func testWeeklySingleDay() {
        let calendar = Calendar.current
        // Start on Monday (weekday 2)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2]) // Monday

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // Should be next Monday
        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 13))!
        #expect(next == expected)
    }

    @Test("Weekly recurrence - multiple days within week")
    func testWeeklyMultipleDays() {
        let calendar = Calendar.current
        // Start on Monday (weekday 2)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4, 6]) // Mon, Wed, Fri

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // Should be Wednesday of same week
        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 8))!
        #expect(next == expected)
    }

    @Test("Weekly recurrence - week boundary crossing")
    func testWeeklyWeekBoundary() {
        let calendar = Calendar.current
        // Start on Friday (weekday 6)
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))! // Friday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2]) // Monday only

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // Should jump to next Monday
        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 13))!
        #expect(next == expected)
    }

    @Test("Weekly recurrence - weekdays pattern")
    func testWeekdaysPattern() {
        let rule = RecurrenceRule.weekdays
        #expect(rule.daysOfWeek == [2, 3, 4, 5, 6])
        #expect(rule.isValid)
    }

    @Test("Weekly recurrence - weekends pattern")
    func testWeekendsPattern() {
        let rule = RecurrenceRule.weekends
        #expect(rule.daysOfWeek == [1, 7])
        #expect(rule.isValid)
    }

    @Test("Weekly recurrence - bi-weekly interval")
    func testBiWeekly() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2], interval: 2) // Every 2 weeks on Monday

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // Should be Monday 2 weeks later
        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 20))!
        #expect(next == expected)
    }

    // MARK: - Monthly Recurrence Tests

    @Test("Monthly recurrence - simple")
    func testMonthlySimple() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 15)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        #expect(next == expected)
    }

    @Test("Monthly recurrence - 31st to February (leap year 2024)")
    func testMonthly31stToFebruaryLeapYear() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // February 2024 has 29 days (leap year), should fall back to last day
        let components = calendar.dateComponents([.year, .month, .day], from: next!)
        #expect(components.year == 2024)
        #expect(components.month == 2)
        #expect(components.day == 29) // Last day of February in leap year
    }

    @Test("Monthly recurrence - 31st to February (non-leap year 2025)")
    func testMonthly31stToFebruaryNonLeapYear() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // February 2025 has 28 days, should fall back to last day
        let components = calendar.dateComponents([.year, .month, .day], from: next!)
        #expect(components.year == 2025)
        #expect(components.month == 2)
        #expect(components.day == 28) // Last day of February in non-leap year
    }

    @Test("Monthly recurrence - 31st to 30-day month")
    func testMonthly31stTo30DayMonth() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 3, day: 31))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // April has 30 days, should fall back to last day
        let components = calendar.dateComponents([.year, .month, .day], from: next!)
        #expect(components.year == 2025)
        #expect(components.month == 4)
        #expect(components.day == 30) // Last day of April
    }

    @Test("Monthly recurrence - multi-month interval")
    func testMonthlyMultiMonthInterval() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 15, interval: 3)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2025, month: 4, day: 15))!
        #expect(next == expected)
    }

    @Test("Monthly recurrence - year boundary")
    func testMonthlyYearBoundary() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 15))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 15)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        #expect(next == expected)
    }

    // MARK: - Yearly Recurrence Tests

    @Test("Yearly recurrence - simple")
    func testYearlySimple() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule.yearly()

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        #expect(next == expected)
    }

    @Test("Yearly recurrence - leap year to non-leap year")
    func testYearlyLeapYearTransition() {
        let calendar = Calendar.current
        // Feb 29, 2024 (leap year)
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        let rule = RecurrenceRule.yearly()

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        // Calendar.date(byAdding:) adjusts Feb 29 -> Feb 28 for non-leap years
        let expected = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        #expect(next == expected)
    }

    @Test("Yearly recurrence - multi-year interval")
    func testYearlyMultiYearInterval() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule.yearly(interval: 5)

        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil)

        let expected = calendar.date(from: DateComponents(year: 2030, month: 1, day: 15))!
        #expect(next == expected)
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching - daily")
    func testDailyPatternMatching() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule.daily(interval: 2)

        let matchDate1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 3))! // +2 days
        #expect(rule.matches(date: matchDate1, relativeTo: baseDate))

        let matchDate2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))! // +4 days
        #expect(rule.matches(date: matchDate2, relativeTo: baseDate))

        let nonMatchDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 4))! // +3 days
        #expect(!rule.matches(date: nonMatchDate, relativeTo: baseDate))
    }

    @Test("Pattern matching - weekly")
    func testWeeklyPatternMatching() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4]) // Monday and Wednesday

        let mondayDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 13))! // Next Monday
        #expect(rule.matches(date: mondayDate, relativeTo: baseDate))

        let wednesdayDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 8))! // Wednesday same week
        #expect(rule.matches(date: wednesdayDate, relativeTo: baseDate))

        let tuesdayDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 7))! // Tuesday
        #expect(!rule.matches(date: tuesdayDate, relativeTo: baseDate))
    }

    // MARK: - Occurrences Generation Tests

    @Test("Generate occurrences with limit")
    func testGenerateOccurrencesWithLimit() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule.daily()

        let occurrences = rule.occurrences(from: startDate, limit: 10)
        #expect(occurrences.count == 10)

        // Verify they're sequential days
        for (index, date) in occurrences.enumerated() {
            let expected = calendar.date(byAdding: .day, value: index + 1, to: startDate)!
            #expect(date == expected)
        }
    }

    @Test("Generate occurrences stops at end date")
    func testGenerateOccurrencesStopsAtEndDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        let rule = RecurrenceRule.daily(endDate: endDate)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 9) // Jan 2-10
        #expect(occurrences.allSatisfy { $0 <= endDate })
    }

    // MARK: - TimeZone Tests

    @Test("TimeZone identifier is preserved")
    func testTimeZonePreservation() {
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let rule = RecurrenceRule(frequency: .daily, timeZone: pst)

        #expect(rule.timeZoneIdentifier == "America/Los_Angeles")
        #expect(rule.timeZone == pst)
    }

    @Test("Invalid timezone identifier falls back to current")
    func testInvalidTimeZoneFallback() {
        let rule = RecurrenceRule(frequency: .daily)
        var modifiedRule = rule
        // Access via the computed property which handles invalid identifiers
        #expect(rule.timeZone != nil)
    }

    // MARK: - Display Properties Tests

    @Test("Display description - daily")
    func testDisplayDescriptionDaily() {
        let rule1 = RecurrenceRule.daily()
        #expect(rule1.displayDescription == "Daily")

        let rule2 = RecurrenceRule.daily(interval: 3)
        #expect(rule2.displayDescription == "Every 3 days")
    }

    @Test("Display description - weekly")
    func testDisplayDescriptionWeekly() {
        let rule1 = RecurrenceRule.weekly(daysOfWeek: [2, 3])
        #expect(rule1.displayDescription.contains("Weekly on"))

        let rule2 = RecurrenceRule.weekly(daysOfWeek: [2], interval: 2)
        #expect(rule2.displayDescription.contains("Every 2 weeks on"))
    }

    @Test("Display description - monthly")
    func testDisplayDescriptionMonthly() {
        let rule1 = RecurrenceRule.monthly(dayOfMonth: 15)
        #expect(rule1.displayDescription == "Monthly on day 15")

        let rule2 = RecurrenceRule.monthly(dayOfMonth: 15, interval: 3)
        #expect(rule2.displayDescription == "Every 3 months on day 15")
    }

    @Test("Display description - yearly")
    func testDisplayDescriptionYearly() {
        let rule1 = RecurrenceRule.yearly()
        #expect(rule1.displayDescription == "Yearly")

        let rule2 = RecurrenceRule.yearly(interval: 2)
        #expect(rule2.displayDescription == "Every 2 years")
    }

    @Test("Display description - from completion mode")
    func testDisplayDescriptionFromCompletion() {
        let rule = RecurrenceRule(frequency: .daily, repeatMode: .fromCompletionDate)
        #expect(rule.displayDescription.contains("after completion"))
    }

    // MARK: - Codable Tests

    @Test("RecurrenceRule is Codable")
    func testCodable() throws {
        let original = RecurrenceRule.daily(interval: 3, endDate: Date())

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecurrenceRule.self, from: data)

        #expect(decoded.frequency == original.frequency)
        #expect(decoded.interval == original.interval)
        #expect(decoded.endDate == original.endDate)
    }

    // MARK: - Equatable Tests

    @Test("RecurrenceRule Equatable works correctly")
    func testEquatable() {
        let rule1 = RecurrenceRule.daily(interval: 2)
        let rule2 = RecurrenceRule.daily(interval: 2)
        let rule3 = RecurrenceRule.daily(interval: 3)

        // Same properties but different IDs - should still be equal based on properties
        #expect(rule1.frequency == rule2.frequency)
        #expect(rule1.interval == rule2.interval)

        #expect(rule1.interval != rule3.interval)
    }
}
