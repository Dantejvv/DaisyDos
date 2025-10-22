# DaisyDos Testing Migration Plan
## Swift Testing + SwiftData - Struct + Local Container Pattern
**Date:** October 21, 2025
**Status:** Ready for Implementation
**Pattern:** Option 2 (Struct + Local Container)

---

## Executive Summary

### Decision
**Use Option 2: Struct + Local Container Pattern** for all Swift Testing test suites in DaisyDos.

### Rationale
1. **Follows Apple's recommendation:** Use structs for test suites for better concurrency safety
2. **Perfect test isolation:** Each test gets fresh container, no shared state
3. **Fixes parallel execution failures:** Root cause addressed
4. **Future-proof:** Aligns with Swift 6 strict concurrency

### Trade-offs Accepted
- ⚠️ **Performance overhead:** ~150ms per test (vs <1ms with shared container)
- ✅ **Acceptable because:** 26 tests = ~4 seconds total, perfect isolation worth the cost
- ✅ **Prevents:** Flaky tests, shared state pollution, debugging nightmares

---

## Root Cause Analysis

### The Problem We Solved

**Symptom:**
```
Test case 'TaskActorTests/createTaskWithActor()' failed (0.000 seconds)
Test case 'TaskActorTests/createTaskWithDueDate()' failed (0.000 seconds)
...
[All tests fail at 0.000s when run as suite]
```

**Root Cause (Verified Against Apple Docs):**

Swift Testing creates a **fresh suite instance for EVERY test**:

```swift
@Suite struct FoodTruckTests {
  @Test func foodTruckExists() { ... }
}

// Swift Testing does this:
let instance = FoodTruckTests()  // NEW INSTANCE PER TEST
instance.foodTruckExists()
```

**Our Old Pattern (BROKEN):**
```swift
@Suite(.serialized)
@MainActor
final class TaskActorTests {
    private var container: ModelContainer!  // ❌ Instance property

    init() throws {  // ❌ Called for EACH test
        container = try TestHelpers.createActorTestContainer()
    }
}
```

**What Happened:**
1. Test 1 starts → Creates `TaskActorTests` instance #1 → `init()` → Creates ModelContainer #1
2. Test 2 starts → Creates `TaskActorTests` instance #2 → `init()` → Creates ModelContainer #2
3. ... (12 times)
4. 12 containers created rapidly → iOS Simulator + SwiftData fails → 0.000s failures

**Why `.serialized` Didn't Help:**
- `.serialized` controls TEST EXECUTION order
- Does NOT control INSTANCE CREATION
- Swift Testing still creates fresh instances per test

**iOS 18 Complication:**
> "ModelContext used to have a strong reference to its container, but in iOS 18 it has become a weak reference."

This meant containers could be deallocated unexpectedly, making the problem worse.

---

## The Solution: Option 2 Pattern

### Pattern Specification

**Struct + Local Container:**
```swift
@Suite("Feature Tests")
struct FeatureTests {
    // NO @MainActor
    // NO instance properties
    // NO init()
    // NO .serialized trait

    @Test("Test description")
    func testSomething() async throws {
        // Create fresh container IN test body
        let container = try TestHelpers.createActorTestContainer()
        let actor = FeatureDataActor(modelContainer: container)

        // Test logic...
        let result = try await actor.doSomething()

        // Assertions
        #expect(result.isValid)

        // No cleanup needed - struct deallocation handles it
    }
}
```

### Why This Works

**1. Struct Value Semantics**
- Each test gets an INDEPENDENT copy of the suite
- No shared state between tests
- Thread-safe by design

**2. Local Container Creation**
- Container created AFTER instance creation
- Created in test body, not in `init()`
- Swift Testing can't create containers prematurely
- Each test fully isolated

**3. Automatic Cleanup**
- Struct deallocated when test completes
- Local container automatically released
- No manual cleanup needed

**4. Follows Apple's Guidance**
> "It's recommended to use structs or actors for suites instead of classes for better concurrency safety."

---

## Current State Assessment

### Phase 1: ModelActor Infrastructure (COMPLETE ✅)

