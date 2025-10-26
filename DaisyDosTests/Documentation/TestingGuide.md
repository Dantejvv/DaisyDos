# DaisyDos Testing Guide

**Last Updated:** October 24, 2025
**Testing Framework:** Swift Testing (modern @Test macro)
**SwiftData Version:** iOS 17.0+

---

## Overview

This guide covers how to write, run, and organize tests for the DaisyDos application using modern Swift Testing patterns and SwiftData in-memory containers.

---

## Quick Start

### Running Tests

**All tests:**
```bash
xcodebuild test -project DaisyDos.xcodeproj -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Specific test suite:**
```bash
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DaisyDosTests/SuiteName
```

**Specific test:**
```bash
xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DaisyDosTests/SuiteName/testName
```

**In Xcode:**
- Run all tests: `Cmd+U`
- Run specific test: Click diamond in gutter next to test
- View tests: `Cmd+6` (Test Navigator)

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

## Resources

- [Swift Testing Documentation](https://github.com/apple/swift-testing)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [FRESH_TESTING_PLAN.md](../../Docs/FRESH_TESTING_PLAN.md) - Complete testing strategy

---

**Questions or Issues?**

Refer to `FRESH_TESTING_PLAN.md` for detailed implementation guidance and architectural decisions.
