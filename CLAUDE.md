# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DaisyDos is a unified iOS productivity application built with SwiftUI that integrates task management and habit tracking. The app targets iOS 17.0+ and uses SwiftData for data persistence with CloudKit integration prepared but disabled by default for privacy.

## Build Commands

This is a standard Xcode project. Use Xcode to build and run:

- **Build**: Cmd+B in Xcode or `xcodebuild build -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Run**: Cmd+R in Xcode to run on simulator/device
- **Test**: Cmd+U in Xcode or `xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Archive**: Product → Archive in Xcode for distribution

### Framework Compatibility Notes

- **PhotoKit**: Not available on iOS Simulator. Code uses conditional import `#if canImport(PhotoKit)` to handle simulator builds
- **EventKit/UserNotifications/CloudKit**: Work on both simulator and device


## Architecture Overview

### Core Technologies
- **SwiftUI + SwiftData**: Modern declarative UI with Core Data successor
- **@Observable Pattern**: State management using Swift's @Observable macro
- **CloudKit Foundation**: Configured but disabled by default (local-only mode)
- **iOS 17.0+ Target**: Leverages latest SwiftData and SwiftUI features
- **SwiftTesting**: Swifts modern testing framework

### Key Architectural Patterns

**Apple's Model-View (MV) Pattern:**
- Models: @Observable classes with business logic (Task, Habit models + Manager services)
- Views: Pure SwiftUI presentation, no business logic
- Services: Lightweight coordinators for queries and external I/O
- No ViewModels: Business logic lives directly in observable models

**Shared Component Strategy:**

Core Philosophy:
- **Composition over inheritance** - Components use action closures instead of environment dependencies for maximum reusability
- **Cross-context validation** - All components work identically across lists, search, detail views, and navigation contexts
- **Single display mode (.compact)** - Focused MVP development, no display mode complexity
- **Pure presentation** - Components receive data and callbacks, contain no business logic

Component Architecture:
- **Row Components**: TaskRowView and HabitRowView follow identical composition patterns with closure-based actions
- **Shared Micro-Components** (`Core/Design/Components/Shared/`): Buttons, Fields, Pickers, Rows, Sections, DetailViews, Layout primitives
- **Tag Components**: TagChipView (full), IconOnlyTagChipView (compact), TagInfoSheet (details)
- All components validated for reusability across multiple contexts and performance-tested with 100+ items

Key Patterns:
- Closure-based action handlers (no environment manager coupling)
- Priority-based background colors, conditional layouts for active vs completed states
- 44pt minimum touch targets, comprehensive VoiceOver support
- Shared metadata indicators (subtasks, attachments, alerts, recurrence)

**Navigation Structure:**

Architecture:
- Tab-based navigation with **independent NavigationStack per tab**
- `NavigationManager` @Observable class with separate `NavigationPath` for each tab
- Tab switching preserves navigation state within each stack
- All tabs injected via `.environment()` at app root for global access

5 Main Tabs:
1. **Today** - Unified daily overview (fully implemented)
2. **Tasks** - Complete task management (fully implemented)
3. **Habits** - Habit tracking with streaks (fully implemented)
4. **Logbook** - Task completion history (fully implemented)
5. **Settings** - App configuration (fully implemented)

Key Files:
- `NavigationManager` (`Core/Navigation/NavigationManager.swift`) - Central navigation coordination
- `TabConfiguration` (`Core/Navigation/TabConfiguration.swift`) - Tab definitions and appearance
- `ContentView` (`App/ContentView.swift`) - TabView with NavigationStack per tab

Navigation Patterns:
- Each tab maintains isolated navigation history
- `navigationManager.pathBinding(for: .tabName)` binds each stack
- Deep linking foundation prepared for future implementation

### Core Systems

**Data Layer:**
- SwiftData models with @Model implementation (Task, Habit, Tag, etc.)
- Manager services with @Observable business logic (TaskManager, HabitManager, TagManager, etc.)
- Three-tier error handling: Platform → App → User error transformation
- Privacy-first: local-only mode by default, CloudKit configured but disabled

**UI Layer:**
- Design system: 8pt grid, WCAG AA accessibility, liquid glass aesthetic
- Reusable component library in `Core/Design/Components/`
- Full VoiceOver support and Dynamic Type scaling throughout
- Performance optimized for large datasets (1000+ items tested)


## File Organization

```
DaisyDos/
├── App/                          # App entry point, ContentView, main setup
├── Core/
│   ├── Data/                     # SwiftData schemas, CloudKit foundation
│   ├── Design/                   # Design system, reusable components
│   ├── ErrorHandling/            # Three-tier error system
│   ├── Models/                   # Shared models (Priority, RecurrenceRule, etc.)
│   ├── Navigation/               # NavigationManager, TabConfiguration
│   └── Services/                 # Shared service protocols
└── Features/
    ├── Tasks/                    # Task management (Models, Views, Services)
    ├── Habits/                   # Habit tracking (Models, Views, Services)
    ├── Tags/                     # Tag system (Models, Views, Services)
    ├── Logbook/                  # Task history (Models, Views, Services)
    ├── Today/                    # Daily overview (fully implemented)
    └── Settings/                 # App settings

DaisyDosTests/                    # Swift Testing framework, 190 tests
├── Unit/                         # Domain logic and manager tests
├── Helpers/                      # Test utilities and helpers
└── Documentation/                # TestingGuide.md
```

**Key Patterns:**
- Each feature has `/Models`, `/Views`, `/Services` subdirectories
- Shared components live in `Core/Design/Components/Shared/`
- Tests mirror production structure in `DaisyDosTests/`

## Current Codebase Status

