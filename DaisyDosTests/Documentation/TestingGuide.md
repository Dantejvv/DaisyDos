# DaisyDos Testing Guide

**Last Updated:** October 25, 2025
**Testing Framework:** Swift Testing (modern @Test macro)
**SwiftData Version:** iOS 17.0+

---

## Test Metrics

**Status:** ✅ **PRODUCTION READY**

| Metric | Value |
|--------|-------|
| Total Tests | 190 |
| Passing Tests | 190 |
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

See `InfrastructureTests.swift` for working examples of:
- Container creation and validation
- Context creation
- Test isolation verification
- Basic CRUD operations

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
Tests caught potential production bugs:
- Feb 29 → Feb 28 transition (not Mar 1!)
- Subtask completion inheritance
- Multiple completions same day handling
- Out-of-order entry sorting

---

## Resources

- [Swift Testing Documentation](https://github.com/apple/swift-testing)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CLAUDE.md](../../../CLAUDE.md) - Project testing overview

---

**Questions or Issues?**

Refer to this guide for all testing patterns and best practices. For project context, see the Testing Infrastructure section in CLAUDE.md.
