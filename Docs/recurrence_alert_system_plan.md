# Recurrence Alert System Implementation Plan

## Intended Logic

### Core Rules:
1. **Alert only applies to ACTIVE instance** - Alert belongs to the instance created at replenishment
2. **New instance = reset alert eligibility** - `notificationFired` resets at replenishment, not completion
3. **Alert fires on replenishment day at alert time** - Uses `ReplenishmentTimeManager` + `alertTimeHour/Minute`
4. **No replenishment if previous incomplete** - Blocking logic for habits
5. **Completion cancels alert** - Remove notification, but don't reset `notificationFired` until next replenishment

### Timeline (Daily habit, 11AM replenish, 1PM alert):
| Time | Event | Bell | Alert |
|------|-------|------|-------|
| Day 1, 1PM | Create habit | No | No (predates replenishment) |
| Day 1, 9PM | Complete | No | - |
| Day 2, 11AM | Replenish | Yes | Scheduled 1PM |
| Day 2, 1PM | Alert fires | No | Fired |
| Day 2, 9PM | Complete | No | - |
| Day 3, 11AM | Replenish | Yes | Scheduled 1PM |

---

## Current State Analysis

### Tasks: ✅ Mostly Correct
- Uses `PendingRecurrence` for deferred instance creation
- Uses `ReplenishmentTimeManager` for scheduling
- `notificationFired` is per-instance (new task = fresh flag)
- **Minor gap**: `effectiveReminderDate` may not account for replenishment time correctly

### Habits: ❌ Needs Rework
- No instance model - habit is global
- `notificationFired` resets on completion (should reset at replenishment)
- Doesn't use `ReplenishmentTimeManager`
- No "incomplete blocks next" logic
- Alert scheduled immediately on completion

---

## Implementation Phases

### Phase 1: Habit Instance Model (Foundation)

**Goal**: Track habit "active instances" similar to tasks

#### 1.1 Add Instance Tracking to Habit Model

**File**: `Features/Habits/Models/Habit.swift`

Add properties:
```swift
/// Date when current active instance was created (replenishment time)
var currentInstanceDate: Date?

/// Whether the current instance has been completed
/// Computed from: lastCompletedDate >= currentInstanceDate
var isCurrentInstanceCompleted: Bool {
    guard let instanceDate = currentInstanceDate,
          let completedDate = lastCompletedDate else { return false }
    return completedDate >= instanceDate
}

/// Whether habit is eligible for new instance (previous completed or first time)
var canReplenish: Bool {
    // First time: no instance yet
    guard let instanceDate = currentInstanceDate else { return true }
    // Check if current instance is completed
    return isCurrentInstanceCompleted
}
```

#### 1.2 Update `isCompletedToday` Logic

Current:
```swift
var isCompletedToday: Bool {
    guard let lastCompleted = lastCompletedDate else { return false }
    return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
}
```

New:
```swift
var isCompletedToday: Bool {
    // Must have active instance AND completed it
    guard let instanceDate = currentInstanceDate,
          let completedDate = lastCompletedDate else { return false }
    return completedDate >= instanceDate
}
```

---

### Phase 2: Replenishment Integration for Habits

**Goal**: Habits use `ReplenishmentTimeManager` like tasks do

#### 2.1 Create HabitReplenishmentService

**New File**: `Features/Habits/Services/HabitReplenishmentService.swift`

```swift
@Observable
final class HabitReplenishmentService {
    private let replenishmentTimeManager: ReplenishmentTimeManager

    /// Check and replenish all eligible habits
    func processReplenishments(habits: [Habit]) {
        let now = Date()
        let replenishmentTime = replenishmentTimeManager.todayReplenishmentDate

        for habit in habits where habit.shouldReplenish(at: now, replenishmentTime: replenishmentTime) {
            replenishHabit(habit)
        }
    }

    /// Replenish a single habit - create new active instance
    func replenishHabit(_ habit: Habit) {
        // Only if previous instance completed (or first time)
        guard habit.canReplenish else { return }

        // Set new instance date
        habit.currentInstanceDate = replenishmentTimeManager.todayReplenishmentDate

        // Reset notification state for new instance
        habit.notificationFired = false

        // Reset subtasks for new instance
        habit.resetSubtasksForNewInstance()

        // Notify for alert scheduling
        NotificationCenter.default.post(name: .habitDidReplenish, object: nil,
                                        userInfo: ["habitId": habit.id.uuidString])
    }
}
```

#### 2.2 Add Replenishment Check to Habit

**File**: `Features/Habits/Models/Habit.swift`

```swift
/// Determines if habit should replenish now
func shouldReplenish(at date: Date, replenishmentTime: Date) -> Bool {
    // Must have recurrence rule
    guard recurrenceRule != nil else { return false }

    // Must be past replenishment time today
    guard date >= replenishmentTime else { return false }

    // Must not have already replenished today
    if let instanceDate = currentInstanceDate,
       Calendar.current.isDate(instanceDate, inSameDayAs: date) {
        return false
    }

    // Must be a scheduled day for this recurrence pattern
    guard isDueOn(date) else { return false }

    // Must have completed previous instance (or be first time)
    return canReplenish
}
```

#### 2.3 Hook into App Lifecycle

**File**: `App/DaisyDosApp.swift` or `Core/Services/AppLifecycleManager.swift`

```swift
// On app foreground / scene activation:
habitReplenishmentService.processReplenishments(habits: allHabits)
```

---

