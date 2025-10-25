# Complete Testing Infrastructure Reset & Rebuild Plan

**Date:** October 22, 2025
**Status:** Ready for Implementation
**Approach:** Clean slate → Modern Swift Testing → Comprehensive domain coverage

---

## 🎯 Overview

Remove all existing test code and configuration, then build a fresh Swift Testing infrastructure following 2025 best practices with comprehensive domain logic coverage.

---

## 📋 Phase 1: Complete Test Removal & Cleanup (15 min)

### 1.1 Remove Test Directories
- Delete `/DaisyDosTests/` directory entirely
- Delete `/DaisyDosUITests/` directory entirely
- Remove test documentation: `TESTING_MIGRATION_PLAN.md`, `SWIFTDATA_TESTING_INVESTIGATION.md`

### 1.2 Clean Xcode Project Configuration
- Remove `DaisyDosTests` target from `DaisyDos.xcodeproj`
- Remove `DaisyDosUITests` target from `DaisyDos.xcodeproj`
- Remove test scheme configurations
- Clean build folder to remove test artifacts

### 1.3 Verify Clean State
- Build main app target successfully
- Confirm no test-related code in production bundle
- Verify git status shows expected deletions

---

## 📋 Phase 2: Fresh Testing Infrastructure Setup (30 min)

### 2.1 Create New Test Target
- Add new **Unit Test Bundle** target: `DaisyDosTests`
- Target settings:
  - iOS 17.0+ deployment target
  - Swift 6 language mode
  - Enable Swift Testing framework (modern @Test, not XCTest)
  - Link to main app target

### 2.2 Create Directory Structure
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
    └── TestingGuide.md
