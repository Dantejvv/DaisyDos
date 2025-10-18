# DaisyDos Testing Architecture Audit Report

**Generated:** October 17, 2025
**Status:** Comprehensive Analysis Complete

---

## Executive Summary

This report provides a complete audit of DaisyDos's current testing infrastructure, identifies architectural issues, and proposes a modern testing strategy aligned with Apple's Swift Testing best practices.

### Key Findings

🔴 **CRITICAL ISSUES:**
- Test files incorrectly placed in main app bundle (`DaisyDos/Features/*/Testing/`)
- Interactive test views mixed with unit tests (`DaisyDosTests/InteractiveTestViews/`)
- Mixed testing frameworks (XCTest and Swift Testing)
- No UI automation tests in `DaisyDosUITests/`

✅ **STRENGTHS:**
- Comprehensive unit test coverage for Task due dates (`TaskDueDateTests.swift`)
- Strong architectural tests (`DaisyDosTests.swift`)
- SwiftData model business logic validated

---

## Current Testing Structure

### 1. Files in WRONG Locations ❌

**Main App Bundle** (`DaisyDos/` - SHOULD NOT CONTAIN TESTS):
```
❌ DaisyDos/Features/Tasks/Testing/
   ├── DueDateTestSuite.swift         # @Observable test runner (DEBUG only)
   ├── DueDateTestView.swift          # Interactive UI test view
   └── TaskDescriptionScrollTest.swift # Interactive UI test view

❌ DaisyDos/Features/Logbook/Testing/
   └── LogbookTestSuite.swift         # @Observable test runner (DEBUG only)
```

**Purpose:** These are interactive manual testing UIs, NOT automated tests.
**Issue:** Bloats production app bundle, wrong architecture pattern.

### 2. Files in QUESTIONABLE Locations ⚠️

