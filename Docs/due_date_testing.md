# Due Date Testing Guide

## Overview

The due date feature testing follows the same pattern as the Logbook testing system. Tests run **inside the app** without launching Xcode's test runner or simulator automation.

## Test Suite Structure

### Files Created
```
DaisyDos/Features/Tasks/Testing/
├── DueDateTestSuite.swift     # @Observable test runner with 20 test cases
└── DueDateTestView.swift      # SwiftUI interface to run and view tests
```

### Architecture Pattern
- **@Observable Class**: `DueDateTestSuite` - Contains all test logic
- **SwiftUI View**: `DueDateTestView` - UI to trigger tests and display results
- **No Simulator Required**: Tests run entirely within the app
- **Instant Feedback**: See results in real-time with pass/fail status

## How to Run Tests

### Option 1: Add to Settings (Recommended)
Add `DueDateTestView` to your Settings or Developer menu:

```swift
NavigationLink("Due Date Tests") {
    DueDateTestView()
}
```

### Option 2: Direct Preview
In Xcode, open `DueDateTestView.swift` and use the Preview canvas:
1. Open `DueDateTestView.swift`
2. Press `Option + Cmd + Return` to show preview
3. Click "Run All Tests" button

### Option 3: Programmatic Execution
```swift
let suite = DueDateTestSuite(
    modelContext: modelContext,
    taskManager: taskManager
)
suite.runAllTests()
// Check suite.testResults for results
```

## Test Coverage (20 Tests)

### Core Functionality (Tests 1-3)
1. **Create Task with Due Date** - Verifies due date assignment
2. **Create Task without Due Date** - Verifies optional behavior
3. **Create Task with Past Due Date** - Verifies overdue detection

### Status Detection (Tests 4-6)
4. **Overdue Status Detection** - Tests `hasOverdueStatus` logic
5. **Due Today Detection** - Tests `isDueToday` accuracy
6. **Due Soon Detection** - Tests 0-3 day window

### Display & Formatting (Tests 7-9)
7. **Display Text Formatting** - Tests Today/Tomorrow/Year formatting
8. **Update Due Date** - Tests modification capabilities
9. **Remove Due Date** - Tests clearing due dates

### Subtask Behavior (Tests 10-11)
10. **Subtask Inheritance** - Tests automatic due date inheritance
11. **Subtask Independence** - Tests custom subtask due dates

### Recurrence Integration (Tests 12-13)
12. **Recurrence Next Occurrence** - Tests date calculation
13. **Recurring Instance Creation** - Tests new task generation

### Filtering & Queries (Tests 14-17)
14. **Overdue Tasks Filtering** - Tests `overdueTasks()` method
15. **Tasks Due Today Filtering** - Tests `tasksDueToday()` method
16. **Tasks Due Soon Filtering** - Tests `tasksDueSoon()` method
17. **Enhanced Today's Tasks** - Tests composite filtering logic

### Advanced Features (Tests 18-20)
18. **Due Date Sorting** - Tests sorting algorithm
19. **Duplicate Overdue Task** - Tests smart past date removal
20. **Duplicate Future Task** - Tests future date preservation

## Expected Output

### Console Output
```
🧪 ========================================
🧪 DUE DATE TEST SUITE - STARTING
🧪 ========================================

✅ Test 1: Create Task with Due Date - Due date set to 10/20/25
✅ Test 2: Create Task without Due Date - Task correctly has no due date
✅ Test 3: Create Task with Past Due Date - Past due date correctly marked as overdue
...
✅ Test 20: Duplicate Future Task - Future due date correctly preserved in duplicate

🧪 ========================================
🧪 TEST SUITE COMPLETE
🧪 ========================================
✅ Passed: 20
❌ Failed: 0
⏱️  Total Duration: 1.85s
🧪 ========================================
```

### UI Output
- **Summary Cards**: Passed count, Failed count, Total duration
- **Test Results List**: Each test with pass/fail icon, name, message, and duration
- **Real-time Updates**: Tests run sequentially with live updates

## Test Result Interpretation

### Success Indicators
- ✅ Green checkmark icon
- Test message explains what was verified
- Duration shows performance

### Failure Indicators
- ❌ Red X icon
- Error message describes what failed
- Expected vs actual values shown

### Performance Expectations
- **Total Duration**: ~1-2 seconds for all 20 tests
- **Individual Tests**: Most complete in <0.01 seconds
- **Database Operations**: Clean setup/teardown for each test

## Debugging Failed Tests

If tests fail, check:

1. **Due Date Logic** (`Task.swift:146-160`)
   - `hasOverdueStatus`
   - `isDueToday`
   - `isDueSoon`

2. **Display Text** (`Task.swift:404-418`)
   - `dueDateDisplayText` formatting

3. **Manager Methods** (`TaskManager.swift:313-327`)
   - `overdueTasks()`
   - `tasksDueToday()`
   - `tasksDueSoon()`

4. **Recurrence** (`Task.swift:360-383`)
   - `nextRecurrence()`
   - `createRecurringInstance()`

## Adding New Tests

Follow the pattern in `DueDateTestSuite.swift`:

```swift
/// Test X: Test Name
private func runTestX_TestName() {
    currentTest = "Test X: Test Name"
    let startTime = Date()

    do {
        try cleanDatabase()

        // Test setup and execution
        // ...

        if /* condition */ {
            recordSuccess(X, startTime, "Success message")
        } else {
            recordFailure(X, startTime, "Failure message")
        }
    } catch {
        recordFailure(X, startTime, "Exception: \(error.localizedDescription)")
    }
}
```

Then add to `runAllTests()`:
```swift
runTestX_TestName()
```

## Comparison with XCTest Suite

| Feature | DueDateTestSuite | XCTest (TaskDueDateTests) |
|---------|------------------|---------------------------|
| **Execution** | In-app, on-demand | Xcode test runner only |
| **UI** | SwiftUI with results | Terminal output |
| **Speed** | Instant | Requires simulator launch |
| **Control** | Run when you want | Automated CI/CD friendly |
| **Best For** | Manual validation | Continuous integration |

Both test suites validate the same functionality - choose based on your workflow!

## Notes

- Tests run in `#if DEBUG` blocks (release builds exclude them)
- Database is cleaned before each test (no interference)
- Tests are fully isolated (no shared state)
- Can be run repeatedly without side effects
- Safe to run on production data (creates separate test tasks)

---

**Quick Start**: Add `DueDateTestView()` to Settings → Run All Tests → Verify all 20 tests pass ✅