### Task Management System - FULLY IMPLEMENTED
- Complete CRUD operations with validation
- Priority system (None/Low/Medium/High), due dates, rich text descriptions
- **Subtasks**: One-level hierarchy with order-based management
- **Attachments**: Full PhotoKit integration, 50MB/file, 200MB/task limits
- **Recurrence**: Daily/weekly/monthly/yearly patterns with dynamic calculations
- **Notifications**: Alert reminders before due date, overdue reminders, snooze functionality
- Advanced filtering, multi-select, bulk operations, search
- UI: TaskRowView, TaskDetailView, TaskEditView, TasksView, TaskNotificationSettingsView (all production-ready)

### Habit Tracking System - FULLY IMPLEMENTED
- Complete CRUD operations with completion tracking and streak management
- **Subtasks**: Daily-reset subtask system with completion tracking
- **Attachments**: Full system identical to tasks (50MB/file, 200MB/habit)
- Skip functionality with optional reason, undo completion with 5-second timer
- RecurrenceRule integration, priority system, character limits (50 title, rich text description)
- **Notifications**: Basic infrastructure complete (HabitNotificationManager, permissions, settings UI)
  - *Not yet complete*: Full smart scheduling for all edge cases
- UI: HabitRowView, HabitDetailView, HabitEditView, HabitsView (all production-ready)

### Tag System - FULLY IMPLEMENTED
- **5-tag limit per item**, 30-tag system limit
- SF Symbol icons, system colors, full CRUD operations
- Tag deletion with usage validation, undo support
- UI: TagsView, TagEditView, TagSelectionView with swipe-to-delete

### Logbook System - FULLY IMPLEMENTED
- Tiered retention: 0-90 days (full Task), 91-365 days (TaskLogEntry), 365+ (deleted)
- Automatic archival every 24 hours on app launch
- Period filtering (7/30/90 days, This Year), search by title/description
- UI: LogbookView, LogEntryRow with @Query real-time updates

### Settings - FULLY IMPLEMENTED
- **Appearance settings**: Theme (system/light/dark), accent color selection (7 colors)
- **Privacy controls**: Local-only mode toggle with CloudKit sync status view
- **Notification settings**: Habit and task reminder configuration
- Data overview (counts), tag management, about view
- Import/export functionality, reset/delete options
- CloudKit sync status and controls (when enabled)

### Today View - FULLY IMPLEMENTED
- Unified task/habit list with TodayItem model and TodayViewModel
- Multiple sort options: time, priority, type, title
- Show/hide completed items toggle
- Multi-select mode with bulk completion and deletion
- Search functionality across tasks and habits
- Swipe actions: edit, delete, duplicate, skip (habits), reschedule (tasks)
- Quick add menu for tasks and habits
- Detail navigation for both tasks and habits
- User accent color support via AppearanceManager
- UI: TodayView, UnifiedTodayRow (production-ready)

### CloudKit Integration - FULLY IMPLEMENTED
- **Container ID**: `iCloud.com.BKD7HH7ZDH.DaisyDos`
- **User-Controlled Toggle**: Privacy-first approach - local-only mode by default
- **Dynamic ModelConfiguration**: Switches between `.none` and `.automatic` based on user preference
- **Conflict Resolution**: Last-write-wins strategy using `modifiedDate` timestamps
- **Offline Queue**: Pending changes queued and synced when connection returns
- **Network Monitoring**: Real-time connectivity tracking with Network framework
- **CloudKit Schema**: Removed `#Unique` constraints for CloudKit compatibility
- **Managers**: CloudKitSyncManager, OfflineQueueManager, NetworkMonitor
- **Settings UI**: CloudKit toggle, CloudKitSyncStatusView with manual sync, iCloud account status
- **Error Handling**: User-friendly CloudKit error messages with actionable guidance
- **Note**: Requires app restart when changing sync mode

### Habit Analytics - FULLY IMPLEMENTED
- **Analytics Manager**: Centralized analytics with caching for performance
- **Data Aggregation**: Weekly completions, mood trends, streak data, time-of-day distribution
- **Chart Components**: Weekly completion chart, mood trends chart, streak dashboard, completion rate pie chart
- **Period Selection**: 7D, 30D, 90D, Year views with dynamic data
- **UI Integration**: Analytics section in HabitDetailView with period selector and summary stats
- **Performance**: Cached queries, optimized for 90+ day periods

### Incomplete Features (Future Development)
- **Calendar Integration**: EventKit permissions removed for MVP (can add post-launch if requested)
- **Task Analytics**: Habit analytics complete, task analytics deferred to post-MVP
- **Advanced Notification Scheduling**: Basic scheduling complete (90%), edge cases remain (timezone changes, DST transitions, conflict resolution)


## Testing Infrastructure

**Framework:** Swift Testing (modern @Test macro, #expect assertions)

**Coverage:** 199 tests, 100% pass rate
- Domain models (Task, Habit, RecurrenceRule, etc.)
- Manager services (CRUD operations, business logic)
- Infrastructure validation (container isolation, data integrity)

**Key Testing Patterns:**
```swift
@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testFeature() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let manager = FeatureManager(modelContext: context)
        let result = manager.performOperation()

        guard case .success(let value) = result else {
            Issue.record("Operation failed")
            return
        }

        #expect(value.isValid)
    }
}
```

**Best Practices:**
- ✅ Struct-based test suites for isolation
- ✅ Fresh ModelContainer per test (no shared state)
- ✅ Pattern match Result types (`guard case .success`)
- ✅ Use #expect assertions (not XCTAssert)
- ❌ Don't store containers in properties
- ❌ Don't share state between tests

**Documentation:** See `DaisyDosTests/Documentation/TestingGuide.md`

---

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies.**

