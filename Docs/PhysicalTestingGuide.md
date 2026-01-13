# Physical Device Testing Guide: Notifications & Recurrence

This guide provides comprehensive test cases for validating DaisyDos notification and recurrence features on physical iOS devices.

---

## Table of Contents
1. [Prerequisites & Setup](#1-prerequisites--setup)
2. [Task Notifications](#2-task-notifications)
3. [Habit Notifications](#3-habit-notifications)
4. [Recurrence System](#4-recurrence-system)
5. [Integration Tests](#5-integration-tests)
6. [Edge Cases & Error Scenarios](#6-edge-cases--error-scenarios)
7. [Troubleshooting Guide](#7-troubleshooting-guide)
8. [Quick Reference Checklists](#8-quick-reference-checklists)
9. [Test Session Log](#9-test-session-log)

---

## 1. Prerequisites & Setup

### Device Requirements
- iOS 17.0 or later
- Physical device (notifications behave differently on simulator)
- Stable network connection (for CloudKit sync testing, if enabled)

### Pre-Test Setup Checklist

| Step | Action | Verified |
|------|--------|----------|
| 1 | Install latest build of DaisyDos on device | [ ] |
| 2 | Launch app and complete onboarding if prompted | [ ] |
| 3 | Grant notification permissions when prompted | [ ] |
| 4 | Verify global notifications enabled (Settings tab → Notifications) | [ ] |
| 5 | Clear any existing test data (optional: fresh install) | [ ] |
| 6 | Note device time zone in test log | [ ] |
| 7 | Ensure Do Not Disturb is OFF | [ ] |
| 8 | Ensure Focus modes are OFF or allow DaisyDos | [ ] |

### Verifying Notification Permissions

1. Open iOS Settings → DaisyDos
2. Tap "Notifications"
3. Verify:
   - "Allow Notifications" is ON
   - "Lock Screen", "Notification Center", and "Banners" are enabled
   - "Sounds" is enabled
   - "Badges" is enabled

### In-App Notification Settings

Location: **Settings tab → Notifications**
- Global notification toggle
- When disabled: All scheduled notifications are removed
- When enabled: All applicable notifications are rescheduled

---

## 2. Task Notifications

### 2.1 Basic Reminder Creation

Tasks use **absolute date/time reminders** set via the reminder picker.

#### T-N-01: Create task with 2-minute reminder
**Steps:**
1. Create new task
2. Tap bell icon in toolbar
3. Set reminder to 2 minutes from now
4. Save task
5. Lock device or background app

**Expected:** Notification appears in ~2 minutes with task title

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |      |

---

#### T-N-02: Create task with 1-hour reminder
**Steps:**
1. Create task
2. Set reminder to 1 hour from now
3. Save and wait

**Expected:** Notification appears in 1 hour

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-03: Create task with next-day reminder
**Steps:**
1. Create task
2. Set reminder for tomorrow at 9:00 AM
3. Save

**Expected:** Notification appears tomorrow at 9:00 AM

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-04: Modify existing reminder
**Steps:**
1. Edit task with reminder
2. Change reminder time to 5 minutes from now
3. Save

**Expected:** Old notification cancelled, new one scheduled. Appears in 5 min

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-05: Remove reminder
**Steps:**
1. Edit task with reminder
2. Clear reminder (set to None)
3. Save

**Expected:** No notification appears at original time

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 2.2 Notification Actions

#### T-N-06: Complete from notification
**Steps:**
1. Wait for task notification
2. Long-press notification
3. Tap "Complete" action

**Expected:** Task marked complete in app, notification dismissed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-07: Snooze from notification
**Steps:**
1. Wait for task notification
2. Long-press notification
3. Tap "Snooze" action

**Expected:** Notification dismissed, new notification appears 1 hour later with "(Snoozed)" in title

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-08: Tap to open
**Steps:**
1. Wait for task notification
2. Tap notification banner

**Expected:** App opens to task detail view

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-09: Dismiss notification
**Steps:**
1. Wait for task notification
2. Swipe to dismiss

**Expected:** Notification removed, task unchanged in app

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-10: Complete from lock screen
**Steps:**
1. Wait for notification on lock screen
2. Long-press and select "Complete"

**Expected:** Task marked complete (may require Face ID/passcode)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |      |

---

### 2.3 Completed Task Behavior

#### T-N-11: Complete task before reminder
**Steps:**
1. Create task with reminder in 5 min
2. Complete task in app before reminder time

**Expected:** No notification appears at reminder time

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### T-N-12: Undo completion reschedules future reminder
**Steps:**
1. Create task with reminder set 5 minutes from now
2. Complete the task (reminder notification is cancelled)
3. Tap "Undo" on the toast within timeout
4. Wait for original reminder time

**Expected:** Notification appears at original reminder time (reminder rescheduled on undo)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

## 3. Habit Notifications

### Understanding Habit Reminders

**Important:** Habits use **absolute date/time reminders** (identical to tasks), NOT offset-based alerts relative to a "target time". The reminder picker allows you to set a specific date and time when the notification should fire.

**Key differences from tasks:**
- **One-shot notifications**: Each reminder schedules a single notification for the specified date/time
- **Rescheduling on completion**: When you complete a habit, the notification is rescheduled for the next occurrence based on the recurrence rule
- **Future date required**: The reminder date must be in the future; past dates are ignored
- **Independent of recurrence**: The recurrence rule determines which days the habit appears as "due", while `reminderDate` is an independent notification time

### 3.1 Basic Reminder Creation

#### H-N-01: Create habit with 2-minute reminder
**Steps:**
1. Create new habit with a title
2. Tap the bell/alarm icon in the toolbar
3. In the reminder picker, select **today's date** and set the **time** to 2 minutes from now
4. Tap "Done" to confirm the reminder
5. Save the habit
6. Lock device or background app

**Expected:** Notification appears in ~2 minutes with habit title

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-02: Create habit with 1-hour reminder
**Steps:**
1. Create habit
2. Tap reminder picker
3. Set reminder to 1 hour from now (today's date, time +1 hour)
4. Save and wait

**Expected:** Notification appears in 1 hour

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-03: Create habit with next-day reminder
**Steps:**
1. Create habit
2. Set reminder for tomorrow at 9:00 AM
3. Save

**Expected:** Notification appears tomorrow at 9:00 AM

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-04: Modify existing reminder
**Steps:**
1. Edit habit with existing reminder
2. Change reminder time to 5 minutes from now
3. Save

**Expected:** Old notification cancelled, new one scheduled. Appears in 5 min

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-05: Remove reminder
**Steps:**
1. Edit habit with reminder
2. Open reminder picker and select "No Reminder"
3. Save

**Expected:** No notification appears at original time

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 3.2 Completion & Rescheduling Behavior

#### H-N-06: Complete habit reschedules notification
**Steps:**
1. Create daily habit with reminder set for today (e.g., 5 min from now)
2. Complete the habit in the app BEFORE the reminder time
3. Check if notification still fires at original time
4. Next day: check if notification fires again at same time

**Expected:**
- Today's notification is cancelled when habit is completed
- Tomorrow's notification is automatically scheduled (same time, next day)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-07: Undo completion restores notification
**Steps:**
1. Create habit with reminder in 10 minutes
2. Complete the habit (notification cancelled)
3. Tap "Undo" within timeout
4. Wait for original reminder time

**Expected:** Notification reappears at original time (rescheduled on undo)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-08: Already completed today - no notification
**Steps:**
1. Create daily habit
2. Complete the habit
3. Edit habit and set reminder for 5 min from now
4. Save and wait

**Expected:** No notification (habit already completed today, skips scheduling)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 3.3 Recurrence Integration

**Note:** Habit recurrence rules determine which days the habit appears as "due". The reminder system schedules one-shot notifications that get rescheduled when the habit is completed.

#### H-N-09: Daily habit - notification each day
**Steps:**
1. Create daily habit with reminder at 9:00 AM today
2. Complete habit today
3. Tomorrow at 9:00 AM, check for notification

**Expected:** Notification fires at 9:00 AM each day until completed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-10: Weekly habit (M/W/F) - correct days only
**Steps:**
1. Create habit with Mon/Wed/Fri recurrence
2. Set reminder for appropriate time
3. Complete on Monday
4. Check Tuesday (off day) - no notification
5. Check Wednesday - notification should fire

**Expected:** Notification only on scheduled days (Mon/Wed/Fri)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-11: Skip habit - notification behavior
**Steps:**
1. Create daily habit with reminder
2. When notification fires, long-press and tap "Skip Today"
3. Next day: check for notification

**Expected:** Today's notification dismissed; tomorrow's notification scheduled

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 3.4 Notification Actions

#### H-N-12: Complete from notification
**Steps:**
1. Wait for habit notification
2. Long-press the notification
3. Tap "Mark Complete ✓"

**Expected:** Habit marked complete for today, notification dismissed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-13: Skip from notification
**Steps:**
1. Wait for habit notification
2. Long-press
3. Tap "Skip Today"

**Expected:** Habit marked skipped for today, notification dismissed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-14: Snooze from notification
**Steps:**
1. Wait for habit notification
2. Long-press
3. Tap "Snooze 1 Hour"

**Expected:** Notification dismissed, new notification appears 1 hour later with "(Snoozed)" in title

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-15: Tap to open
**Steps:**
1. Tap habit notification banner

**Expected:** App opens to habit detail view

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### H-N-16: Dismiss notification
**Steps:**
1. Wait for habit notification
2. Swipe to dismiss

**Expected:** Notification removed, habit unchanged in app

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

## 4. Recurrence System

### 4.1 Daily Recurrence

#### R-D-01: Basic daily
**Steps:**
1. Create task with daily recurrence
2. Complete task
3. Reopen app next day (or wait for schedule)

**Expected:** New task instance created for next day

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-D-02: Every 2 days
**Steps:**
1. Create task with 2-day interval
2. Complete
3. Check next day

**Expected:** No new task next day; appears in 2 days

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-D-03: Every 3 days
**Steps:** Same as above with 3-day interval

**Expected:** New instance in 3 days

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-D-04: Daily with specific time
**Steps:**
1. Create daily task with preferred time (e.g., 9 AM)
2. Complete

**Expected:** Next instance has 9 AM as due time

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.2 Weekly Recurrence

#### R-W-01: Single weekday (Monday)
**Steps:**
1. Create task recurring every Monday
2. Complete on Monday

**Expected:** Next instance appears next Monday

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-W-02: Multiple weekdays (Mon/Wed/Fri)
**Steps:**
1. Create task for Mon, Wed, Fri
2. Complete on Monday

**Expected:** Next instance on Wednesday

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-W-03: Week boundary (Fri to Mon)
**Steps:**
1. Create task for Mon/Fri
2. Complete on Friday

**Expected:** Next instance is Monday (week rolls over)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-W-04: All weekdays
**Steps:**
1. Create task for all 7 days
2. Complete

**Expected:** Next instance is tomorrow

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.3 Monthly Recurrence

#### R-M-01: Normal day (15th)
**Steps:**
1. Create monthly task for 15th
2. Complete

**Expected:** Next instance on 15th of next month

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-M-02: Month-end (31st)
**Steps:**
1. Create monthly task for 31st
2. Complete in January

**Expected:** Feb instance on 28th (or 29th leap year)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-M-03: Day 30
**Steps:**
1. Create monthly task for 30th
2. Complete in January

**Expected:** Feb instance on 28th/29th

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-M-04: Day 29
**Steps:**
1. Create monthly task for 29th
2. Complete in January

**Expected:** Feb instance on 28th (non-leap) or 29th (leap)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.4 Yearly Recurrence

#### R-Y-01: Normal date
**Steps:**
1. Create yearly task (e.g., March 15)
2. Complete

**Expected:** Next instance March 15 next year

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-Y-02: Feb 29 (leap year)
**Steps:**
1. Create yearly task for Feb 29 in leap year
2. Complete

**Expected:** Next year (non-leap): Feb 28

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-Y-03: Feb 29 preservation
**Steps:** Same task, wait for next leap year

**Expected:** Returns to Feb 29 in leap year

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  | Requires long-term tracking |

---

### 4.5 Custom Intervals

#### R-C-01: Every 5 days
**Steps:**
1. Create task with custom 5-day interval
2. Complete

**Expected:** Next instance in 5 days

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-C-02: Every 10 days
**Steps:** Same with 10-day interval

**Expected:** Next instance in 10 days

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-C-03: Maximum interval (365 days)
**Steps:** Create with 365-day interval

**Expected:** Functions as yearly (1 year interval)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.6 maxOccurrences

#### R-MO-01: Limit of 3
**Steps:**
1. Create task with maxOccurrences=3
2. Complete 3 times

**Expected:** No 4th instance created

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-MO-02: Limit of 1
**Steps:**
1. Create task with maxOccurrences=1
2. Complete

**Expected:** No second instance (one-time behavior)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-MO-03: Limit of 10
**Steps:**
1. Create task with maxOccurrences=10
2. Complete all 10

**Expected:** 10th completion stops recurrence

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-MO-04: Verify counter
**Steps:**
1. Create task with maxOccurrences=5
2. Complete 2 times
3. Check remaining count

**Expected:** Should show 3 remaining (or equivalent)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.7 recreateIfIncomplete

#### R-RI-01: `true` - incomplete creates next
**Steps:**
1. Create daily task with recreateIfIncomplete=true
2. Do NOT complete today
3. Check tomorrow

**Expected:** New instance created even though previous incomplete

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-RI-02: `false` - incomplete blocks next
**Steps:**
1. Create daily task with recreateIfIncomplete=false
2. Do NOT complete today
3. Check tomorrow

**Expected:** NO new instance (blocked until previous completed)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-RI-03: `false` - complete unblocks
**Steps:**
1. Same as R-RI-02
2. Complete the incomplete task

**Expected:** Next instance created after completion

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 4.8 Deferred Creation (PendingRecurrence)

The system uses deferred creation: completing a recurring task schedules the next instance for the future, not immediately.

#### R-PC-01: Not immediate
**Steps:**
1. Create daily task (due tomorrow)
2. Complete today

**Expected:** New instance does NOT appear immediately; appears tomorrow

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-PC-02: App foreground triggers
**Steps:**
1. Complete recurring task
2. Close app completely
3. Wait past scheduled time
4. Reopen app

**Expected:** Pending task created when app becomes active

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-PC-03: App launch triggers
**Steps:**
1. Complete recurring task
2. Force quit app
3. Wait past scheduled time
4. Launch app fresh

**Expected:** Pending task processed on launch

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### R-PC-04: Multiple pending
**Steps:**
1. Complete several recurring tasks
2. Background app for extended period
3. Return to app

**Expected:** All pending recurrences processed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

## 5. Integration Tests

### 5.1 Recurring Task + Reminder

#### I-01: Reminder not inherited
**Steps:**
1. Create recurring task with reminder
2. Complete task

**Expected:** New instance created WITHOUT reminder (must set manually)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-02: Set reminder on recurring instance
**Steps:**
1. Edit recurring instance
2. Add reminder
3. Complete

**Expected:** New instance still has no reminder

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 5.2 App Lifecycle

#### I-03: Notification while backgrounded
**Steps:**
1. Create task reminder for 2 min
2. Background app
3. Wait for notification

**Expected:** Notification appears, actions work correctly

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-04: Notification after force quit
**Steps:**
1. Create task reminder
2. Force quit app
3. Wait for notification

**Expected:** Notification appears (system scheduled)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-05: Action after app killed
**Steps:**
1. Force quit app
2. Wait for notification
3. Tap "Complete" action

**Expected:** App launches, task marked complete

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-06: Badge count accuracy
**Steps:**
1. Create multiple tasks with reminders
2. Let notifications fire

**Expected:** Badge shows correct count of pending items

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-07: Badge cleared on launch
**Steps:**
1. Have notifications pending
2. Launch app

**Expected:** Badge count resets to 0

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 5.3 Global Toggle Interactions

#### I-08: Disable clears all
**Steps:**
1. Create several tasks/habits with notifications
2. Go to Settings → Notifications
3. Disable global toggle

**Expected:** All pending notifications removed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### I-09: Re-enable reschedules
**Steps:**
1. With notifications disabled, create tasks with reminders
2. Enable global toggle

**Expected:** All applicable notifications scheduled

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

## 6. Edge Cases & Error Scenarios

### 6.1 Permission States

#### E-P-01: Initially denied
**Steps:**
1. Fresh install
2. Deny notification permission
3. Create task with reminder

**Expected:** App functions, no notification appears, no crash

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-P-02: Revoke mid-use
**Steps:**
1. With notifications working
2. Go to iOS Settings → DaisyDos → Notifications
3. Disable "Allow Notifications"

**Expected:** Existing notifications removed by system

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-P-03: Re-grant permission
**Steps:**
1. After denying, re-enable in iOS Settings
2. Create new task with reminder

**Expected:** New notifications work

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 6.2 Time/Date Edge Cases

#### E-T-01: Past reminder date
**Steps:**
1. Create task
2. Set reminder for time that has passed

**Expected:** Reminder NOT scheduled (past dates ignored)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-T-02: Very near future (< 1 min)
**Steps:**
1. Set reminder for 30 seconds from now

**Expected:** Notification may or may not appear (system delay) - Edge case

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-T-03: Far future (1 year)
**Steps:**
1. Set reminder for 1 year from now
2. Verify saved

**Expected:** Reminder saved, will fire in 1 year (system limit applies)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 6.3 Timezone Testing

**Note:** These tests require manually changing device timezone in iOS Settings.

#### E-TZ-01: Create in TZ A, receive in TZ B
**Steps:**
1. Create task reminder for 3 PM in timezone A
2. Change device to timezone B (+2 hours)
3. Wait

**Expected:** Notification at 3 PM in original timezone (appears 1 PM in new TZ) - Depends on implementation

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-TZ-02: Recurrence across TZ change
**Steps:**
1. Create daily recurring task
2. Change timezone
3. Check next occurrence

**Expected:** Follows user's timezone preference

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 6.4 February Edge Cases

**Note:** These tests may require date manipulation or waiting until specific dates.

#### E-F-01: Jan 31 monthly to Feb
**Steps:**
1. Create monthly task for 31st on Jan 31
2. Complete

**Expected:** Feb instance created on 28th (non-leap) or 29th (leap)

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-F-02: Jan 30 monthly to Feb
**Steps:** Same for 30th

**Expected:** Feb instance on 28th/29th

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-F-03: Jan 29 monthly to Feb (non-leap)
**Steps:** In non-leap year, 29th task

**Expected:** Feb instance on 28th

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-F-04: Jan 29 monthly to Feb (leap)
**Steps:** In leap year, 29th task

**Expected:** Feb instance on 29th

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

### 6.5 Data Integrity

#### E-D-01: Delete task with pending notification
**Steps:**
1. Create task with reminder
2. Delete task before reminder

**Expected:** Notification removed, does not fire

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-D-02: Delete habit with scheduled alerts
**Steps:**
1. Create habit with alerts
2. Delete habit

**Expected:** All related notifications removed

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

#### E-D-03: Edit recurring task
**Steps:**
1. Edit a recurring task instance
2. Change title

**Expected:** Only current instance changed, recurrence continues

| Pass | Fail | Notes |
|------|------|-------|
| [ ]  | [ ]  |       |

---

## 7. Troubleshooting Guide

### 7.1 Verifying Notification State

#### Check Pending Notifications (Debug)

If running from Xcode, add this debug code temporarily:

```swift
UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
    print("Pending notifications: \(requests.count)")
    for request in requests {
        print("- ID: \(request.identifier)")
        print("  Title: \(request.content.title)")
        print("  Trigger: \(String(describing: request.trigger))")
    }
}
```

#### Console Log Patterns

When debugging, look for these log messages:
- `"Scheduling task notification for..."` - Task reminder being set
- `"Scheduling habit notification for..."` - Habit alert being set
- `"Removing notification with identifier..."` - Notification cancelled
- `"Processing pending recurrences..."` - Deferred tasks being created

### 7.2 Common Issues & Solutions

| Issue | Possible Causes | Solutions |
|-------|-----------------|-----------|
| **No notifications appear** | Permissions denied; Global toggle off; Do Not Disturb active; Focus mode blocking | Check iOS Settings → DaisyDos → Notifications; Check in-app Settings → Notifications; Check Control Center; Check Focus settings |
| **Notification appears but no actions** | NotificationDelegate not set properly | Verify app initialization in console logs |
| **Wrong notification time** | Timezone mismatch; Incorrect trigger type | Check device timezone matches expected behavior |
| **Actions don't work** | App process not available | Try force quitting and reopening app, then test again |
| **Recurring task not created** | maxOccurrences reached; recreateIfIncomplete=false; App not launched/foregrounded | Check recurrence settings; launch app to process pending |
| **Badge count wrong** | Badge not updated on notification | Clear badge manually; verify badge logic in code |
| **Duplicate notifications** | Multiple notification requests created | Check for duplicate scheduling calls |

### 7.3 Debug Checklist

When notifications aren't working:

- [ ] Verify iOS notification permissions (iOS Settings)
- [ ] Verify in-app global toggle is ON
- [ ] Check Do Not Disturb / Focus mode
- [ ] Try creating a new task with 1-minute reminder
- [ ] Check Xcode console for scheduling logs
- [ ] Verify NotificationDelegate is set (check app init logs)
- [ ] Try force quitting and relaunching app
- [ ] Check if device has low power mode (may delay notifications)

### 7.4 Useful Debug Commands (Xcode Console)

```swift
// Print all pending notifications
UNUserNotificationCenter.current().getPendingNotificationRequests { print($0) }

// Print delivered notifications
UNUserNotificationCenter.current().getDeliveredNotifications { print($0) }

// Remove all pending (for testing)
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

// Check authorization status
UNUserNotificationCenter.current().getNotificationSettings { print($0) }
```

---

## 8. Quick Reference Checklists

### 8.1 Smoke Test (5-10 minutes)

Quick validation that core features work:

- [ ] **T-N-01**: Create task with 2-min reminder, verify notification appears
- [ ] **T-N-06**: Complete task from notification action
- [ ] **H-N-01**: Create habit with 2-min reminder, verify notification appears
- [ ] **H-N-12**: Complete habit from notification action
- [ ] **R-D-01**: Create daily recurring task, complete it, verify pending created
- [ ] **I-08**: Toggle global notifications off/on, verify behavior

### 8.2 Full Regression Test (30-60 minutes)

Complete validation before release:

**Task Notifications:**
- [ ] T-N-01 through T-N-05 (Basic reminder creation)
- [ ] T-N-06 through T-N-10 (Notification actions)
- [ ] T-N-11, T-N-12 (Completed task behavior)

**Habit Notifications:**
- [ ] H-N-01 through H-N-05 (Basic reminder creation)
- [ ] H-N-06 through H-N-08 (Completion & rescheduling behavior)
- [ ] H-N-09 through H-N-11 (Recurrence integration)
- [ ] H-N-12 through H-N-16 (Notification actions)

**Recurrence:**
- [ ] R-D-01, R-D-02 (Daily)
- [ ] R-W-01, R-W-02 (Weekly)
- [ ] R-M-01, R-M-02 (Monthly)
- [ ] R-MO-01 (maxOccurrences)
- [ ] R-RI-01, R-RI-02 (recreateIfIncomplete)
- [ ] R-PC-01, R-PC-02 (Deferred creation)

**Integration:**
- [ ] I-01 (Reminder not inherited)
- [ ] I-03 through I-05 (App lifecycle)
- [ ] I-08, I-09 (Global toggle)

**Edge Cases:**
- [ ] E-P-01 (Permission denied)
- [ ] E-T-01 (Past reminder date)
- [ ] E-D-01 (Delete with pending notification)

### 8.3 Edge Case Deep Dive (2+ hours)

For thorough testing of boundary conditions:

- [ ] All E-P tests (Permission states)
- [ ] All E-T tests (Time edge cases)
- [ ] All E-TZ tests (Timezone - requires settings changes)
- [ ] All E-F tests (February - may require date changes)
- [ ] All E-D tests (Data integrity)
- [ ] R-Y-02, R-Y-03 (Leap year - requires long-term or date manipulation)

---

## 9. Test Session Log

Use this template to document each testing session:

```
═══════════════════════════════════════════════════════════════
TEST SESSION LOG
═══════════════════════════════════════════════════════════════

Date: ____________________
Tester: __________________

DEVICE INFORMATION
─────────────────────────────────────────────────────────────────
Device Model: _________________ (e.g., iPhone 15 Pro)
iOS Version: _________________  (e.g., 17.2)
App Version: _________________  (e.g., 1.0 Build 42)
Timezone: ____________________  (e.g., PST, UTC-8)

PRE-TEST CHECKLIST
─────────────────────────────────────────────────────────────────
[ ] Fresh install / Clean data
[ ] Notification permissions granted
[ ] Global notifications enabled in app
[ ] Do Not Disturb OFF
[ ] Focus modes OFF or allowing DaisyDos
[ ] Device charged / plugged in

TEST TYPE
─────────────────────────────────────────────────────────────────
[ ] Smoke Test    [ ] Full Regression    [ ] Edge Case Deep Dive

TESTS EXECUTED
─────────────────────────────────────────────────────────────────
Test IDs Run: ________________________________________________

PASS / FAIL SUMMARY
─────────────────────────────────────────────────────────────────
Total Tests: ______
Passed: ______
Failed: ______
Blocked: ______

FAILED TESTS
─────────────────────────────────────────────────────────────────
Test ID: ________
Expected: ________________________________________________
Actual: __________________________________________________
Steps to Reproduce: ______________________________________
________________________________________________________

Test ID: ________
Expected: ________________________________________________
Actual: __________________________________________________
Steps to Reproduce: ______________________________________
________________________________________________________

ISSUES FOUND
─────────────────────────────────────────────────────────────────
Issue #1: ________________________________________________
Severity: [ ] Critical  [ ] Major  [ ] Minor  [ ] Cosmetic
Description: _____________________________________________
________________________________________________________

Issue #2: ________________________________________________
Severity: [ ] Critical  [ ] Major  [ ] Minor  [ ] Cosmetic
Description: _____________________________________________
________________________________________________________

GENERAL NOTES
─────────────────────────────────────────────────────────────────
________________________________________________________
________________________________________________________
________________________________________________________
________________________________________________________

═══════════════════════════════════════════════════════════════
```

---

## Appendix A: Reminder System Reference

### How Reminders Work

Both tasks and habits use **absolute date/time reminders**. You set a specific date and time, and a notification fires at that exact moment.

| Feature | Tasks | Habits |
|---------|-------|--------|
| Reminder type | Absolute date/time | Absolute date/time |
| Picker UI | Date + Time picker | Date + Time picker |
| On completion | Notification cancelled | Notification rescheduled for next occurrence |
| Recurrence integration | Reminder NOT inherited by next instance | Reminder auto-rescheduled based on recurrence rule |

### Notification Scheduling Logic

**Tasks:**
1. User sets reminder date/time
2. System schedules one-shot notification
3. On task completion: notification cancelled
4. On task deletion: notification cancelled
5. New recurring instance does NOT inherit reminder

**Habits:**
1. User sets reminder date/time
2. System schedules one-shot notification
3. On habit completion: notification rescheduled for next occurrence (same time, next scheduled day)
4. On habit skip: notification rescheduled for next occurrence
5. If habit already completed today: no notification scheduled

## Appendix B: Recurrence Frequency Reference

| Frequency | Description | Special Handling |
|-----------|-------------|------------------|
| Daily | Every X days | None |
| Weekly | Specific days of week | Multiple days supported; week boundary wrapping |
| Monthly | Specific day of month | Day clamping (31→28/30); Feb edge cases |
| Yearly | Specific date annually | Feb 29 → Feb 28 in non-leap years |
| Custom | Every X days | Treated as daily with custom interval |

## Appendix C: Notification Identifier Formats

| Type | Format | Example |
|------|--------|---------|
| Task reminder | `task_{UUID}` | `task_550e8400-e29b-41d4-a716-446655440000` |
| Habit alert (daily) | `habit_{UUID}` | `habit_550e8400-e29b-41d4-a716-446655440000` |
| Habit alert (weekly) | `habit_{UUID}_{0-6}` | `habit_550e8400-...440000_0` (Sunday) |

---

*Last Updated: January 2026*
*DaisyDos Physical Device Testing Guide v1.0*