```

### 2.3 Create TestHelpers Foundation
- Implement `createTestContainer()` with all 8 models in schema
- Use `ModelConfiguration(isStoredInMemoryOnly: true)`
- Struct-based pattern (no classes, no shared state)
- Document usage examples

---

## 📋 Phase 3: Priority 1 - Core Domain Logic Tests (2-3 hours)

### 3.1 RecurrenceRuleTests (Highest Complexity)
**Priority: CRITICAL** - Most complex business logic

Test Coverage:
- ✅ Daily recurrence calculations (simple intervals)
- ✅ Weekly recurrence (weekday matching, week boundaries)
- ✅ Monthly recurrence (31st → Feb edge cases, leap years)
- ✅ Yearly recurrence (date preservation)
- ✅ End date enforcement
- ✅ Max occurrences limits
- ✅ Timezone handling
- ✅ Pattern matching validation

**Target: 25-30 parameterized tests**

**Key Edge Cases:**
- Interval = 1 vs > 1
- Weekdays at week boundary (Sunday→Monday)
- Monthly: 31st month → 28/30 day month
- End date enforcement (before, on, after)
- Year boundaries
- Leap years and February
- Timezone changes

---

### 3.2 HabitModelTests (Streak Logic)
**Priority: CRITICAL** - Core habit feature

Test Coverage:
- ✅ `recalculateStreakFromHistory()` with various completion patterns
- ✅ Consecutive day counting
- ✅ Gap detection (>1 day breaks streak)
- ✅ Empty history edge case
- ✅ Single completion
- ✅ Multiple completions same day
- ✅ Out-of-order completion entries
- ✅ Month/year boundaries
- ✅ `markCompleted()` prevents double completion
- ✅ `undoTodaysCompletion()` and recalculation

**Target: 20-25 tests**

**Key Edge Cases:**
- Empty completion history
- Single completion (streak = 1)
- Multiple completions same day (counts as 1)
- Multi-day gaps (>1 day)
- Completions out of chronological order
- Month/year boundaries

---

### 3.3 TaskModelTests (Completion Propagation)
**Priority: CRITICAL** - Complex relationship logic

Test Coverage:
- ✅ Parent completion cascades to all subtasks
- ✅ Completion date inheritance to subtasks
- ✅ Uncompleting parent uncompletes all subtasks
- ✅ Uncompleting subtask uncompletes parent
- ✅ One-level hierarchy enforcement
- ✅ Subtask ordering (moveUp/moveDown)
- ✅ Due date calculations (isDueToday, isDueSoon, hasOverdueStatus)
- ✅ Tag limit enforcement (3-tag max)

**Target: 25-30 tests**

**Key Edge Cases:**
- Parent with multiple subtasks at different states
- Uncompleting parent with mixed completion states
- Uncompleting subtask when others still complete
- Self-referential tasks (prevented but should test)
- Deep nesting attempts (should fail)
- Single subtask
- Two subtasks swapping
- Multiple swaps in sequence

---

## 📋 Phase 4: Priority 2 - Manager Service Tests (2-3 hours)

### 4.1 TaskManagerTests

Test Coverage:
- ✅ CRUD operations (create, update, delete, toggle completion)
- ✅ Subtask management (create, move, prevent nesting)
- ✅ Tag assignment/removal with limit enforcement
- ✅ Search functionality
- ✅ Filtering (priority, due date, overdue, tags)
- ✅ Recurring task processing
- ✅ Task duplication with date sanitization

**Target: 30-35 tests**

**Key Areas:**
- `createTask()` with validation
- `updateTask()` partial updates
- Subtask creation prevents subtasks of subtasks
- `addTag()`/`removeTag()` enforce 3-tag limit
- `searchTasks()` full-text search
- `processRecurringTasks()` creates new instances
- `duplicateTask()` sanitizes due dates

---

### 4.2 HabitManagerTests

Test Coverage:
- ✅ CRUD operations
- ✅ Completion tracking with and without notes/mood
- ✅ Undo completion functionality
- ✅ Skip tracking with reason
- ✅ Tag management
- ✅ Search and filtering
- ✅ Analytics calculations (completion rate, streaks)

**Target: 25-30 tests**

**Key Areas:**
- `createHabit()` validation
- `markHabitCompleted()` simple completion
- `markHabitCompletedWithTracking()` with notes/mood
- `undoHabitCompletion()` reverts today's completion
- `skipHabit()` creates skip entry
- Tag limit enforcement
- `todayCompletionRate`, `averageStreak`, `longestActiveStreak`

---

### 4.3 TagManagerTests

Test Coverage:
- ✅ CRUD with 30-tag system limit
- ✅ Name uniqueness validation
- ✅ Deletion prevention when in use
- ✅ Force delete functionality
- ✅ Color/symbol suggestions
- ✅ Usage analytics

**Target: 15-20 tests**

**Key Areas:**
- `createTag()` checks system limit + duplicate name
- `updateTag()` name uniqueness validation
- `deleteTag()` prevents deletion if in use
- `forceDeleteTag()` deletes even if in use
- `suggestTagColor()`/`suggestTagSymbol()`
- `validateTagName()` checks emptiness + uniqueness

---

## 📋 Phase 5: Priority 3 - Advanced Features Tests (1-2 hours)

### 5.1 HabitSkip & Impact Tests

Test Coverage:
- ✅ Skip frequency calculations
- ✅ Impact scoring matrix (6 outcomes)
- ✅ Justified vs unjustified skips

**Target: 10-12 tests**

**Impact Levels to Test:**
- `.rare`: <10% skip rate, no reason
- `.occasional`: <10% skip rate, with reason
- `.worrying`: 10-30% skip rate, no reason
- `.concerning`: 10-30% skip rate, with reason
- `.alarming`: >30% skip rate, no reason
- `.problematic`: >30% skip rate, with reason

---

### 5.2 TaskLogEntry Tests

Test Coverage:
- ✅ Snapshot creation from completed tasks
- ✅ Duration calculations
- ✅ Overdue status capture
- ✅ Tag name preservation

**Target: 8-10 tests**

**Key Areas:**
- `convenience init(from:)` creates accurate snapshot
- Completion duration (creation→completion)
- Overdue status at completion time
- Subtask relationships captured
- Tag names stored (not IDs)

---

### 5.3 Validation Logic Tests

Test Coverage:
- ✅ Title validation (non-empty)
- ✅ Tag limit enforcement across models
- ✅ RecurrenceRule validation (intervals, weekdays, dayOfMonth)

**Target: 10-12 tests**

**Validation Rules:**
- Task/Habit title cannot be empty
- Max 3 tags per task/habit
- System limit of 30 tags
- RecurrenceRule interval >= 1
- Weekdays must be 1-7
- dayOfMonth must be 1-31

---

## 📋 Phase 6: Documentation & Best Practices (30 min)

### 6.1 Update CLAUDE.md

Add comprehensive testing section:
- Modern Swift Testing pattern (struct-based)
- Local container creation in each test
- Parameterized testing examples
- Async/await patterns
- Anti-patterns to avoid

### 6.2 Create TestingGuide.md

Document:
- How to write new tests
- How to run tests (xcodebuild commands)
- Test organization principles
- Troubleshooting common issues

### 6.3 Test Template

Create reusable template file showing best practices

---

## 🎯 Testing Principles & Patterns

### ✅ Modern Swift Testing Pattern (REQUIRED)

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

        // 2. Create manager or actor
        let manager = FeatureManager(modelContext: container.mainContext)

        // 3. Execute operation
        let result = manager.performOperation()

        // 4. Verify expectations
        #expect(result.isValid)
        #expect(result.count == 1)
    }

    @Test("Parameterized test", arguments: [1, 2, 3, 4, 5])
    func testWithParameter(value: Int) async throws {
        let container = try TestHelpers.createTestContainer()
        // Test logic...
        #expect(value > 0)
    }
}
```