**What Exists:**
- `/DaisyDos/Features/Tasks/Services/TaskDataActor.swift` (280 lines)
- `/DaisyDosTests/Unit/Actors/TaskActorTests.swift` (13 tests)
- `/DaisyDosTests/Helpers/TestHelpers.swift` (createActorTestContainer method)

**TaskDataActor Implementation:**
```swift
@ModelActor
actor TaskDataActor {
    // CRUD Operations
    func createTask(...) throws -> Task
    func updateTask(...) throws
    func deleteTask(_ task: Task) throws
    func toggleTaskCompletion(_ task: Task) throws
    func duplicateTask(_ task: Task) throws -> Task

    // Query Operations
    func fetchAllTasks() throws -> [Task]
    func fetchTask(by id: UUID) throws -> Task?
    func taskCount() throws -> Int
    func fetchPendingTasks() throws -> [Task]
    func fetchCompletedTasks() throws -> [Task]
    func fetchOverdueTasks() throws -> [Task]
    func fetchTasksDueToday() throws -> [Task]

    // Tag Operations
    func addTag(_ tag: Tag, to task: Task) throws -> Bool
    func removeTag(_ tag: Tag, from task: Task) throws
}
```

**Status:** ✅ All methods implemented, documented, production-ready

**TestHelpers Addition:**
```swift
static func createActorTestContainer() throws -> ModelContainer {
    let schema = Schema([
        Task.self, Tag.self, TaskAttachment.self,
        Habit.self, HabitCompletion.self, HabitStreak.self, HabitSkip.self,
        TaskLogEntry.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}
```

### Current Test Inventory

**Tests Needing Migration:**

| Test Suite | Tests | Current Pattern | Status |
|------------|-------|-----------------|--------|
| TaskActorTests | 13 | Class + stored container | ❌ Fails as suite |
| DaisyDosArchitectureTests | 13 | Class + shared container | ⚠️ Works with .serialized |
| **Total** | **26** | | |

**Individual Test Status:**
- ✅ All 26 tests PASS when run individually
- ❌ TaskActorTests FAILS when run as suite (0.000s)
- ⚠️ DaisyDosArchitectureTests requires `.serialized` (slow)

---

## Migration Strategy

### Phase 1: Fix TaskActorTests (IMMEDIATE PRIORITY)

**Current (BROKEN):**
```swift
@Suite("Task Data Actor - CRUD Operations", .serialized)
@MainActor
final class TaskActorTests {
    private var container: ModelContainer!

    init() throws {
        container = try TestHelpers.createActorTestContainer()
    }

    @Test("Create task with actor isolation")
    func createTaskWithActor() async throws {
        let actor = TaskDataActor(modelContainer: container)
        // ...
    }
}
```

**After Migration (WORKING):**
```swift
@Suite("Task Data Actor - CRUD Operations")
struct TaskActorTests {
    @Test("Create task with actor isolation")
    func createTaskWithActor() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)
        // ...
    }
}
```

**Changes Required:**
1. ✅ Change `final class` → `struct`
2. ✅ Remove `@MainActor`
3. ✅ Remove `.serialized` trait
4. ✅ Delete `init()` method
5. ✅ Delete `private var container` property
6. ✅ Add container creation to EACH of 13 test functions

**Estimated Time:** 15 minutes
**Expected Result:** All 13 tests pass as suite in ~2 seconds

---

### Phase 2: Migrate DaisyDosArchitectureTests

**Current (SLOW):**
```swift
@Suite(.serialized)
@MainActor
final class DaisyDosTests {
    let container: ModelContainer

    init() throws {
        container = try TestHelpers.sharedContainer
    }

    @Test("TaskManager @Observable reactivity")
    func testTaskManagerObservablePattern() async throws {
        let taskManager = TaskManager(modelContext: container.mainContext)
        // ...
    }
}
```

**After Migration (FAST):**
```swift
@Suite
struct DaisyDosTests {
    @Test("TaskManager @Observable reactivity")
    func testTaskManagerObservablePattern() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let taskManager = TaskManager(modelContext: container.mainContext)
        // ...
    }
}
```