**DaisyDosTests/InteractiveTestViews/** (Unit test target):
```
⚠️  AccessibilityTestView.swift     # Interactive UI, not unit test
⚠️  ComponentTestView.swift         # Interactive UI, not unit test
⚠️  DesignSystemTestView.swift      # Interactive UI, not unit test
⚠️  DynamicTypeTestView.swift       # Interactive UI, not unit test
⚠️  ErrorHandlingTestView.swift     # Interactive UI, not unit test
⚠️  ManagerTestView.swift           # Interactive UI, not unit test
⚠️  ModelTestView.swift             # Interactive UI, not unit test
⚠️  PerformanceTestView.swift       # Interactive UI, not unit test
⚠️  TouchTargetAuditView.swift      # Interactive UI, not unit test
```

**Purpose:** Manual testing/development tools, SwiftUI previews.
**Issue:** These are NOT XCTest or Swift Testing unit tests - they're development utilities.

### 3. Files in CORRECT Locations ✅

**DaisyDosTests/** (Unit test target):
```
✅ DaisyDosTests.swift           # Swift Testing (@Test) - Architecture validation
✅ TaskDueDateTests.swift        # XCTest - Comprehensive due date tests
✅ MockData/                     # Test fixtures (empty currently)
✅ TestHelpers/                  # Test utilities (empty currently)
```

**DaisyDosUITests/** (UI test target):
```
⚠️  DaisyDosUITests.swift            # Skeleton only, no real tests
⚠️  DaisyDosUITestsLaunchTests.swift # Performance test only
```

---

## Testing Framework Analysis

### Current Usage

**Swift Testing (@Test macro):**
- `DaisyDosTests.swift` - Modern approach ✅
- Uses `#expect` and `#require` macros
- Struct-based test suites
- Async/await support

**XCTest (XCTestCase):**
- `TaskDueDateTests.swift` - Traditional approach ✅
- Uses `XCTAssert*` functions
- Class-based test suites
- Well-structured, comprehensive

**Custom Test Runners (@Observable):**
- `DueDateTestSuite.swift` - ❌ Anti-pattern
- `LogbookTestSuite.swift` - ❌ Anti-pattern
- Manual test execution, print-based output
- Not integrated with Xcode Test Navigator

### Recommended Framework: Swift Testing

**Why Swift Testing over XCTest:**

| Feature | Swift Testing | XCTest |
|---------|---------------|--------|
| **Modern Swift** | ✅ Structs, actors, modern syntax | ❌ Classes only, ObjC roots |
| **Concurrency** | ✅ Native async/await | ⚠️ Limited support |
| **Assertions** | ✅ `#expect`, `#require` | ❌ `XCTAssert*` |
| **Parameterized Tests** | ✅ Built-in `@Test(arguments:)` | ❌ Manual loops |
| **Test Organization** | ✅ `@Suite` trait-based | ❌ Class hierarchy |
| **Performance** | ✅ Parallel by default | ⚠️ Serial unless configured |
| **Error Messages** | ✅ Rich, actionable | ❌ Basic |

---

## What is Currently Tested ✅

### Well-Tested Areas

**1. Task Due Date Functionality** (`TaskDueDateTests.swift` - 613 lines):
- ✅ Task creation with/without due dates
- ✅ Past due date handling
- ✅ Overdue status detection
- ✅ Due today/soon detection
- ✅ Display text formatting
- ✅ Due date updates and removal
- ✅ Subtask due date inheritance
- ✅ Recurrence calculations
- ✅ TaskManager filtering (overdue, today, soon)
- ✅ Enhanced today's tasks logic
- ✅ Due date sorting
- ✅ Duplicate task due date handling

**2. Architecture Patterns** (`DaisyDosTests.swift` - 454 lines):
- ✅ @Observable manager pattern
- ✅ TaskManager reactivity
- ✅ HabitManager streak calculations
- ✅ TagManager constraint validation
- ✅ Task model business logic
- ✅ Habit model business logic
- ✅ Tag system limits
- ✅ Error transformation system
- ✅ DaisyDosError user messages
- ✅ Environment injection
- ✅ SwiftData schema integration
- ✅ Performance baselines
- ✅ Manager error handling

**Test Coverage Estimate:** ~35-40% of core business logic

---

## What is NOT Tested ❌

### Critical Gaps

**1. UI/UX Flows (0% coverage):**
- ❌ Task creation flow end-to-end
- ❌ Habit completion workflow
- ❌ Tag assignment UI
- ❌ Navigation between tabs
- ❌ Subtask management UI
- ❌ Attachment picker and preview
- ❌ Recurrence picker UI
- ❌ Settings changes
- ❌ Logbook filtering and search

**2. Features Without Tests:**
- ❌ **Subtasks:** Creation, ordering, deletion, completion
- ❌ **Attachments:** File management, size limits, gallery
- ❌ **Recurrence:** UI integration, recurring instance generation
- ❌ **Tag System:** Creation, editing, deletion, assignment UI
- ❌ **Habit Features:**
  - Skip functionality
  - Notification scheduling
  - Analytics calculations
  - Progress charts
  - Heatmap visualization
  - Streak recovery
- ❌ **Logbook:**
  - Archival system
  - History tracking
  - Search functionality
  - Task recovery
- ❌ **Today View:** Smart task aggregation
- ❌ **Settings:** All preference management

**3. Non-Functional Requirements:**
- ❌ Accessibility (VoiceOver, Dynamic Type)
- ❌ Performance under load (1000+ tasks/habits)
- ❌ Memory leaks and retain cycles
- ❌ Data migration scenarios
- ❌ Edge cases (low battery, disk space, network issues)

**4. Integration Tests:**
- ❌ Cross-manager workflows
- ❌ Tag assignment across tasks and habits
- ❌ Completion state synchronization
- ❌ Search across multiple data types

---

## Proposed Testing Architecture

### Directory Structure

```
DaisyDos/
├── Features/
│   ├── Tasks/           # ❌ REMOVE Testing/ subdirectory
│   ├── Habits/          # ❌ REMOVE Testing/ subdirectory
│   └── Logbook/         # ❌ REMOVE Testing/ subdirectory
│
DaisyDosTests/ (Unit & Integration Tests)
├── Unit/
│   ├── Models/
│   │   ├── TaskModelTests.swift
│   │   ├── HabitModelTests.swift
│   │   ├── TagModelTests.swift
│   │   ├── RecurrenceRuleTests.swift
│   │   └── AttachmentModelTests.swift
│   ├── Managers/
│   │   ├── TaskManagerTests.swift
│   │   ├── HabitManagerTests.swift
│   │   ├── TagManagerTests.swift
│   │   ├── LogbookManagerTests.swift
│   │   └── NavigationManagerTests.swift
│   ├── Services/
│   │   ├── HabitNotificationManagerTests.swift
│   │   └── HabitAnalyticsTests.swift
│   └── ErrorHandling/
│       ├── ErrorTransformerTests.swift
│       └── DaisyDosErrorTests.swift
│
├── Integration/
│   ├── TaskSubtaskIntegrationTests.swift
│   ├── TaskAttachmentIntegrationTests.swift
│   ├── HabitStreakIntegrationTests.swift
│   ├── TagAssignmentIntegrationTests.swift
│   └── LogbookArchivalIntegrationTests.swift
│
├── Helpers/
│   ├── TestFixtures.swift
│   ├── MockData.swift
│   └── XCTestExtensions.swift
│
└── Resources/
    └── TestAssets.xcassets

DaisyDosUITests/ (UI Automation Tests)
├── Flows/
│   ├── TaskCreationFlowTests.swift
│   ├── HabitCompletionFlowTests.swift
│   ├── TagManagementFlowTests.swift
│   └── LogbookNavigationTests.swift
│
├── Accessibility/
│   ├── VoiceOverTests.swift
│   ├── DynamicTypeTests.swift
│   └── ColorContrastTests.swift
│
├── Pages/
│   ├── TasksViewPage.swift
│   ├── HabitsViewPage.swift
│   ├── TodayViewPage.swift
│   └── SettingsViewPage.swift
│
└── Helpers/
    ├── UITestExtensions.swift
    └── PageObjectBase.swift

DaisyDos/ (Development Utilities - #if DEBUG only)
└── DeveloperTools/
    ├── InteractiveTesting/
    │   ├── ComponentGalleryView.swift
    │   ├── DesignSystemPreview.swift
    │   ├── AccessibilityAuditView.swift
    │   └── PerformanceMonitorView.swift
    └── TestData/
        └── SampleDataGenerator.swift
```

### Testing Strategy

**1. Unit Tests (Swift Testing preferred):**
```swift
import Testing
@testable import DaisyDos

@Suite("Task Model Business Logic")
struct TaskModelTests {

    @Test("Task completion toggles status correctly")
    func taskCompletionToggle() {
        let task = Task(title: "Test Task")
        #expect(!task.isCompleted)

        task.toggleCompletion()
        #expect(task.isCompleted)

        task.toggleCompletion()
        #expect(!task.isCompleted)
    }

    @Test("Task enforces 3-tag limit", arguments: [1, 2, 3, 4])
    func tagLimitEnforcement(tagCount: Int) {
        let task = Task(title: "Test")
        for i in 1...tagCount {
            let tag = Tag(name: "Tag \(i)")
            _ = task.addTag(tag)
        }
        #expect(task.tags.count == min(tagCount, 3))
    }
}
```

**2. Integration Tests (Swift Testing):**
```swift
@Suite("Subtask Integration")
@MainActor
struct SubtaskIntegrationTests {
    var container: ModelContainer!
    var taskManager: TaskManager!

    init() async throws {
        container = try ModelContainer(
            for: Task.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        taskManager = TaskManager(modelContext: container.mainContext)
    }

    @Test("Create subtask inherits parent tags")
    func subtaskInheritsParentTags() async throws {
        let parentResult = taskManager.createTask(title: "Parent")
        guard case .success(let parent) = parentResult else {
            Issue.record("Parent creation failed")
            return
        }

        let tag = Tag(name: "Work")
        _ = parent.addTag(tag)

        let subtask = parent.createSubtask(title: "Subtask")
        #expect(subtask.tags.contains(tag))
    }
}
```

**3. UI Tests (XCUITest with Page Object pattern):**
```swift
import XCTest

final class TaskCreationFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    func testCreateTaskWithAllFields() {
        let tasksTab = app.tabBars.buttons["Tasks"]
        tasksTab.tap()

        let addButton = app.navigationBars.buttons["Add"]
        addButton.tap()

        let titleField = app.textFields["Task Title"]
        titleField.tap()
        titleField.typeText("Buy groceries")

        let descriptionField = app.textViews["Description"]
        descriptionField.tap()
        descriptionField.typeText("Milk, eggs, bread")

        let priorityPicker = app.buttons["Priority: Medium"]
        priorityPicker.tap()
        app.buttons["High"].tap()

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Buy groceries"].exists)
    }
}
```

---

## Migration Plan

### Phase 1: Remove Incorrect Test Files ⚠️

**Action Items:**
1. ❌ **DELETE** `DaisyDos/Features/Tasks/Testing/` entire directory
2. ❌ **DELETE** `DaisyDos/Features/Logbook/Testing/` entire directory
3. **MOVE** Interactive test views to developer tools:
   - Move `DaisyDosTests/InteractiveTestViews/` → `DaisyDos/DeveloperTools/InteractiveTesting/`
   - Wrap in `#if DEBUG` conditionals
   - Keep for manual testing but separate from automated tests

### Phase 2: Standardize on Swift Testing

**Action Items:**
1. ✅ **KEEP** `DaisyDosTests.swift` (already Swift Testing)
2. **MIGRATE** `TaskDueDateTests.swift` from XCTest → Swift Testing
3. **CREATE** new test files using Swift Testing template

### Phase 3: Fill Testing Gaps

**Priority Order:**
1. **High Priority:** Subtasks, Attachments, Recurrence
2. **Medium Priority:** Habit analytics, Logbook archival
3. **Low Priority:** UI automation, Accessibility

### Phase 4: Establish CI/CD Integration

**Action Items:**
1. Configure Xcode Cloud or GitHub Actions
2. Run tests on every PR
3. Block merges on test failures
4. Generate code coverage reports (target: 80%+)

---

## Testing Best Practices

### DO ✅

1. **Use Swift Testing for new tests**
   - Modern, expressive, better error messages
   - Async/await support
   - Parameterized tests

2. **Follow AAA Pattern (Arrange, Act, Assert)**
   ```swift
   @Test func exampleTest() {
       // Arrange
       let task = Task(title: "Test")

       // Act
       task.toggleCompletion()

       // Assert
       #expect(task.isCompleted)
   }
   ```

3. **Use descriptive test names**
   - ✅ `@Test("Task completion toggles status correctly")`
   - ❌ `@Test func test1()`

4. **Test one thing per test**
   - Each test validates single behavior
   - Makes failures easier to diagnose

5. **Use in-memory ModelContainer for tests**
   ```swift
   let container = try ModelContainer(
       for: Task.self,
       configurations: ModelConfiguration(isStoredInMemoryOnly: true)
   )
   ```

6. **Clean up test data**
   - Use `init()` for setup
   - Use `deinit` for cleanup
   - Ensure tests are isolated

### DON'T ❌

1. **DON'T put test files in main app bundle**
   - Tests belong in `DaisyDosTests/` or `DaisyDosUITests/`

2. **DON'T use print() for test results**
   - Use framework assertions (`#expect`, `XCTAssert`)

3. **DON'T mix testing and production code**
   - Keep test utilities separate

4. **DON'T skip tests**
   - Fix or remove broken tests
   - Use `.disabled(if:)` trait if temporary skip needed

5. **DON'T test implementation details**
   - Test behavior, not internals

6. **DON'T hardcode dates**
   ```swift
   // ❌ Bad
   let dueDate = Date(timeIntervalSince1970: 1697500800)

   // ✅ Good
   let dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
   ```

---

## Running Tests

### Xcode

**Unit Tests:**
```
1. Cmd + U (Run all tests)
2. Cmd + Ctrl + U (Run tests without building)
3. Click diamond icon next to test to run single test
```

**UI Tests:**
```
1. Select DaisyDosUITests scheme
2. Cmd + U
3. Or: Test Navigator (Cmd + 6) → Right-click → Run
```

### Command Line

**All Tests:**
```bash
xcodebuild test \
  -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Unit Tests Only:**
```bash
xcodebuild test \
  -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests
```

**Specific Test:**
```bash
xcodebuild test \
  -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:DaisyDosTests/TaskModelTests/taskCompletionToggle
```

**Code Coverage:**
```bash
xcodebuild test \
  -scheme DaisyDos \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

---

## Recommendations

### Immediate Actions (This Week)

1. **Delete** test files from main app bundle
2. **Move** InteractiveTestViews to DeveloperTools
3. **Standardize** on Swift Testing for new tests
4. **Document** testing patterns in CLAUDE.md

### Short Term (This Month)

1. **Write tests** for subtasks functionality
2. **Write tests** for attachments system
3. **Migrate** TaskDueDateTests to Swift Testing
4. **Create** test helpers and fixtures

### Long Term (Next Quarter)

1. **Implement** UI automation tests
2. **Add** accessibility tests
3. **Integrate** with CI/CD pipeline
4. **Achieve** 80%+ code coverage

---

## Conclusion

DaisyDos has a solid foundation for testing but requires architectural cleanup and expanded coverage. By following this plan and adopting Swift Testing as the standard, the project will have:

✅ **Clear separation** between production code and tests
✅ **Modern testing practices** aligned with Apple's guidance
✅ **Comprehensive coverage** of all features
✅ **Automated testing** in CI/CD pipeline
✅ **Maintainable test suite** that grows with the app

**Next Step:** Review this report and approve the migration plan before proceeding with cleanup.

---

**Report prepared by:** Claude Code
**Contact:** For questions about this report, see project documentation.

---

## APPENDIX A: Detailed File Inventory

### Files to DELETE (Production App Bundle)

**Complete paths for deletion:**
```bash
# Task Testing Files
/Users/dante/Dev/DaisyDos/DaisyDos/Features/Tasks/Testing/DueDateTestSuite.swift
/Users/dante/Dev/DaisyDos/DaisyDos/Features/Tasks/Testing/DueDateTestView.swift
/Users/dante/Dev/DaisyDos/DaisyDos/Features/Tasks/Testing/TaskDescriptionScrollTest.swift

# Logbook Testing Files
/Users/dante/Dev/DaisyDos/DaisyDos/Features/Logbook/Testing/LogbookTestSuite.swift

# Delete entire directories
rm -rf /Users/dante/Dev/DaisyDos/DaisyDos/Features/Tasks/Testing
rm -rf /Users/dante/Dev/DaisyDos/DaisyDos/Features/Logbook/Testing
```

### Files to MOVE (DaisyDosTests → DeveloperTools)

**Source:** `/Users/dante/Dev/DaisyDos/DaisyDosTests/InteractiveTestViews/`
**Destination:** `/Users/dante/Dev/DaisyDos/DaisyDos/DeveloperTools/InteractiveTesting/`

**Files to move:**
```
AccessibilityTestView.swift
ComponentTestView.swift
DesignSystemTestView.swift
DynamicTypeTestView.swift
ErrorHandlingTestView.swift
ManagerTestView.swift
ModelTestView.swift
PerformanceTestView.swift
TouchTargetAuditView.swift
```

**Note:** Also remove `.tmp` files in InteractiveTestViews directory

### Files to KEEP (Already Correct)

```
✅ DaisyDosTests/DaisyDosTests.swift
✅ DaisyDosTests/TaskDueDateTests.swift
✅ DaisyDosTests/MockData/ (directory)
✅ DaisyDosTests/TestHelpers/ (directory)
✅ DaisyDosUITests/DaisyDosUITests.swift
✅ DaisyDosUITests/DaisyDosUITestsLaunchTests.swift
```

---

## APPENDIX B: Step-by-Step Migration Commands

### Phase 1: Cleanup (Safe Order)

```bash
# Step 1: Create new directory structure
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDos/DeveloperTools/InteractiveTesting
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/Models
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/Managers
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/Services
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/ErrorHandling
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Integration
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosTests/Helpers
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosUITests/Flows
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosUITests/Accessibility
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosUITests/Pages
mkdir -p /Users/dante/Dev/DaisyDos/DaisyDosUITests/Helpers

# Step 2: Move InteractiveTestViews (preserve for development)
mv /Users/dante/Dev/DaisyDos/DaisyDosTests/InteractiveTestViews/*.swift \
   /Users/dante/Dev/DaisyDos/DaisyDos/DeveloperTools/InteractiveTesting/

# Step 3: Delete .tmp files
rm -f /Users/dante/Dev/DaisyDos/DaisyDosTests/InteractiveTestViews/*.tmp

# Step 4: Delete old InteractiveTestViews directory
rm -rf /Users/dante/Dev/DaisyDos/DaisyDosTests/InteractiveTestViews

# Step 5: Delete incorrect test files from app bundle
rm -rf /Users/dante/Dev/DaisyDos/DaisyDos/Features/Tasks/Testing
rm -rf /Users/dante/Dev/DaisyDos/DaisyDos/Features/Logbook/Testing

# Step 6: Move existing test files to new structure
mv /Users/dante/Dev/DaisyDos/DaisyDosTests/DaisyDosTests.swift \
   /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/DaisyDosArchitectureTests.swift

mv /Users/dante/Dev/DaisyDos/DaisyDosTests/TaskDueDateTests.swift \
   /Users/dante/Dev/DaisyDos/DaisyDosTests/Unit/Models/TaskDueDateTests.swift
```

**⚠️ IMPORTANT:** After running these commands, you MUST update Xcode project references:
1. Open DaisyDos.xcodeproj
2. Remove red/missing file references
3. Add files back in correct locations
4. Ensure files are in correct targets (DaisyDosTests, DaisyDos with DEBUG flag)

---

## APPENDIX C: Xcode Project Configuration

### Add DeveloperTools to App Target (#if DEBUG)

**File Header Template:**
```swift
//
//  <FileName>.swift
//  DaisyDos
//
//  Development utility - only included in DEBUG builds
//

#if DEBUG
import SwiftUI
@testable import DaisyDos

// ... your code here ...

#endif
```

### Target Membership Rules

**DaisyDos Target (Production App):**
- ✅ Main app code (`DaisyDos/Features/`, `DaisyDos/Core/`)
- ✅ DeveloperTools (#if DEBUG wrapped)
- ❌ NO test files (DaisyDosTests, DaisyDosUITests)

**DaisyDosTests Target (Unit Tests):**
- ✅ All files in `DaisyDosTests/` directory
- ✅ `@testable import DaisyDos` access
- ❌ NO UI automation code

**DaisyDosUITests Target (UI Automation):**
- ✅ All files in `DaisyDosUITests/` directory
- ✅ XCUITest framework
- ❌ NO @testable import (tests through UI only)

---

## APPENDIX D: Swift Testing Migration Example

### Before (XCTest):

```swift
import XCTest
@testable import DaisyDos

final class TaskDueDateTests: XCTestCase {
    var modelContext: ModelContext!
    var taskManager: TaskManager!
    var calendar: Calendar!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let container = try ModelContainer(
            for: Task.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = container.mainContext
        taskManager = TaskManager(modelContext: modelContext)
        calendar = Calendar.current
    }

    override func tearDownWithError() throws {
        modelContext = nil
        taskManager = nil
        calendar = nil
        try super.tearDownWithError()
    }

    func testCreateTaskWithDueDate() throws {
        let dueDate = calendar.date(byAdding: .day, value: 3, to: Date())!
        let result = taskManager.createTask(
            title: "Test task",
            dueDate: dueDate
        )

        switch result {
        case .success(let task):
            XCTAssertEqual(task.title, "Test task")
            XCTAssertNotNil(task.dueDate)
            XCTAssertEqual(task.dueDate, dueDate)
        case .failure(let error):
            XCTFail("Task creation failed: \(error)")
        }
    }

    func testOverdueStatus() throws {
        let pastDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let task = Task(title: "Overdue task", dueDate: pastDate)

        XCTAssertTrue(task.hasOverdueStatus)
        XCTAssertFalse(task.isCompleted)
    }
}
```

### After (Swift Testing):

```swift
import Testing
@testable import DaisyDos

@Suite("Task Due Date Functionality")
@MainActor
struct TaskDueDateTests {
    let container: ModelContainer
    let taskManager: TaskManager
    let calendar: Calendar

    init() async throws {
        container = try ModelContainer(
            for: Task.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        taskManager = TaskManager(modelContext: container.mainContext)
        calendar = Calendar.current
    }

    @Test("Create task with due date sets date correctly")
    func createTaskWithDueDate() async throws {
        let dueDate = calendar.date(byAdding: .day, value: 3, to: Date())!
        let result = taskManager.createTask(
            title: "Test task",
            dueDate: dueDate
        )

        guard case .success(let task) = result else {
            Issue.record("Task creation failed")
            return
        }

        #expect(task.title == "Test task")
        #expect(task.dueDate != nil)
        #expect(task.dueDate == dueDate)
    }

    @Test("Overdue task status is correctly identified")
    func overdueStatus() {
        let pastDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let task = Task(title: "Overdue task", dueDate: pastDate)

        #expect(task.hasOverdueStatus)
        #expect(!task.isCompleted)
    }

    @Test(
        "Due soon detection works within 3-day window",
        arguments: [
            (days: 0, expected: true, label: "Today"),
            (days: 1, expected: true, label: "Tomorrow"),
            (days: 2, expected: true, label: "2 days"),
            (days: 3, expected: true, label: "3 days"),
            (days: 4, expected: false, label: "4 days")
        ]
    )
    func dueSoonDetection(test: (days: Int, expected: Bool, label: String)) {
        let dueDate = calendar.date(byAdding: .day, value: test.days, to: Date())!
        let task = Task(title: "Task due \(test.label)", dueDate: dueDate)

        #expect(
            task.isDueSoon == test.expected,
            "Task due \(test.label) should\(test.expected ? "" : " not") be due soon"
        )
    }
}
```

**Key Differences:**
1. `@Suite` instead of `class ... XCTestCase`
2. `struct` instead of `final class`
3. `init()` instead of `setUp()` / `setUpWithError()`
4. `deinit` instead of `tearDown()` / `tearDownWithError()`
5. `#expect` instead of `XCTAssert*`
6. `#require` instead of `try XCTUnwrap()`
7. `Issue.record()` instead of `XCTFail()`
8. `@Test(arguments:)` for parameterized tests

---

## APPENDIX E: Test Template Library

### Unit Test Template (Model)

```swift
import Testing
@testable import DaisyDos

@Suite("<ModelName> Business Logic")
struct <ModelName>Tests {

    @Test("<Description of what the test validates>")
    func <testName>() {
        // Arrange
        let model = <ModelName>(/* initialize */)

        // Act
        model.someMethod()

        // Assert
        #expect(model.someProperty == expectedValue)
    }

    @Test("<Parameterized test description>", arguments: [/* test cases */])
    func <parameterizedTestName>(input: <Type>) {
        // Test with multiple inputs
        #expect(condition)
    }
}
```

### Integration Test Template

```swift
import Testing
@testable import DaisyDos