---

### ✅ Key Principles

1. **Struct-based suites (default)** - Use structs for value semantics and test isolation
2. **Local container per test** - Perfect isolation, create fresh container in each test
3. **No stored container properties** - Don't store containers in instance properties
4. **No @MainActor on suite** - Apply @MainActor only to individual tests that need it
5. **Parameterized tests** - Leverage Swift Testing's built-in parameterization
6. **#expect over XCTAssert** - Modern assertion macros
7. **Async/throws support** - Built-in, no special handling needed
8. **In-memory containers** - Fast, isolated, no disk I/O
9. **Classes for cleanup** - Use classes with deinit when you need per-test cleanup

---

### ❌ Anti-Patterns (AVOID)

```swift
// ❌ WRONG - Don't store container in property
@Suite
struct FeatureTests {
    let container: ModelContainer  // ❌ BAD - Stored property

    init() throws {
        container = try TestHelpers.createTestContainer()  // ❌ BAD
    }

    @Test func testFeature() async throws {
        // Container might be deallocated or stale
    }
}

// ❌ WRONG - Don't share containers across tests
@Suite
struct FeatureTests {
    static let sharedContainer = ...  // ❌ BAD - Shared state
}

// ❌ WRONG - Don't use @MainActor on entire suite
@Suite
@MainActor  // ❌ BAD - Slows down all tests unnecessarily
struct FeatureTests {
    @Test func testNonUILogic() { }  // Doesn't need main actor
}

// ❌ WRONG - Don't use .serialized without reason
@Suite(.serialized)  // ❌ BAD - Disables parallelization without justification
struct FeatureTests { }
```

---

### ✅ Valid Patterns (USE THESE)

```swift
// ✅ CORRECT - Struct with local container (DEFAULT PATTERN)
@Suite struct FeatureTests {
    @Test func testFeature() async throws {
        let container = try TestHelpers.createTestContainer()
        let manager = FeatureManager(modelContext: container.mainContext)

        let result = manager.performOperation()
        #expect(result.isValid)
    }
}

// ✅ CORRECT - Struct with init() is fine (for constants/setup)
@Suite struct FeatureTests {
    let testConstant: String

    init() {
        testConstant = "test-value"  // ✅ OK - Just don't store containers
    }

    @Test func testFeature() async throws {
        let container = try TestHelpers.createTestContainer()  // ✅ Local
        #expect(testConstant == "test-value")
    }
}

// ✅ CORRECT - Class with deinit for cleanup
@Suite
final class FileSystemTests {
    @Test func testFileCreation() async throws {
        let container = try TestHelpers.createTestContainer()
        // Create test files...
    }

    deinit {
        // ✅ Cleanup runs after EACH test
        // Remove test files, reset singletons, etc.
    }
}

// ✅ CORRECT - @MainActor on individual tests only
@Suite struct ViewTests {
    @Test @MainActor func testSwiftUIView() async throws {
        let container = try TestHelpers.createTestContainer()
        // SwiftUI code that needs main actor
    }

    @Test func testBackgroundLogic() async throws {
        // Runs on background thread (faster)
    }
}

// ✅ CORRECT - Parameterized test
@Suite struct ValidationTests {
    @Test("Valid intervals", arguments: [1, 2, 7, 14, 30])
    func testInterval(value: Int) async throws {
        let container = try TestHelpers.createTestContainer()
        let rule = RecurrenceRule(frequency: .daily, interval: value)
        #expect(rule.interval == value)
    }
}
```