**Changes Required:**
1. ✅ Change `final class` → `struct`
2. ✅ Remove `@MainActor`
3. ✅ Remove `.serialized` trait
4. ✅ Delete `init()` method
5. ✅ Delete `let container` property
6. ✅ Replace `TestHelpers.sharedContainer` → `createActorTestContainer()` in 13 tests

**Estimated Time:** 20 minutes
**Expected Result:** All 13 tests pass as suite in ~2 seconds

---

### Phase 3: Establish Pattern for Future Tests

**Update CLAUDE.md:**
```markdown
## Testing Best Practices

### Swift Testing Pattern (Required)

**Always use Struct + Local Container pattern:**

\`\`\`swift
import Testing
import SwiftData
@testable import DaisyDos

@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testFeature() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = FeatureDataActor(modelContainer: container)

        // Test logic
    }
}
\`\`\`

**DO NOT:**
- ❌ Use `final class` for test suites
- ❌ Store containers in instance properties
- ❌ Use `init()` for setup
- ❌ Use `.serialized` trait
- ❌ Use `@MainActor` on test suite
- ❌ Share containers across tests
```

**Create Test Template File:**
`/DaisyDosTests/Templates/TestTemplate.swift`

**Estimated Time:** 10 minutes

---

## Implementation Guide

### Step-by-Step Conversion Process

**For Each Test Suite:**

1. **Backup Current File**
   ```bash
   git diff DaisyDosTests/Unit/Actors/TaskActorTests.swift
   ```

2. **Change Class to Struct**
   ```swift
   // Before
   @Suite("Tests", .serialized)
   @MainActor
   final class MyTests {

   // After
   @Suite("Tests")
   struct MyTests {
   ```

3. **Remove Instance State**
   ```swift
   // Delete these lines:
   private var container: ModelContainer!
   let container: ModelContainer

   init() throws {
       container = try TestHelpers.createActorTestContainer()
   }
   ```

4. **Add Container to Each Test**
   ```swift
   @Test func myTest() async throws {
       // Add this as first line:
       let container = try TestHelpers.createActorTestContainer()

       // Rest of test...
   }
   ```

5. **Update Actor/Manager Creation**
   ```swift
   // If test used:
   let actor = TaskDataActor(modelContainer: container)  // ✅ No change needed

   // If test used shared container:
   let taskManager = TaskManager(modelContext: container.mainContext)  // ✅ No change needed
   ```

6. **Run Tests**
   ```bash
   xcodebuild test -only-testing:DaisyDosTests/MyTests
   ```

### Common Patterns

**Pattern 1: Actor-Based Test**
```swift
@Test("Test with actor")
func testWithActor() async throws {
    let container = try TestHelpers.createActorTestContainer()
    let actor = TaskDataActor(modelContainer: container)

    let result = try await actor.createTask(title: "Test")
    #expect(result.title == "Test")
}
```

**Pattern 2: Manager-Based Test**
```swift
@Test("Test with manager")
func testWithManager() async throws {
    let container = try TestHelpers.createActorTestContainer()
    let taskManager = TaskManager(modelContext: container.mainContext)

    let result = taskManager.createTask(title: "Test")
    #expect(result != nil)
}
```

**Pattern 3: Multiple Operations**
```swift
@Test("Complex test")
func complexTest() async throws {
    let container = try TestHelpers.createActorTestContainer()
    let actor = TaskDataActor(modelContainer: container)

    // Create
    let task = try await actor.createTask(title: "Test")

    // Update
    try await actor.updateTask(task, title: "Updated")

    // Verify
    let fetched = try await actor.fetchTask(by: task.id)
    #expect(fetched?.title == "Updated")

    // Delete
    try await actor.deleteTask(task)
    #expect(try await actor.taskCount() == 0)
}
```

---

## Performance Expectations

### Measurements

| Metric | Before (Shared) | After (Local) | Change |
|--------|----------------|---------------|--------|
| Container creation | 1× (~200ms) | 26× (~150ms each) | +3.7s |
| Per-test overhead | <1ms | ~150ms | +150ms |
| Total suite time | ~500ms | ~4.0s | +3.5s |
| Memory usage | ~50MB | ~50MB | No change* |