@Suite("<Feature> Integration")
@MainActor
struct <Feature>IntegrationTests {
    let container: ModelContainer
    let manager: <Manager>

    init() async throws {
        container = try ModelContainer(
            for: <Model>.self, <OtherModel>.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        manager = <Manager>(modelContext: container.mainContext)
    }

    @Test("<Cross-feature interaction description>")
    func <integrationTestName>() async throws {
        // Arrange - create related entities

        // Act - trigger cross-feature interaction

        // Assert - verify both features updated correctly
        #expect(condition1)
        #expect(condition2)
    }
}
```

### UI Test Template (Page Object)

```swift
import XCTest

final class <Feature>FlowTests: XCTestCase {
    var app: XCUIApplication!
    var <page>: <Page>!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()

        <page> = <Page>(app: app)
    }

    func test<FeatureFlow>() {
        // Arrange - navigate to starting point
        <page>.navigateTo()

        // Act - perform user actions
        <page>.performAction()

        // Assert - verify UI state
        XCTAssertTrue(<page>.elementExists)
    }
}

// Page Object
struct <Page> {
    let app: XCUIApplication

    func navigateTo() {
        app.tabBars.buttons["<TabName>"].tap()
    }

    func performAction() {
        app.buttons["<ButtonIdentifier>"].tap()
    }