---

## 📊 Expected Test Coverage

| Domain Area | Test Count | Priority | Est. Time |
|------------|------------|----------|-----------|
| RecurrenceRule | 25-30 | Critical | 1.5 hours |
| Habit Streaks | 20-25 | Critical | 1 hour |
| Task Completion | 25-30 | Critical | 1.5 hours |
| TaskManager | 30-35 | High | 1.5 hours |
| HabitManager | 25-30 | High | 1.5 hours |
| TagManager | 15-20 | High | 1 hour |
| Advanced Features | 30-35 | Medium | 1.5 hours |
| **TOTAL** | **~180 tests** | | **~10 hours** |

---

## 🚀 Implementation Strategy

### Execution Order

1. **Phase 1 first** - Clean slate ensures no conflicts
2. **Phase 2 immediately after** - Foundation must be solid
3. **Phase 3 next** - Critical business logic coverage
4. **Phases 4-5** - Build out comprehensive coverage
5. **Phase 6 last** - Document for future developers

### Validation at Each Phase

- Build succeeds after each phase
- Tests pass individually and as suite
- No test interdependencies
- Clean git commits per phase

---

## ✅ Success Criteria

- [ ] All existing test code removed from project
- [ ] Fresh test target builds successfully
- [ ] TestHelpers provides isolated containers
- [ ] ~180 comprehensive tests covering all domain logic
- [ ] All tests pass individually and as suite
- [ ] Documentation guides future test development
- [ ] Zero XCTest patterns (100% Swift Testing)
- [ ] Test execution time <30 seconds for full suite
- [ ] No flaky tests or race conditions
- [ ] Parameterized tests for edge cases
- [ ] Clear, descriptive test names

---

## 🔧 TestHelpers Implementation

```swift
import SwiftData
@testable import DaisyDos

enum TestHelpers {
    /// Creates an in-memory ModelContainer for testing with all DaisyDos models
    /// - Returns: A fresh ModelContainer configured for in-memory testing
    /// - Throws: If the container cannot be created (schema issues, etc.)
    static func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Tag.self,
            TaskAttachment.self,
            Habit.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            TaskLogEntry.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Creates a test ModelContext from a fresh container
    /// - Returns: A ModelContext ready for testing
    /// - Throws: If the container cannot be created
    static func createTestContext() throws -> ModelContext {
        let container = try createTestContainer()
        return ModelContext(container)
    }
}
```

**Usage Pattern:**
```swift
@Suite struct TaskTests {
    @Test func createTask() async throws {
        // Pattern 1: Create container when you need both container and context
        let container = try TestHelpers.createTestContainer()
        let manager = TaskManager(modelContext: container.mainContext)

        // Pattern 2: Create context directly when you only need context
        let context = try TestHelpers.createTestContext()

        // Each test gets its own fresh, isolated storage
    }
}
```

---

## 📚 Context7 Documentation References

### Swift Testing
- Library ID: `/swiftlang/swift-testing`
- Focus: @Test macro, parameterized tests, async/throws support

### SwiftData
- Library ID: `/websites/developer_apple_swiftdata`
- Focus: ModelContainer, ModelConfiguration, in-memory testing

### Swift Language
- Library ID: `/swiftlang/swift`
- Focus: Modern Swift patterns, concurrency

---

## 🐛 Troubleshooting

### Tests fail at 0.000s
**Cause:** Container deallocated or instance creation issue

**Solution:**
1. Verify using `struct` (not class)
2. Remove `init()` method
3. Remove stored `container` property
4. Add container creation to EACH test