*In-memory containers are lightweight; OS reclaims memory between tests

### Why Performance Cost is Acceptable

1. **Absolute Time Still Fast**
   - 4 seconds for 26 tests is excellent
   - Developers won't notice the difference
   - CI/CD impact minimal (~4s per run)

2. **Perfect Isolation Worth It**
   - No flaky tests from shared state
   - No debugging test interdependencies
   - No mysterious failures

3. **Aligns with Apple's Recommendation**
   - Struct pattern is the "right way"
   - Future-proof for Swift 6
   - Better concurrency safety

4. **Can Optimize Later If Needed**
   - Could group related tests if suite grows to 100+
   - Could use static container in specific cases
   - Current scale doesn't warrant optimization

---

## What We're NOT Doing

### Abandoned from Old ModelActor Refactoring Plan

**Phase 3-5 of old plan (CANCELLED):**
- ❌ Refactoring TaskManager to delegate to TaskDataActor
- ❌ Updating DaisyDosApp to pass ModelContainer
- ❌ Changing UI button actions to async/await
- ❌ Creating HabitDataActor, TagDataActor, LogbookDataActor
- ❌ Removing synchronous CRUD methods from Managers

**Why These Are Cancelled:**
1. **Problem was test execution, not production code**
   - Managers work perfectly with mainContext
   - No threading issues in production
   - UI doesn't need async/await for current scale

2. **Scope creep**
   - Original goal: Fix parallel test execution
   - Refactoring managers is different concern
   - Can revisit if production needs change

3. **Option 2 solves test problem without production changes**
   - Struct pattern fixes test isolation
   - No need to touch production code
   - Minimal disruption, maximum benefit

### What We're Keeping

**From Phase 1 (KEEP):**
- ✅ TaskDataActor.swift - Excellent implementation, may use in future
- ✅ TestHelpers.createActorTestContainer() - Essential for Option 2
- ✅ ModelActor pattern knowledge - Valuable for future features

**Rationale:**
- TaskDataActor is production-ready if we ever need it
- Demonstrates correct ModelActor pattern
- Minimal maintenance burden
- Future-proofs architecture

---

## Testing Best Practices

### Standard Pattern (Required for All Tests)

```swift
import Testing
import SwiftData
@testable import DaisyDos

@Suite("Feature Name Tests")
struct FeatureTests {

    @Test("Descriptive test name")
    func testFeature() async throws {
        // 1. Create isolated container
        let container = try TestHelpers.createActorTestContainer()

        // 2. Create actor or manager
        let actor = FeatureDataActor(modelContainer: container)
        // OR
        let manager = FeatureManager(modelContext: container.mainContext)

        // 3. Perform operations
        let result = try await actor.performOperation()

        // 4. Assert expectations
        #expect(result.isValid)
        #expect(result.count == 1)

        // 5. No cleanup needed (automatic via struct deallocation)
    }

    @Test("Another test")
    func testAnotherFeature() async throws {
        // Each test gets fresh container
        let container = try TestHelpers.createActorTestContainer()
        // ...
    }
}
```

### Anti-Patterns (DO NOT DO)

**❌ Using Class:**
```swift
// WRONG - Don't use class
@Suite
final class FeatureTests {  // ❌ Use struct instead
    // ...
}
```

**❌ Storing Container:**
```swift
// WRONG - Don't store container
@Suite
struct FeatureTests {
    let container: ModelContainer  // ❌ Don't store state

    init() throws {  // ❌ Don't use init
        container = try TestHelpers.createActorTestContainer()
    }
}
```

**❌ Using .serialized:**
```swift
// WRONG - Don't use .serialized
@Suite(.serialized)  // ❌ Not needed with Option 2
struct FeatureTests { }
```

**❌ Using @MainActor on Suite:**
```swift
// WRONG - Don't use @MainActor on suite
@Suite
@MainActor  // ❌ Let ModelActor handle isolation
struct FeatureTests { }
```

