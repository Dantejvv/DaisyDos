# Due Date Feature Validation Guide

This guide provides manual validation steps for the due date feature. Run these when you want to validate functionality without automated tests.

## ✅ Quick Validation Checklist

### 1. Basic Due Date Creation & Display
- [ ] Create a task with a due date 3 days from now
  - Verify due date appears in task detail
  - Verify due date shows formatted text (e.g., "Jan 20")
- [ ] Create a task without a due date
  - Verify no due date shown
  - Verify task works normally

### 2. Due Date Status Indicators
- [ ] Create a task due TODAY
  - Verify `isDueToday` shows "Today" text
  - Verify not marked as overdue
- [ ] Create a task due TOMORROW
  - Verify shows "Tomorrow" text
  - Verify `isDueSoon` returns true
- [ ] Create a task with due date 5 DAYS AGO
  - Verify shows as overdue (red indicator)
  - Verify `hasOverdueStatus` = true
- [ ] Complete the overdue task
  - Verify overdue indicator disappears
  - Verify `hasOverdueStatus` = false

### 3. Due Date Editing
- [ ] Edit an existing task's due date
  - Change from 3 days → 7 days
  - Verify updated date shows correctly
- [ ] Remove a due date from a task
  - Toggle off "Set due date"
  - Verify due date cleared

### 4. Subtask Due Date Inheritance
- [ ] Create parent task with due date (Jan 30)
- [ ] Add subtask to parent
  - Verify subtask inherits parent's due date (Jan 30)
- [ ] Change subtask due date to different date (Feb 5)
  - Verify subtask can have independent due date

### 5. Sorting & Filtering
- [ ] Create 5 tasks with mixed due dates:
  - Task A: No due date
  - Task B: Due yesterday (overdue)
  - Task C: Due today
  - Task D: Due in 2 days
  - Task E: Due in 10 days
- [ ] Sort by "Due Date"
  - Verify order: B (overdue) → C (today) → D (2 days) → E (10 days) → A (no date)
- [ ] Check "Today's Tasks" view
  - Should show: B (overdue), C (today), A (no date)
  - Should NOT show: D, E (future tasks)

### 6. Recurrence Integration
- [ ] Create recurring task (Daily) with due date
- [ ] Complete the task
- [ ] Verify new instance created with next day's due date

### 7. Task Duplication
- [ ] Duplicate task with PAST due date (5 days ago)
  - Verify duplicate has NO due date
- [ ] Duplicate task with FUTURE due date (7 days ahead)
  - Verify duplicate keeps the future due date

## 🎯 Expected Behavior Summary

### Computed Properties
| Property | Condition | Expected Result |
|----------|-----------|-----------------|
| `hasOverdueStatus` | Due date in past, incomplete | `true` |
| `hasOverdueStatus` | Due date in past, completed | `false` |
| `hasOverdueStatus` | Due date in future | `false` |
| `hasOverdueStatus` | No due date | `false` |
| `isDueToday` | Due date is today | `true` |
| `isDueToday` | Due date is yesterday/tomorrow | `false` |
| `isDueSoon` | Due in 0-3 days, incomplete | `true` |
| `isDueSoon` | Due in 4+ days | `false` |
| `isDueSoon` | Completed task | `false` |

### Display Text Format
| Due Date | Display Text |
|----------|--------------|
| Today | "Today" |
| Tomorrow | "Tomorrow" |
| This year (e.g., Mar 15, 2025) | "Mar 15" |
| Next year (e.g., Jan 20, 2026) | "Jan 20, 2026" |
| No due date | `nil` |

### TaskManager Filters
- `overdueTasks()` - Returns only incomplete tasks past their due date
- `tasksDueToday()` - Returns tasks due on current date
- `tasksDueSoon()` - Returns tasks due within next 3 days
- `tasksWithDueDates()` - Returns all tasks that have any due date set
- `enhancedTodaysTasks` - Returns overdue + due today + no due date (excludes future tasks)

## 🧪 Manual Code Verification

If you want to verify the code logic without UI testing, you can check these files:

### Core Implementation Files
```
Task.swift:52              - dueDate property definition
Task.swift:146-160         - Computed properties (hasOverdueStatus, isDueToday, isDueSoon)
Task.swift:404-418         - Display text formatting
Task.swift:311             - Subtask inheritance logic
TaskManager.swift:313-327  - Filtering methods
TaskManager.swift:486-532  - Enhanced today's tasks logic
TaskManager.swift:549-555  - Duplication smart handling
```

### UI Integration Files
```
AddTaskView.swift:61-70    - Due date picker UI
TaskEditView.swift:173-182 - Due date editing
TaskDetailView.swift:433-468 - Due date display with overdue warnings
TasksView.swift:292-301    - Due date sorting logic
```

## 🔍 Quick Code Inspection

To verify the implementation without running tests, check:

1. **Due Date Storage**: Grep for `var dueDate: Date?` in Task.swift
2. **Status Logic**: Review computed properties in Task.swift lines 146-160
3. **Display Logic**: Check dueDateDisplayText property in Task.swift:404-418
4. **Manager Filters**: Review TaskManager.swift filtering methods

## 📝 Notes

- All due date comparisons are timezone-aware via `Calendar.current`
- Completed tasks are never marked as overdue (by design)
- Due dates can be set in the past (for catching up on old work)
- Subtasks inherit parent due dates but can be changed independently
- Past due dates are removed when duplicating tasks (smart behavior)
- Future due dates are preserved when duplicating tasks

---

**Automated Test Suite**: If you want to run the comprehensive XCTest suite later, it's available at:
`DaisyDosTests/TaskDueDateTests.swift` (36 test cases covering all scenarios)

Run with: Open Xcode → Product → Test → Select TaskDueDateTests
