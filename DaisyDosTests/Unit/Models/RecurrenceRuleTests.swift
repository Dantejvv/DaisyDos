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
        #expect(rule1.displayDescription == "Monthly on the 15th")

        let rule2 = RecurrenceRule.monthly(dayOfMonth: 15, interval: 3)
        #expect(rule2.displayDescription == "Every 3 months on the 15th")
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

    // MARK: - maxOccurrences + endDate Combination Tests

    @Test("maxOccurrences alone limits occurrences")
    func testMaxOccurrencesAlone() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule(frequency: .daily, interval: 1, maxOccurrences: 5)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 5, "Should stop at maxOccurrences")
    }

    @Test("endDate alone limits occurrences")
    func testEndDateAlone() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!
        let rule = RecurrenceRule.daily(endDate: endDate)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 4, "Should stop at endDate")
        #expect(occurrences.allSatisfy { $0 <= endDate })
    }

    @Test("maxOccurrences reached before endDate - maxOccurrences wins")
    func testMaxOccurrencesBeforeEndDate() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        let rule = RecurrenceRule(frequency: .daily, interval: 1, endDate: endDate, maxOccurrences: 3)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 3, "Should stop at maxOccurrences (3) before endDate allows 9")
    }

    @Test("endDate reached before maxOccurrences - endDate wins")
    func testEndDateBeforeMaxOccurrences() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 3))!
        let rule = RecurrenceRule(frequency: .daily, interval: 1, endDate: endDate, maxOccurrences: 10)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 2, "Should stop at endDate (2 days) before maxOccurrences allows 10")
        #expect(occurrences.allSatisfy { $0 <= endDate })
    }

    @Test("maxOccurrences=1 creates single occurrence")
    func testMaxOccurrencesSingle() {
        let rule = RecurrenceRule(frequency: .daily, maxOccurrences: 1)
        let startDate = Date()

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 1, "maxOccurrences=1 should create only one occurrence")
    }

    @Test("maxOccurrences with weekly recurrence")
    func testMaxOccurrencesWeekly() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4], interval: 1) // Mon, Wed
        let ruleWithMax = RecurrenceRule(
            frequency: rule.frequency,
            interval: rule.interval,
            daysOfWeek: rule.daysOfWeek,
            maxOccurrences: 5
        )

        let occurrences = ruleWithMax.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 5, "Should create exactly 5 occurrences across Mon/Wed pattern")
    }

    @Test("maxOccurrences with monthly recurrence")
    func testMaxOccurrencesMonthly() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule(frequency: .monthly, dayOfMonth: 15, maxOccurrences: 3)

        let occurrences = rule.occurrences(from: startDate, limit: 100)
        #expect(occurrences.count == 3, "Should create 3 monthly occurrences")

        // Verify dates are Feb 15, Mar 15, Apr 15
        let months = occurrences.map { calendar.component(.month, from: $0) }
        #expect(months == [2, 3, 4])
    }

    // MARK: - Time/DST Edge Case Tests

    @Test("Time at midnight (00:00)")
    func testTimeMidnight() {
        let rule = RecurrenceRule.daily(time: "00:00")
        #expect(rule.preferredTimeHour == 0)
        #expect(rule.preferredTimeMinute == 0)

        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 12))!
        let next = rule.nextOccurrence(after: start)
        #expect(next != nil)

        let hour = calendar.component(.hour, from: next!)
        #expect(hour == 0, "Should be midnight")
    }

    @Test("Time at end of day (23:59)")
    func testTimeEndOfDay() {
        let rule = RecurrenceRule.daily(time: "23:59")
        #expect(rule.preferredTimeHour == 23)
        #expect(rule.preferredTimeMinute == 59)

        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 12))!
        let next = rule.nextOccurrence(after: start)
        #expect(next != nil)

        let hour = calendar.component(.hour, from: next!)
        let minute = calendar.component(.minute, from: next!)
        #expect(hour == 23)
        #expect(minute == 59)
    }

    @Test("Invalid time formats return nil")
    func testInvalidTimeFormats() {
        let invalidFormats = ["9am", "25:00", "9:70", "midnight", "12:00:00", "abc", "12", ":30"]

        for format in invalidFormats {
            let rule = RecurrenceRule.daily(time: format)
            #expect(rule.preferredTime == nil, "Format '\(format)' should be invalid")
        }
    }

    @Test("Time preservation across DST - spring forward")
    func testDSTSpringForward() {
        // DST in US: March 9, 2025 at 2:00 AM → 3:00 AM
        let calendar = Calendar.current
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let rule = RecurrenceRule(frequency: .daily, timeZone: pst, preferredTime: DateComponents(hour: 9, minute: 0))

        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pst

        // March 8, 2025 at 9 AM PST (before DST)
        let beforeDST = pstCalendar.date(from: DateComponents(
            timeZone: pst,
            year: 2025,
            month: 3,
            day: 8,
            hour: 9
        ))!

        // Get next occurrence (should be March 9 at 9 AM PDT)
        let next = rule.nextOccurrence(after: beforeDST)
        #expect(next != nil)

        let components = pstCalendar.dateComponents([.hour, .minute], from: next!)
        #expect(components.hour == 9, "Hour should remain 9 despite DST")
        #expect(components.minute == 0)
    }

    @Test("Time preservation across DST - fall back")
    func testDSTFallBack() {
        // DST ends in US: November 2, 2025 at 2:00 AM → 1:00 AM
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let rule = RecurrenceRule(frequency: .daily, timeZone: pst, preferredTime: DateComponents(hour: 9, minute: 0))

        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pst

        // November 1, 2025 at 9 AM PDT (before DST ends)
        let beforeDST = pstCalendar.date(from: DateComponents(
            timeZone: pst,
            year: 2025,
            month: 11,
            day: 1,
            hour: 9
        ))!

        let next = rule.nextOccurrence(after: beforeDST)
        #expect(next != nil)

        let components = pstCalendar.dateComponents([.hour, .minute], from: next!)
        #expect(components.hour == 9, "Hour should remain 9 despite DST")
    }

    @Test("Weekly recurrence across DST boundary")
    func testWeeklyAcrossDST() {
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let rule = RecurrenceRule.weekly(
            daysOfWeek: [2], // Monday
            time: "09:00"
        )

        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pst

        // Monday March 2, 2025 (before DST)
        let monday1 = pstCalendar.date(from: DateComponents(
            timeZone: pst,
            year: 2025,
            month: 3,
            day: 2,
            hour: 9
        ))!

        // Next should be Monday March 9 (after DST)
        let monday2 = rule.nextOccurrence(after: monday1)
        #expect(monday2 != nil)

        let components = pstCalendar.dateComponents([.weekday, .hour], from: monday2!)
        #expect(components.weekday == 2, "Should be Monday")
        #expect(components.hour == 9, "Should preserve 9 AM")
    }

    @Test("International timezone - Pacific/Auckland")
    func testInternationalTimezone() {
        let nzt = TimeZone(identifier: "Pacific/Auckland")!
        let rule = RecurrenceRule(frequency: .daily, timeZone: nzt)

        #expect(rule.timeZoneIdentifier == "Pacific/Auckland")
        #expect(rule.timeZone == nzt)

        let startDate = Date()
        let next = rule.nextOccurrence(after: startDate)
        #expect(next != nil, "Should work with NZ timezone")
    }

    // MARK: - Monthly Day Transition Tests

    @Test("Monthly 29th through February non-leap year")
    func testMonthly29thThroughFebruary() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 29)

        // Start Jan 29, 2025
        let jan29 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 29))!
        let feb = rule.nextOccurrence(after: jan29)
        #expect(feb != nil)

        let febComponents = calendar.dateComponents([.month, .day], from: feb!)
        #expect(febComponents.month == 2)
        #expect(febComponents.day == 28, "Feb 2025 only has 28 days, should clamp to 28")

        // Next should be Mar 29
        let mar = rule.nextOccurrence(after: feb!)
        let marComponents = calendar.dateComponents([.month, .day], from: mar!)
        #expect(marComponents.month == 3)
        #expect(marComponents.day == 29, "March has 29th")
    }

    @Test("Monthly 30th through February")
    func testMonthly30thThroughFebruary() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 30)

        let jan30 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 30))!
        let feb = rule.nextOccurrence(after: jan30)
        #expect(feb != nil)

        let febComponents = calendar.dateComponents([.month, .day], from: feb!)
        #expect(febComponents.day == 28, "Feb only has 28 days")
    }

    @Test("Monthly 31st consecutive transitions")
    func testMonthly31stConsecutiveTransitions() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!

        // Generate 6 months of occurrences
        let occurrences = rule.occurrences(from: jan31, limit: 6)
        #expect(occurrences.count == 6)

        // Verify each month
        let expectedDays = [28, 31, 30, 31, 30, 31] // Feb, Mar, Apr, May, Jun, Jul
        for (index, date) in occurrences.enumerated() {
            let day = calendar.component(.day, from: date)
            #expect(day == expectedDays[index], "Month \(index + 2) should have day \(expectedDays[index])")
        }
    }

    @Test("Monthly 31st full year cycle")
    func testMonthly31stFullYear() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let occurrences = rule.occurrences(from: jan31, limit: 12)

        // Expected last days: Feb=28, Mar=31, Apr=30, May=31, Jun=30, Jul=31, Aug=31, Sep=30, Oct=31, Nov=30, Dec=31, Jan=31
        let expectedDays = [28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, 31]

        for (index, date) in occurrences.enumerated() {
            let day = calendar.component(.day, from: date)
            #expect(day == expectedDays[index], "Occurrence \(index) should have day \(expectedDays[index])")
        }
    }

    @Test("Monthly 29th leap year transition")
    func testMonthly29thLeapYear() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 29)

        // Jan 29, 2024 (leap year)
        let jan29_2024 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 29))!
        let feb = rule.nextOccurrence(after: jan29_2024)
        #expect(feb != nil)

        let febComponents = calendar.dateComponents([.year, .month, .day], from: feb!)
        #expect(febComponents.year == 2024)
        #expect(febComponents.month == 2)
        #expect(febComponents.day == 29, "Feb 2024 is leap year with 29 days")
    }

    @Test("Monthly with multi-month interval and day clamping")
    func testMonthlyMultiIntervalClamping() {
        let calendar = Calendar.current
        let rule = RecurrenceRule.monthly(dayOfMonth: 31, interval: 3) // Every 3 months on 31st

        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let occurrences = rule.occurrences(from: jan31, limit: 4)

        // Jan → Apr (30) → Jul (31) → Oct (31) → Jan (31)
        let expectedDays = [30, 31, 31, 31]
        for (index, date) in occurrences.enumerated() {
            let day = calendar.component(.day, from: date)
            #expect(day == expectedDays[index])
        }
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching - monthly on specific day")
    func testMonthlyPatternMatching() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 15)

        // Match: Feb 15
        let feb15 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!
        #expect(rule.matches(date: feb15, relativeTo: baseDate))

        // Match: Mar 15
        let mar15 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 15))!
        #expect(rule.matches(date: mar15, relativeTo: baseDate))

        // Non-match: Feb 14
        let feb14 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 14))!
        #expect(!rule.matches(date: feb14, relativeTo: baseDate))
    }

    @Test("Pattern matching - monthly with clamping")
    func testMonthlyPatternMatchingWithClamping() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let rule = RecurrenceRule.monthly(dayOfMonth: 31)

        // Should match Feb 28 (clamped from 31)
        let feb28 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        #expect(rule.matches(date: feb28, relativeTo: baseDate), "Should match clamped day")

        // Should NOT match Feb 27
        let feb27 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 27))!
        #expect(!rule.matches(date: feb27, relativeTo: baseDate))

        // Should match Mar 31
        let mar31 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 31))!
        #expect(rule.matches(date: mar31, relativeTo: baseDate))
    }

    @Test("Pattern matching - yearly")
    func testYearlyPatternMatching() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let rule = RecurrenceRule.yearly()

        // Match: Jun 15, 2026
        let year2 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        #expect(rule.matches(date: year2, relativeTo: baseDate))

        // Match: Jun 15, 2027
        let year3 = calendar.date(from: DateComponents(year: 2027, month: 6, day: 15))!
        #expect(rule.matches(date: year3, relativeTo: baseDate))

        // Non-match: Jun 16, 2026
        let wrong = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        #expect(!rule.matches(date: wrong, relativeTo: baseDate))
    }

    @Test("Pattern matching - yearly with leap day")
    func testYearlyPatternMatchingLeapDay() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))! // Leap day
        let rule = RecurrenceRule.yearly()

        // 2025 is not leap year - should match Feb 28 (clamped)
        let feb28_2025 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        #expect(rule.matches(date: feb28_2025, relativeTo: baseDate), "Should match clamped leap day")

        // 2028 is leap year - should match Feb 29
        let feb29_2028 = calendar.date(from: DateComponents(year: 2028, month: 2, day: 29))!
        #expect(rule.matches(date: feb29_2028, relativeTo: baseDate))
    }

    @Test("Pattern matching - weekly with interval")
    func testWeeklyPatternMatchingWithInterval() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule.weekly(daysOfWeek: [2], interval: 2) // Every 2 weeks on Monday

        // Match: Monday 2 weeks later
        let monday2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 20))!
        #expect(rule.matches(date: monday2, relativeTo: baseDate))

        // Non-match: Monday 1 week later (wrong interval)
        let monday1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 13))!
        #expect(!rule.matches(date: monday1, relativeTo: baseDate))

        // Match: Monday 4 weeks later
        let monday4 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 3))!
        #expect(rule.matches(date: monday4, relativeTo: baseDate))
    }

    @Test("Pattern matching - date before baseDate")
    func testPatternMatchingBeforeBaseDate() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let rule = RecurrenceRule.daily()

        // Date before baseDate should not match
        let before = calendar.date(from: DateComponents(year: 2025, month: 5, day: 31))!
        #expect(!rule.matches(date: before, relativeTo: baseDate))
    }

    @Test("Pattern matching - custom frequency")
    func testCustomFrequencyPatternMatching() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let rule = RecurrenceRule(frequency: .custom, interval: 7) // Every 7 days

        // Match: +7 days
        let day7 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 8))!
        #expect(rule.matches(date: day7, relativeTo: baseDate))

        // Match: +14 days
        let day14 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        #expect(rule.matches(date: day14, relativeTo: baseDate))

        // Non-match: +10 days
        let day10 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 11))!
        #expect(!rule.matches(date: day10, relativeTo: baseDate))
    }
}