**❌ Sharing Containers:**
```swift
// WRONG - Don't share containers
@Suite
struct FeatureTests {
    static let sharedContainer = ...  // ❌ No sharing

    @Test func test1() async throws {
        let actor = MyActor(modelContainer: Self.sharedContainer)  // ❌
    }
}
```

### When to Use UUIDs

**Good Practice:**
```swift
@Test("Create unique tasks")
func testCreateTasks() async throws {
    let container = try TestHelpers.createActorTestContainer()
    let actor = TaskDataActor(modelContainer: container)

    // Use UUIDs for unique test data
    let task1 = try await actor.createTask(title: "Test-\(UUID())")
    let task2 = try await actor.createTask(title: "Test-\(UUID())")

    #expect(task1.id != task2.id)
}
```

**Why:** Even though containers are isolated, using UUIDs makes tests more robust and prevents any potential edge cases.

---

## Verification & Testing

### Running Tests

**Individual Test Suite:**
```bash
# Run TaskActorTests
xcodebuild test -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/TaskActorTests
```

**All Tests:**
```bash
# Run all DaisyDos tests
xcodebuild test -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests
```

**Specific Test:**
```bash
# Run single test
xcodebuild test -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/TaskActorTests/createTaskWithActor
```

### Expected Results

**After Phase 1 (TaskActorTests Migration):**
```
Test Suite 'TaskActorTests' started
Test case 'TaskActorTests/createTaskWithActor()' passed (0.180 seconds)
Test case 'TaskActorTests/createTaskWithDueDate()' passed (0.165 seconds)
...
Test Suite 'TaskActorTests' passed (2.1 seconds)
  - 13 tests passed
  - 0 tests failed
```

**Key Indicators of Success:**
- ✅ Tests complete in 2-3 seconds (not 0.000s)
- ✅ All tests show "passed" status
- ✅ No "Clone 1" appearing multiple times
- ✅ No threading warnings/errors

**After Phase 2 (All Tests Migrated):**
```
Test Suite 'DaisyDosTests' started
  - TaskActorTests: 13 passed
  - DaisyDosArchitectureTests: 13 passed
Total: 26 passed, 0 failed (4.2 seconds)
```

### Debugging Failed Tests

**If tests still fail after migration:**

1. **Check Pattern Compliance**
   ```swift
   // Verify:
   // 1. Using struct (not class)
   @Suite struct MyTests {  // ✅

   // 2. No instance properties
   // ❌ let container: ModelContainer

   // 3. No init()
   // ❌ init() throws { }

   // 4. Container in test body
   @Test func test() async throws {
       let container = try TestHelpers.createActorTestContainer()  // ✅
   }
   ```

2. **Run Individual Test**
   ```bash
   xcodebuild test -only-testing:DaisyDosTests/MyTests/failingTest
   ```

3. **Check Error Messages**
   - Look for "failed to find active container" → Container deallocated
   - Look for "0.000 seconds" → Instance creation issue
   - Look for threading errors → Incorrect actor usage

4. **Verify Schema**
   ```swift
   // Ensure createActorTestContainer has all models:
   Schema([
       Task.self,
       Tag.self,
       TaskAttachment.self,
       Habit.self,
       HabitCompletion.self,
       HabitStreak.self,
       HabitSkip.self,
       TaskLogEntry.self
   ])
   ```

---

## Reference Documentation

### Apple's Official Recommendations

**1. Struct for Test Suites**
> "It's recommended to use structs or actors for suites instead of classes for better concurrency safety."

**Context:** Apple's migration guide from XCTest to Swift Testing

**2. Instance Creation Behavior**
> "Illustrates how the testing library handles instance methods within a `@Suite` type by creating an instance and calling the method."

```swift
@Suite struct FoodTruckTests {
  @Test func foodTruckExists() { ... }
}

// Equivalent to:
let instance = FoodTruckTests()
instance.foodTruckExists()
```

**3. Setup/Teardown Pattern**
```swift
// Apple's example:
struct FoodTruckTests {
  var batteryLevel: NSNumber

  init() async throws {
    batteryLevel = 100  // Setup per instance
  }
}
```

**Note:** Option 2 avoids this pattern by not using instance properties.

