# DaisyDos Testing Guide

**Last Updated:** December 22, 2025
**Testing Framework:** Swift Testing (modern @Test macro)
**SwiftData Version:** iOS 17.0+

## Document Navigation

**This document:** Comprehensive testing guide and best practices
**For architecture and patterns:** [CLAUDE.md](../../CLAUDE.md)
**For feature implementation status:** [implementation_roadmap.md](../../Docs/implementation_roadmap.md)

---

## Table of Contents

1. [Test Metrics](#test-metrics)
2. [Overview](#overview)
3. [Testing Philosophy](#testing-philosophy)
4. [Quick Start](#quick-start)
5. [Writing Tests](#writing-tests)
6. [TestHelpers Usage](#testhelpers-usage)
7. [Common Patterns](#common-patterns)
8. [Advanced Patterns](#advanced-patterns)
9. [Test Organization](#test-organization)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)
12. [Examples from Codebase](#examples-from-codebase)
13. [Key Learnings](#key-learnings)
14. [Resources](#resources)

---

## Test Metrics

**Status:** ✅ **PRODUCTION READY**

| Metric | Value |
|--------|-------|
| Total Tests | 199 |
| Passing Tests | 199 |
| Pass Rate | 100% |
| Execution Time | ~0.35 seconds |
| Average per Test | ~1.8ms |
| Framework | Swift Testing (100%) |
| Flaky Tests | 0 |

**Test Coverage:**
- Infrastructure: 4 tests (container validation, isolation)
- RecurrenceRule: 35 tests (date calculations, edge cases)
- Habit Model: 20 tests (streak logic, completion tracking)
- Task Model: 24 tests (completion cascading, relationships)
- TaskManager: 22 tests (CRUD, filtering, search, duplicate) ✨ NEW +2
- HabitSkip: 15 tests (impact analysis, frequency)
- **HabitManager: 26 tests** (CRUD, completion, tags, search) ✨ NEW
- **TagManager: 24 tests** (CRUD, validation, 30-tag limit) ✨ NEW
- **LogbookManager: 11 tests** (housekeeping, archival, retention) ✨ NEW
- **TaskLogEntry: 9 tests** (snapshot creation, duration) ✨ NEW

**Run All New Tests:**
```bash
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/HabitManagerTests \
  -only-testing:DaisyDosTests/TagManagerTests \
  -only-testing:DaisyDosTests/LogbookManagerTests \
  -only-testing:DaisyDosTests/TaskLogEntryTests

✔ Test run with 62 tests passed after 0.278 seconds.
```

---

## Overview

This guide covers how to write, run, and organize tests for the DaisyDos application using modern Swift Testing patterns and SwiftData in-memory containers.

### Key Achievements

**Modern Testing Foundation:**
- 100% Swift Testing framework (no XCTest legacy code)
- Perfect test isolation with fresh containers per test
- Struct-based test suites for value semantics
- Pattern matching for Result types
- Comprehensive edge case coverage (leap years, boundaries, cascading logic)

**Critical Edge Cases Tested:**
- Feb 29 → Feb 28 transitions (leap year handling)
- Month boundaries (Jan 31 → Feb 28/29)
- Year boundaries (Dec 31 → Jan 1)
- Parent→Subtask completion cascading (bidirectional)
- Multiple completions same day
- Out-of-order completion entries
- Tag limit enforcement (3 per item, 30 system-wide)
- Skip impact calculation (6 severity levels)

---

## Testing Philosophy

### What We Test

- ✅ **Domain model logic** - Completion cascades, streak calculation, state transitions
- ✅ **Manager services** - CRUD operations, validation, business rules, error handling
- ✅ **Complex calculations** - RecurrenceRule date math, skip impact analysis
- ✅ **Data integrity** - Relationships, cascading deletes, persistence

### What We DON'T Test

- ❌ **SwiftUI view rendering** - Too brittle, UI tests are manual
- ❌ **Simple getters/setters** - Trivial logic, no value
- ❌ **SwiftData framework behavior** - Trust Apple's framework
- ❌ **Third-party library internals** - Test our integration points only

### When to Write Tests

- **Before merge:** All new business logic must have tests
- **For bug fixes:** Add regression test that fails, then fix
- **For refactoring:** Tests prove behavior unchanged
- **Skip for:** UI-only changes, trivial updates, prototype code

### Test Coverage Goals

- **Domain models:** 100% (critical business logic)
- **Managers/Services:** 100% (orchestration and validation)
- **UI layer:** 0% automated (manual testing only)
- **Infrastructure:** Validation tests only

### Testing Principles

1. **Test behavior, not implementation** - Focus on "what" not "how"
2. **One concept per test** - Single assertion path per test
3. **Obvious over clever** - Clear > concise
4. **Fast over comprehensive** - 199 tests in 0.35s is the goal

---

## Quick Start

### Running Tests

**Command Line:**
```bash
# All tests
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16'

# Specific test suite
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/RecurrenceRuleTests

# Specific test
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/RecurrenceRuleTests/testDailySimpleInterval
```

**In Xcode:**
- Run all tests: `Cmd+U`
- Run specific test: Click diamond in gutter next to test
- View tests: `Cmd+6` (Test Navigator)
- View detailed results: `Cmd+9` (Report Navigator)

**Test Summary Output:**

Swift Testing automatically provides a summary at the end of test execution:

```
✔ Suite "Infrastructure Tests" passed after 0.003 seconds.
✔ Suite "Recurrence Rule Tests" passed after 0.025 seconds.
✔ Suite "Habit Model Tests" passed after 0.019 seconds.
...
✔ Test run with 118 tests passed after 0.235 seconds.

** TEST SUCCEEDED **
```

The summary shows:
- Total test count (118 tests)
- Pass/fail status for each suite
- Execution time per suite and overall
- Final test result (SUCCEEDED/FAILED)

---

## Writing Tests

### Basic Test Structure

```swift
import Testing
import SwiftData
@testable import DaisyDos

@Suite("Feature Tests")
struct FeatureTests {

    @Test("Test description")
    func testFeature() async throws {
        // 1. Create isolated container
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 2. Create manager or perform setup
        let manager = FeatureManager(modelContext: context)

        // 3. Execute operation
        let result = manager.performOperation()

        // 4. Verify expectations
        #expect(result.isValid)
        #expect(result.count == 1)
    }
}
```

### Key Principles

1. **Use structs for test suites** (default pattern)
2. **Create fresh container in each test** (perfect isolation)
3. **Never store containers in properties** (causes lifecycle issues)
4. **Use #expect for assertions** (not XCTAssert)
5. **Mark tests async throws** when needed
6. **Apply @MainActor only to specific tests** (not entire suite)

---

## TestHelpers Usage

### Creating Containers

```swift
// Pattern 1: Create container when you need both container and context
let container = try TestHelpers.createTestContainer()
let manager = TaskManager(modelContext: container.mainContext)

// Pattern 2: Create context directly when you only need context
let context = try TestHelpers.createTestContext()
```

### Why This Pattern Works

- Each test gets a fresh, isolated in-memory database
- No data pollution between tests
- Fast execution (no disk I/O)
- Automatic cleanup when test ends
- Uses same schema as production app

---

## Common Patterns

### Testing Model Logic

```swift
@Test("Task completion cascades to subtasks")
func testTaskCompletionCascade() async throws {
    let container = try TestHelpers.createTestContainer()
    let context = ModelContext(container)

    // Create parent task with subtasks
    let parent = Task(title: "Parent")
    let subtask1 = Task(title: "Subtask 1")
    let subtask2 = Task(title: "Subtask 2")

    parent.subtasks.append(subtask1)
    parent.subtasks.append(subtask2)

    context.insert(parent)
    try context.save()

    // Mark parent complete
    parent.markComplete()

    // Verify cascade
    #expect(parent.isCompleted)
    #expect(subtask1.isCompleted)
    #expect(subtask2.isCompleted)
}
```

### Testing Manager Services

```swift
@Test("TaskManager creates task with validation")
func testTaskCreation() async throws {
    let container = try TestHelpers.createTestContainer()
    let manager = TaskManager(modelContext: container.mainContext)

    // Create task
    let result = manager.createTask(
        title: "Test Task",
        description: "Test Description",
        priority: .high
    )

    // Verify success
    #expect(result.isSuccess)

    // Fetch and verify
    let descriptor = FetchDescriptor<Task>()
    let tasks = try container.mainContext.fetch(descriptor)
    #expect(tasks.count == 1)
    #expect(tasks[0].title == "Test Task")
}
```

### Parameterized Tests

```swift
@Test("RecurrenceRule validates intervals", arguments: [1, 2, 7, 14, 30])
func testValidIntervals(interval: Int) async throws {
    let rule = RecurrenceRule(frequency: .daily, interval: interval)
    #expect(rule.interval == interval)
    #expect(rule.interval > 0)
}

@Test("Month boundaries handled correctly", arguments: [
    (month: 1, day: 31, expectedDays: 31),  // January
    (month: 2, day: 31, expectedDays: 28),  // February (non-leap)
    (month: 4, day: 31, expectedDays: 30),  // April
])
func testMonthBoundaries(month: Int, day: Int, expectedDays: Int) async throws {
    // Test logic here
}
```

### Testing SwiftUI Views (if needed)

```swift
@Test @MainActor func testViewRendering() async throws {
    let container = try TestHelpers.createTestContainer()
    let context = ModelContext(container)

    let task = Task(title: "Test")
    context.insert(task)

    let view = TaskRowView(task: task, displayMode: .compact)

    // Verify view properties
    #expect(view != nil)
}
```

---

## Advanced Patterns

### When to Use Classes Instead of Structs

Use `final class` when you need cleanup after each test:

```swift
@Suite
final class FileSystemTests {

    @Test func testFileCreation() async throws {
        let container = try TestHelpers.createTestContainer()
        // Create test files...
    }

    deinit {
        // Cleanup runs after EACH test
        // Remove test files, reset singletons, etc.
    }
}
```

### Serial vs Parallel Execution

```swift
// Default: Tests run in parallel (faster)
@Suite struct ParallelTests {
    @Test func test1() { }
    @Test func test2() { }  // Can run simultaneously with test1
}

// When tests share state or resources (use sparingly):
@Suite(.serialized) struct SerialTests {
    @Test func test1() { }
    @Test func test2() { }  // Waits for test1 to complete
}
```

---

## Test Organization

```
DaisyDosTests/
├── Helpers/
│   └── TestHelpers.swift (ModelContainer factory)
├── Unit/
│   ├── Models/
│   │   ├── TaskModelTests.swift
│   │   ├── HabitModelTests.swift
│   │   ├── RecurrenceRuleTests.swift
│   │   └── TagModelTests.swift
│   └── Services/
│       ├── TaskManagerTests.swift
│       ├── HabitManagerTests.swift
│       └── TagManagerTests.swift
└── Documentation/
    └── TestingGuide.md (this file)
```

### Naming Conventions

- **Test files:** `{Feature}Tests.swift`
- **Test suites:** `@Suite("{Feature} Tests")`
- **Test functions:** Descriptive names (`testTaskCompletionCascadesToSubtasks`)
- **Test display names:** Human-readable (`@Test("Task completion cascades to subtasks")`)

---

## Troubleshooting

### Container Creation Fails

**Error:** `SwiftDataError._Error.loadIssueModelContainer`

**Solution:**
- Ensure using `DaisyDosSchemaV4` in TestHelpers
- Verify `cloudKitDatabase: .none` is set
- Check all models are included in schema

### Tests Pass Individually But Fail in Suite

**Cause:** Shared state between tests

**Solution:**
- Create fresh container in EACH test (don't store in properties)
- Avoid static/shared variables
- Use struct-based suites for value semantics

### Tests Are Slow

**Expected:** ~180 tests should run in 20-30 seconds

**If slower:**
- Check for blocking operations
- Verify using in-memory containers
- Restart simulator
- Avoid unnecessary `.serialized` traits

---

## Best Practices

### ✅ DO

- Create fresh container in each test
- Use descriptive test names
- Test edge cases with parameterized tests
- Keep tests focused and independent
- Use #expect for modern assertions
- Apply @MainActor only to specific tests
- Default to struct-based suites

### ❌ DON'T

- Store containers in instance/static properties
- Share containers between tests
- Use @MainActor on entire suite
- Use `.serialized` unless necessary
- Mix XCTest and Swift Testing patterns
- Skip test isolation

---

## Examples from Codebase

### Exemplary Test Files

**InfrastructureTests.swift** - Foundation and isolation patterns
- Container creation and validation
- Context creation
- Test isolation verification (proves each test gets fresh container)
- Basic CRUD operations

**RecurrenceRuleTests.swift** - Complex business logic (35 tests)
- Comprehensive date calculation edge cases
- Demonstrates parameterized testing with `arguments:` parameter
- Month boundary handling (Jan 31 → Feb 28/29)
- Leap year transitions (Feb 29 → Feb 28)
- Year boundaries (Dec 31 → Jan 1)

**TaskManagerTests.swift** - Service layer patterns (22 tests)
- CRUD operations with validation
- Result type pattern matching (`guard case .success`)
- Duplicate detection logic
- Database persistence verification

**HabitManagerTests.swift** - Complete feature coverage (26 tests)
- Completion tracking and streak calculation
- Tag relationship management
- Search and filtering operations
- Error handling patterns

**TaskModelTests.swift** - Domain model testing (24 tests)
- Completion cascading (parent → subtasks)
- Bidirectional relationship testing
- State transition verification
- Computed property validation

---

## Key Learnings

### 1. Swift Testing Instance Creation
Swift Testing creates a **fresh instance of the test suite for EVERY test**:
- Storing containers in instance properties fails (deallocated before use)
- Local container creation is the only reliable pattern
- Struct-based suites enforce this pattern naturally

### 2. SwiftData Testing Configuration
Critical setup for testing:
```swift
let schema = Schema(versionedSchema: DaisyDosSchemaV4.self)
let configuration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true,
    cloudKitDatabase: .none  // CRITICAL: Disables CloudKit
)
```

### 3. Result Type Pattern Matching
Swift's Result doesn't have `.isSuccess` - use pattern matching:
```swift
// ✅ CORRECT
guard case .success(let value) = result else {
    Issue.record("Failed")
    return
}

// ❌ WRONG
if result.isSuccess { }  // Property doesn't exist
```

### 4. Edge Cases Find Real Bugs
Tests prevented production bugs by catching edge cases:

**Date Boundary Issues** (RecurrenceRuleTests.swift):
- Feb 29 → Feb 28 transition (not Mar 1!) when moving from leap to non-leap year
- Month boundaries: Jan 31 → Feb 28/29 handling
- Year boundaries: Dec 31 → Jan 1 transitions

**State Management Issues** (TaskModelTests.swift):
- Subtask completion cascading (parent completion affects all children)
- Bidirectional relationship integrity (parent ↔ subtask references)
- Completion date inheritance across task hierarchy

**Data Integrity Issues** (HabitModelTests.swift):
- Multiple completions same day (don't extend streak multiple times)
- Out-of-order completion entries (must sort before streak calculation)
- Skip impact on active streaks (6 severity levels affect differently)

---

## Resources

- [Swift Testing Documentation](https://github.com/apple/swift-testing)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CLAUDE.md](../../../CLAUDE.md) - Project testing overview

---

**Questions or Issues?**

Refer to this guide for all testing patterns and best practices. For project context, see the Testing Infrastructure section in CLAUDE.md.