---

### "Failed to find active container"
**Cause:** Container deallocated before use

**Solution:**
1. Create container at start of test function
2. Keep container in scope for entire test
3. Don't pass container to async closure that outlives test

---

### Tests are slow (>30 seconds)
**Cause:** Container creation overhead or expensive operations

**Expected:** ~180 tests should run in ~20-30 seconds

**Check:**
1. Container creation (~50ms each expected)
2. Simulator performance (restart if needed)
3. Blocking operations in tests

---

## 📝 Total Estimated Time

**Phase 1:** 15 minutes (cleanup)
**Phase 2:** 30 minutes (infrastructure)
**Phase 3:** 4-5 hours (critical domain logic - complex edge cases)
**Phase 4:** 3-4 hours (manager services)
**Phase 5:** 2-3 hours (advanced features)
**Phase 6:** 30 minutes (documentation)

**Total: 10-13 hours**

**Approach:** Incremental with validation at each phase

**Note:** Phase 3 requires extra time due to complexity of:
- RecurrenceRule edge cases (timezone, leap years, month boundaries)
- Habit streak calculations with grace periods
- Task subtask propagation with multiple edge cases

---

## 🎓 Key Learnings from Previous Attempts

### What We Learned
1. Swift Testing creates fresh suite instance for EVERY test
2. Storing containers in instance properties fails (deallocated before use)
3. `.serialized` controls execution order, not instance creation
4. Struct pattern + local containers = perfect isolation
5. XCTest patterns don't translate to Swift Testing
6. Each test needs its own container created locally
7. Classes are valid when you need deinit cleanup

### What We're Avoiding
1. Storing containers in instance properties (struct or class)
2. Shared containers across tests (static properties)
3. Container initialization in init() methods
4. @MainActor on entire suite (apply to individual tests only)
5. Unnecessary .serialized traits (kills parallelization)
6. XCTest migration patterns (setUp/tearDown/XCTAssert)

### What We're Embracing
1. Structs as default (value semantics, isolation)
2. Classes when cleanup needed (deinit for per-test cleanup)
3. Local container creation in each test
4. Parameterized testing for edge cases
5. Modern #expect assertions
6. Async/throws test functions

---

---

## 📚 Additional Best Practices & Patterns

### When to Use Struct vs Class

**Use Struct (Default):**
- ✅ Most tests (95%+ of cases)
- ✅ Tests with no cleanup needed
- ✅ Tests that can use local variables
- ✅ Maximum test isolation via value semantics

**Use Class (Specific Cases):**
- ✅ Tests that create files/directories (cleanup in deinit)
- ✅ Tests that modify global state (reset in deinit)
- ✅ Tests that need guaranteed cleanup after each test
- ✅ Tests that manage external resources

### @MainActor Usage Guidelines

```swift
// ✅ CORRECT - Apply to individual SwiftUI/UI tests
@Suite struct ViewTests {
    @Test @MainActor func testView() async throws {
        let container = try TestHelpers.createTestContainer()
        let view = TaskRowView(task: task)
        // Test SwiftUI view
    }

    @Test func testViewModel() async throws {
        // Runs on background thread - faster
    }
}

// ❌ WRONG - Entire suite forced onto main thread
@Suite @MainActor struct ViewTests {
    @Test func testView() { }
    @Test func testViewModel() { }  // Unnecessarily slow
}
```

### Container Lifecycle Best Practices

1. **Always create locally** - Container created inside test function
2. **Let scope manage lifecycle** - Container deallocates when test ends
3. **No storage in properties** - Avoid instance/static properties
4. **One container per test** - Fresh state for each test

### Test Organization Tips

1. **One suite per domain concept** - TaskTests, HabitTests, etc.
2. **Group related tests in nested suites** - Use nested structs for logical grouping
3. **Descriptive test names** - "testRecurrenceRuleHandlesLeapYears" not "testRule1"
4. **Use parameterized tests for edge cases** - DRY principle for variations

---

**Document Version:** 2.0
**Last Updated:** October 24, 2025
**Status:** Audited against 2025 Swift Testing & SwiftData best practices
**Next Step:** Execute Phase 1 - Complete test removal