### What Apple Does NOT Address

Apple's documentation is **silent on:**
- ❌ Whether to create fresh databases per test
- ❌ Whether to share expensive resources like ModelContainer
- ❌ Performance vs isolation trade-offs
- ❌ SwiftData-specific patterns

**This is why we had to decide:** Option 2 interprets Apple's struct recommendation while making our own choice about container sharing.

### Swift Testing Instance Lifecycle

**Key Behavior:**
- Swift Testing creates a NEW suite instance for EVERY test
- This is by design for isolation
- Happens even with `.serialized` trait
- Struct provides value semantics on top of this

**Implications:**
- Instance properties get fresh values per test (good for isolation)
- Expensive initialization in `init()` runs per test (bad for performance)
- Static properties shared across all instances (can be good or bad)
- Local variables in test body created/destroyed per test (perfect for Option 2)

---

## Migration Checklist

### Pre-Migration

- [ ] Read and understand this entire document
- [ ] Ensure Xcode project compiles without errors
- [ ] Run existing tests to establish baseline
- [ ] Commit current state to git: `git add . && git commit -m "Pre-migration baseline"`

### Phase 1: TaskActorTests

- [ ] Open `/DaisyDosTests/Unit/Actors/TaskActorTests.swift`
- [ ] Change `final class TaskActorTests` → `struct TaskActorTests`
- [ ] Remove `@MainActor` annotation
- [ ] Remove `.serialized` trait from `@Suite`
- [ ] Delete `private var container: ModelContainer!` property
- [ ] Delete `init() throws { }` method
- [ ] Add `let container = try TestHelpers.createActorTestContainer()` to all 13 tests
- [ ] Build project (Cmd+B) - should succeed
- [ ] Run tests: `xcodebuild test -only-testing:DaisyDosTests/TaskActorTests`
- [ ] Verify all 13 tests pass in ~2 seconds
- [ ] Commit: `git add . && git commit -m "Migrate TaskActorTests to Option 2 pattern"`

### Phase 2: DaisyDosArchitectureTests

- [ ] Open `/DaisyDosTests/Unit/DaisyDosArchitectureTests.swift`
- [ ] Change `final class DaisyDosTests` → `struct DaisyDosTests`
- [ ] Remove `@MainActor` annotation
- [ ] Remove `.serialized` trait from `@Suite`
- [ ] Delete `let container: ModelContainer` property
- [ ] Delete `init() throws { container = try TestHelpers.sharedContainer }` method
- [ ] Add `let container = try TestHelpers.createActorTestContainer()` to all 13 tests
- [ ] Build project (Cmd+B) - should succeed
- [ ] Run tests: `xcodebuild test -only-testing:DaisyDosTests/DaisyDosTests`
- [ ] Verify all 13 tests pass in ~2 seconds
- [ ] Commit: `git add . && git commit -m "Migrate DaisyDosArchitectureTests to Option 2 pattern"`

### Phase 3: Documentation

- [ ] Update `/CLAUDE.md` with Option 2 pattern under Testing section
- [ ] Create test template file (optional)
- [ ] Run full test suite: `xcodebuild test -only-testing:DaisyDosTests`
- [ ] Verify all 26 tests pass in ~4 seconds
- [ ] Commit: `git add . && git commit -m "Complete testing migration to Option 2 pattern"`

### Validation

- [ ] All tests pass as suite (not just individually)
- [ ] No `.serialized` traits in test code
- [ ] All test suites use `struct`
- [ ] No `init()` methods in test suites
- [ ] No stored container properties in test suites
- [ ] Test execution time acceptable (~4 seconds for 26 tests)
- [ ] No threading warnings or errors

---

## Future Test Development

### For ALL New Test Suites

**Always use this template:**