    var elementExists: Bool {
        app.staticTexts["<ExpectedText>"].exists
    }
}
```

---

## APPENDIX F: Common Testing Patterns

### Pattern 1: Testing Observable State Changes

```swift
@Test("Manager notifies observers of state changes")
@MainActor
func observableStateChange() async throws {
    let container = try ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let taskManager = TaskManager(modelContext: container.mainContext)

    let initialCount = taskManager.taskCount
    _ = taskManager.createTask(title: "New task")

    // @Observable should update immediately
    #expect(taskManager.taskCount == initialCount + 1)
}
```

### Pattern 2: Testing SwiftData Relationships

```swift
@Test("Parent-child relationship persists correctly")
@MainActor
func parentChildRelationship() async throws {
    let container = try ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let parent = Task(title: "Parent")
    container.mainContext.insert(parent)

    let child = parent.createSubtask(title: "Child")

    #expect(parent.subtasks.contains(child))
    #expect(child.parentTask === parent)

    try container.mainContext.save()

    // Verify persistence
    let descriptor = FetchDescriptor<Task>()
    let allTasks = try container.mainContext.fetch(descriptor)
    #expect(allTasks.count == 2)
}
```

### Pattern 3: Testing Error Handling

```swift
@Test("Manager handles validation errors correctly")
func validationErrorHandling() {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let taskManager = TaskManager(modelContext: container.mainContext)

    // Empty title should fail
    let result = taskManager.createTask(title: "")

    guard case .failure(let error) = result else {
        Issue.record("Expected failure for empty title")
        return
    }

    #expect(error.userMessage.contains("check your information"))
    #expect(error.isUserError == true)
}
```

### Pattern 4: Testing Async Operations

```swift
@Test("Async manager operation completes successfully")
@MainActor
func asyncOperation() async throws {
    let manager = HabitManager(modelContext: modelContext)

    guard case .success(let habit) = manager.createHabit(title: "Test") else {
        Issue.record("Habit creation failed")
        return
    }

    // Async completion
    await manager.syncCompletions()

    #expect(habit.lastSyncDate != nil)
}
```

### Pattern 5: Testing Date-Based Logic

```swift
@Test("Date calculations handle edge cases")
func dateEdgeCases() {
    let calendar = Calendar.current

    // Midnight boundary
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 23
    components.minute = 59
    let almostMidnight = calendar.date(from: components)!

    let task = Task(title: "Test", dueDate: almostMidnight)

    // Should still be "due today" even at 23:59
    #expect(task.isDueToday)
}
```

---

## APPENDIX G: Verification Checklist

Before completing migration, verify:

### Phase 1 Checklist: ✅ Cleanup Complete

- [ ] All test files removed from `DaisyDos/Features/*/Testing/`
- [ ] InteractiveTestViews moved to `DaisyDos/DeveloperTools/InteractiveTesting/`
- [ ] All moved files wrapped in `#if DEBUG`
- [ ] Xcode project references updated (no red files)
- [ ] Project builds successfully (`Cmd + B`)
- [ ] Existing tests still pass (`Cmd + U`)

### Phase 2 Checklist: ✅ Swift Testing Adopted

- [ ] `DaisyDosTests.swift` uses Swift Testing (already done)
- [ ] `TaskDueDateTests.swift` migrated to Swift Testing
- [ ] New test files created in Unit/ structure
- [ ] All tests use `@Test` and `#expect`
- [ ] Test organization follows @Suite pattern
- [ ] All tests discoverable in Test Navigator

### Phase 3 Checklist: ✅ Testing Gaps Filled

- [ ] Subtask tests written (creation, deletion, ordering)
- [ ] Attachment tests written (file management, size limits)
- [ ] Recurrence tests written (instance creation, scheduling)
- [ ] Habit analytics tests written
- [ ] Logbook archival tests written
- [ ] Code coverage > 80%

### Phase 4 Checklist: ✅ CI/CD Integrated

- [ ] GitHub Actions / Xcode Cloud configured
- [ ] Tests run on every PR
- [ ] Coverage reports generated
- [ ] Failing tests block merge
- [ ] Performance regression detection enabled

---

## APPENDIX H: Troubleshooting

### Issue: "Cannot find 'Testing' in scope"

**Solution:**
```swift
// Add to test file
import Testing
```

**Solution if still fails:**
1. Check Package.swift or project dependencies
2. Ensure Swift Testing package added to test target
3. Clean build folder (Cmd + Shift + K)
4. Restart Xcode

### Issue: "@Test attribute not recognized"

**Solution:**
- Swift Testing requires Swift 5.9+ and Xcode 15+
- Check project's Swift Language Version setting
- Update to latest Xcode if necessary

### Issue: "Tests not appearing in Test Navigator"

**Solution:**
1. Ensure files are in DaisyDosTests target
2. Clean build (Cmd + Shift + K)
3. Close and reopen Test Navigator (Cmd + 6)
4. Product → Build for Testing (Cmd + Shift + U)

### Issue: "SwiftData ModelContainer crashes in tests"

**Solution:**
```swift
// Always use in-memory configuration
let container = try ModelContainer(
    for: Task.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
)
```

### Issue: "Test isolation error with @MainActor"

**Solution:**
```swift
// Add @MainActor to entire test suite
@Suite
@MainActor
struct MyTests {
    // All tests run on main actor
}

// Or add to individual tests
@Test
@MainActor
func myTest() async {
    // Test code
}
```

---

**Last Updated:** October 17, 2025
**Version:** 2.0 - Enhanced for complete migration
**Status:** ✅ Ready for Implementation