### Phase 3: Alert Scheduling Updates

**Goal**: Align `HabitNotificationManager` with instance-based model

#### 3.1 Update `effectiveReminderDate` for Habits

**File**: `Features/Habits/Models/Habit.swift`

Current logic calculates next occurrence. New logic should:
- Only return a date if there's an active instance (`currentInstanceDate` is set)
- Apply alert time to the instance date, not "next occurrence"

```swift
var effectiveReminderDate: Date? {
    // Snoozed takes priority
    if let snoozed = snoozedUntil { return snoozed }

    // Must have alert time configured
    guard let hour = alertTimeHour, let minute = alertTimeMinute else { return nil }

    // Must have active instance
    guard let instanceDate = currentInstanceDate else { return nil }

    // Apply alert time to instance date
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: instanceDate)
    components.hour = hour
    components.minute = minute
    components.second = 0

    return calendar.date(from: components)
}
```

#### 3.2 Update `hasPendingAlert`

**File**: `Features/Habits/Models/Habit.swift`

```swift
var hasPendingAlert: Bool {
    // Must have active uncompleted instance
    guard !isCurrentInstanceCompleted else { return false }

    // Must have future reminder date
    guard let date = effectiveReminderDate else { return false }

    // Must not have fired yet
    return date > Date() && !notificationFired
}
```

#### 3.3 Update `reminderDisplayText`

Show "None" if no active instance or instance completed:

```swift
var reminderDisplayText: String? {
    // No display if instance completed or no instance
    guard let _ = currentInstanceDate, !isCurrentInstanceCompleted else { return nil }

    // Existing time formatting logic...
}
```

#### 3.4 Update HabitNotificationManager

**File**: `Features/Habits/Services/HabitNotificationManager.swift`

Change `habitWasCompleted` observer:
```swift
@objc private func habitWasCompleted(_ notification: Foundation.Notification) {
    // REMOVE notification (don't reschedule)
    // Next instance will be created at replenishment time
    removeHabitNotification(habitId: habitId)
}
```

Add `habitDidReplenish` observer:
```swift
@objc private func habitDidReplenish(_ notification: Foundation.Notification) {
    // Schedule notification for new instance
    if let habit = fetchHabit(habitId) {
        scheduleHabitReminder(for: habit)
    }
}
```

---

### Phase 4: Task Alignment (Minor)

**Goal**: Ensure tasks follow same pattern

#### 4.1 Verify `effectiveReminderDate` Uses Replenishment

Current implementation should already work since:
- New task instances are created with fresh `notificationFired = false`
- `effectiveReminderDate` calculates based on task's due date

**Verify**: Alert time is applied to the task's `dueDate` (set at replenishment), not calculated from recurrence rule.

---

### Phase 5: Bell Icon & Detail View

**Goal**: Consistent display across both types

#### 5.1 Bell Icon Shows When:
- Has active instance (`currentInstanceDate` for habits, task exists for tasks)
- Instance not completed
- Alert time configured
- `notificationFired == false`
- Alert time is in future OR hasn't passed today yet

#### 5.2 Detail View "Reminder" Field Shows:
- **"None"** if: no alert configured OR no active instance OR instance completed
- **Time** if: active uncompleted instance with alert configured

---

## Migration Considerations

### Existing Habits Without `currentInstanceDate`:
- On first app launch after update, run migration:
  - If habit is active (not completed today): set `currentInstanceDate = startOfToday`
  - If habit is completed today: set `currentInstanceDate = startOfToday`
  - This preserves current behavior while enabling new model

### Notification Identifiers:
- Current: `"habit-{habitId}"` or `"task-{taskId}"`
- No change needed - identifier is per-item, notification content changes per instance

---

## Testing Checklist

### Habit Scenarios:
- [ ] Create habit at 1PM with 1PM alert → Bell should NOT show (no instance yet)
- [ ] After replenishment time → Bell shows
- [ ] Complete before alert → Bell disappears, no alert fires
- [ ] Alert fires → Bell disappears
- [ ] Don't complete → Next day, no replenishment, no bell
- [ ] Complete then next replenishment → New bell appears

### Task Scenarios:
- [ ] Create recurring task → Behaves same as habit
- [ ] Complete task → PendingRecurrence created
- [ ] At replenishment time → New task appears with bell

### Edge Cases:
- [ ] Snooze then complete → Snooze cancelled
- [ ] Change alert time mid-instance → Reschedule notification
- [ ] Delete habit/task → Notification cancelled
- [ ] App backgrounded during replenishment time → Process on foreground

---

## Files to Modify

1. `Features/Habits/Models/Habit.swift` - Add instance tracking
2. `Features/Habits/Services/HabitNotificationManager.swift` - Change completion handling
3. **NEW** `Features/Habits/Services/HabitReplenishmentService.swift` - Replenishment logic
4. `Features/Tasks/Models/Task.swift` - Verify effectiveReminderDate
5. `App/DaisyDosApp.swift` or lifecycle manager - Hook replenishment processing
6. `Core/Services/Managers/NotificationDelegate.swift` - Verify no changes needed

---

## Estimated Scope

- **Phase 1**: Habit instance model - Core foundation
- **Phase 2**: Replenishment service - Integration layer
- **Phase 3**: Alert scheduling - Notification updates
- **Phase 4**: Task verification - Minor checks
- **Phase 5**: UI consistency - Bell/detail view

Total: Moderate complexity, primarily habit-side changes. Tasks already follow the correct pattern.