```swift
import Testing
import SwiftData
@testable import DaisyDos

/// Tests for [Feature Name]
/// Validates [what this test suite covers]
@Suite("[Feature] Tests")
struct FeatureTests {

    /// Test [specific behavior]
    @Test("Descriptive test name")
    func testSpecificBehavior() async throws {
        // 1. Create isolated container
        let container = try TestHelpers.createActorTestContainer()

        // 2. Create dependencies
        let actor = FeatureDataActor(modelContainer: container)
        // OR
        let manager = FeatureManager(modelContext: container.mainContext)

        // 3. Execute operation
        let result = try await actor.performOperation()

        // 4. Verify expectations
        #expect(result.isValid)
        #expect(result.propertyValue == expectedValue)
    }

    /// Test [another behavior]
    @Test("Another test")
    func testAnotherBehavior() async throws {
        let container = try TestHelpers.createActorTestContainer()
        // ...
    }
}
```

### Adding New Actors

**If you create a new ModelActor:**

1. **Create the Actor**
   ```swift
   // /DaisyDos/Features/NewFeature/Services/NewFeatureDataActor.swift
   import SwiftData

   @ModelActor
   actor NewFeatureDataActor {
       func performOperation() throws -> Result { }
   }
   ```

2. **Create Tests Using Option 2 Pattern**
   ```swift
   // /DaisyDosTests/Unit/Actors/NewFeatureActorTests.swift
   @Suite("New Feature Data Actor Tests")
   struct NewFeatureActorTests {
       @Test("Test operation")
       func testOperation() async throws {
           let container = try TestHelpers.createActorTestContainer()
           let actor = NewFeatureDataActor(modelContainer: container)
           // ...
       }
   }
   ```

3. **No Changes Needed to Production Code**
   - Managers can continue using mainContext
   - UI can continue using synchronous manager methods
   - Actors are for testing or future features

---

## Troubleshooting

### Common Issues

**Issue: Tests still fail at 0.000s**

**Check:**
1. Did you change `class` → `struct`?
2. Did you remove `init()` method?
3. Did you remove stored `container` property?
4. Did you add container creation to EACH test?

**Solution:**
```swift
// Should look like:
@Suite("Tests")  // No .serialized
struct MyTests {  // struct, not class
    // No init()
    // No properties

    @Test func test() async throws {
        let container = try TestHelpers.createActorTestContainer()  // Must be here
        // ...
    }
}
```

---

**Issue: "Failed to find active container"**

**Cause:** Container deallocated before use

**Check:**
1. Container created at start of test function (not after async operations)
2. Container kept in scope for entire test
3. Not passing container to async closure that outlives test

**Solution:**
```swift
@Test func test() async throws {
    let container = try TestHelpers.createActorTestContainer()
    let actor = TaskDataActor(modelContainer: container)

    // Container stays in scope until test ends
    try await actor.createTask(title: "Test")

    // Don't do this:
    // Task.detached {
    //     try await actor.createTask(title: "Test")  // ❌ Container might be gone
    // }
}
```

---

**Issue: Tests are slow (>10 seconds for 26 tests)**

**Check:**
1. Are you creating containers correctly? (should be ~150ms each)
2. Is simulator running slow? (restart simulator)
3. Are tests doing expensive operations?

**Expected:** 26 tests × 150ms = ~4 seconds

**If much slower:**
- Profile with Instruments
- Check for blocking operations
- Verify simulator performance

---

## Summary

### What Changed

**Before:**
- Used `final class` for test suites
- Stored containers in instance properties or used shared container
- Used `.serialized` trait
- Tests failed when run as suite (0.000s)

**After:**
- Use `struct` for test suites
- Create local container in each test body
- No `.serialized` trait needed
- Tests pass as suite (~4 seconds)

### Key Principles

1. **Always use `struct`** for test suite types
2. **Never store containers** in instance properties
3. **Create containers locally** in each test function
4. **No `init()` methods** in test suites
5. **No `.serialized` trait** needed
6. **Let ModelActor handle isolation** (no `@MainActor` on suite)

### Success Metrics

- ✅ All 26 tests pass as suite
- ✅ Test execution time ~4 seconds
- ✅ No 0.000s failures
- ✅ No threading errors
- ✅ Perfect test isolation
- ✅ Future-proof for Swift 6

---

**Document Version:** 1.0
**Last Updated:** October 21, 2025
**Status:** Ready for implementation
**Next Step:** Execute Phase 1 - Migrate TaskActorTests
