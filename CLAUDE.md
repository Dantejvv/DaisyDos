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
- **Charts Framework**: Prepared for future habit analytics (not currently implemented)

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
- TaskRowView and HabitRowView designed for maximum reusability
- Components work across different contexts (lists, search)
- Composition pattern with closure-based actions for flexibility
- Shared micro-components: TagsSectionView, RowActionButton for consistency
- Single display mode (.compact) for focused MVP development

**Navigation Structure:**
- Tab-based navigation with independent NavigationStack per tab
- NavigationManager @Observable class with separate NavigationPath per tab
- Production TabView with 5 main sections (Today, Tasks, Habits, Logbook, Settings)

### Core Systems

**Data Layer:**
- SwiftData models: `Task.swift`, `Habit.swift`, `Tag.swift` with full @Model implementation
- Manager services: `TaskManager.swift`, `HabitManager.swift`, `TagManager.swift` with @Observable business logic
- Three-tier error handling: Platform → App → User error transformation
- Privacy-first approach with local-only mode default

**UI Layer:**
- Design system with 8pt grid, WCAG AA colors, liquid glass aesthetic
- Reusable components: `CardView`, `DaisyButton`, `InputField`, `StateViews`
- Full accessibility compliance with VoiceOver support and Dynamic Type scaling
- Performance optimized for large datasets (1000+ items)

## Current Codebase Status

### Foundation & Core Architecture
**Navigation & Infrastructure:**
- Complete tab-based navigation (Today, Tasks, Habits, Logbook, Settings)
- Privacy-first local-only data storage (CloudKit configured but disabled by default)
- WCAG AA accessibility compliance throughout
- Professional UI with liquid glass design aesthetic
- 5-tab navigation with independent NavigationStack per tab

### Task Management System
**Core Task Features:**
- Complete CRUD operations with validation
- Priority System: Low/Medium/High with visual indicators
- Due Dates & Start Dates: Full date management with validation
- Task Descriptions: Rich text descriptions
- Subtask Relationships: One-level hierarchy (tasks can have subtasks, subtasks cannot have subtasks)
- File Attachments: PhotoKit integration, 50MB per file, 200MB per task limit
- Recurrence Rules: Daily/weekly/monthly/yearly patterns with dynamic calculations
- Advanced Filtering: Priority, due date, overdue, smart sectioning

**Task UI Components:**
- TaskRowView: Reusable composition pattern with action closures
- TaskDetailView: Comprehensive display with subtask and attachment management
- TaskEditView: Dedicated editing with validation and change detection
- TasksView: Multi-select, bulk operations, context menus
- Subtask Management: Order-based reordering, progress visualization
- Attachment System: Complete PhotoKit integration with gallery and preview
- Shared micro-components: TagsSectionView, RowActionButton

**TaskRowView Architecture (Proven Pattern):**
- Composition pattern API with action closures for maximum reusability
- Environment dependencies removed for pure presentation
- Display mode: .compact (primary focus)
- Cross-context validated: Works identically across TasksView, search results
- Performance optimized with conditional UI

### Habit Tracking System
**Core Habit Features:**
- Complete CRUD operations with validation
- Enhanced Habit model with RecurrenceRule integration
- HabitCompletion model for individual completion tracking
- HabitStreak model for streak management
- Simple consecutive day streak tracking
- Skip functionality with optional reason text
- Undo completion with automatic streak recalculation
- Character limits: 50 chars title, 200 chars description
- Real-time form validation with error/warning separation

**Habit UI Components:**
- HabitRowView: Follows TaskRowView patterns exactly with composition pattern
- HabitDetailView: Comprehensive display with statistics and completion history
- HabitEditView: Advanced validation with character count indicators
- HabitsView: Reuses HabitRowView component
- SimpleHabitSkipView: Reason input interface
- HabitCompletionUndoToast: 5-second countdown timer
- Visual feedback for completed, skipped, and pending states

**HabitRowView Architecture (Consistent with Tasks):**
- Composition pattern with action closures (onMarkComplete, onEdit, onDelete, onSkip)
- Display mode: .compact (primary focus)
- Habit-specific features: streak display, grace period indicators
- Comprehensive accessibility support with VoiceOver labels and 44pt touch targets
- Shared micro-components with TaskRowView

**Notifications (Basic Infrastructure):**
- HabitNotificationManager: Basic @Observable notification service (~300 LOC)
- HabitNotificationSettingsView: Permission management UI
- Settings integration in main SettingsView
- **Not Yet Complete**: Full smart scheduling for all recurrence patterns, notification actions for quick completion/skip

### Tag System
**Tag Features:**
- 3-tag limit per task/habit with automatic enforcement
- 30-tag system limit with real-time validation
- SF Symbol icon selection
- System color assignment
- Full CRUD operations with tag assignment UI
- Tag deletion with usage validation and undo support
- Swipe-to-delete and context menus in TagsView and TagEditView

### Logbook System
**Task History & Archival:**
- TaskLogEntry model: Lightweight snapshots of completed tasks
- Tiered retention: 0-90 days (full Task), 91-365 days (TaskLogEntry), 365+ days (deleted)
- Automatic archival system runs every 24 hours on app launch
- LogbookView with @Query for automatic real-time updates
- Period filtering: 7 days, 30 days, 90 days, This Year
- Search by title and description across completed tasks
- LogEntryRow component for lightweight archived task display
- TaskRowView reused for recent completions (0-90 days)
- Completed tasks automatically hidden from TasksView

**Technical Implementation:**
- Manual Swift filtering (SwiftData #Predicate has issues with optional Date comparisons)
- @Query-based real-time updates (automatic cross-tab sync)
- Environment injection of LogbookManager in DaisyDosApp

### Settings & Configuration
**Current Settings:**
- Basic SettingsView implementation
- Habit notification settings integration
- Privacy controls foundation (local-only mode toggle exists)
- CloudKit configuration prepared but disabled

### Features in Initial State (Not Complete)
**Calendar Integration:**
- EventKit permissions framework exists
- No calendar views or integration UI implemented yet

**Advanced Analytics:**
- Charts framework prepared for habit analytics
- No visualization components implemented yet
- CompletionAggregate model prepared but unused

**Today View:**
- Tab exists in navigation
- Core unified view not yet implemented

## File Organization

### Current Architecture
```
DaisyDos/
├── Features/
│   ├── Tasks/ - Complete task management system
│   │   ├── Models/ (Task.swift, Priority.swift, RecurrenceRule.swift, TaskAttachment.swift)
│   │   ├── Views/ (TaskRowView.swift, TaskDetailView.swift, TaskEditView.swift, TasksView.swift)
│   │   ├── Services/ (TaskManager.swift, TaskManager+Subtasks.swift, TaskManager+Attachments.swift)
│   │   └── Subtasks/, Attachments/, Recurrence/ (Complete subsystems)
│   │
│   ├── Habits/ - Core habit management (notifications basic, analytics prepared)
│   │   ├── Models/ (Habit.swift, HabitCompletion.swift, HabitStreak.swift, HabitSkip.swift)
│   │   ├── Views/ (HabitsView.swift, HabitRowView.swift, HabitDetailView.swift, HabitEditView.swift)
│   │   └── Services/ (HabitManager.swift, HabitNotificationManager.swift)
│   │
│   ├── Tags/ - Complete tag system
│   │   ├── Models/ (Tag.swift)
│   │   ├── Views/ (TagsView.swift, TagEditView.swift, TagPickerView.swift)
│   │   └── Services/ (TagManager.swift)
│   │
│   ├── Logbook/ - Task history with tiered retention
│   │   ├── Models/ (TaskLogEntry.swift, CompletionAggregate.swift [unused])
│   │   ├── Views/ (LogbookView.swift, LogEntryRow.swift)
│   │   └── Services/ (LogbookManager.swift)
│   │
│   ├── Today/ - Basic tab shell (unified view not implemented)
│   └── Settings/ - Basic settings UI
│
├── Core/ - Complete foundation
│   ├── Design/ (Design system, reusable components)
│   ├── Data/ (SwiftData schemas V1-V4, CloudKit foundation)
│   ├── ErrorHandling/ (Three-tier error system)
│   └── Navigation/ (NavigationManager, TabConfiguration)
│
├── DaisyDosTests/ - Testing infrastructure (118 tests, 100% pass)
│   ├── Unit/ (RecurrenceRuleTests, HabitModelTests, TaskModelTests, etc.)
│   ├── Infrastructure/ (TestHelpers, container validation)
│   └── Documentation/ (TestingGuide.md)
```

## Key Implementation Principles

### **Critical: Component Consistency**
1. **Composition over Inheritance** - Use action closures for reusability (proven in TaskRowView and HabitRowView)
2. **Cross-Context Validation** - Components must work across multiple contexts (lists, search, detail views)
3. **Display Mode Support** - Primary focus on .compact mode for clarity
4. **Shared Patterns** - HabitRowView follows TaskRowView patterns exactly for consistency

### **Established Architectural Patterns**
1. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
2. **Privacy by Default**: All features work locally before any cloud integration
3. **Error Handling Excellence**: Three-tier system transforms errors to user-friendly messages
4. **Accessibility Excellence**: WCAG 2.1 AA compliance with 44pt touch targets
5. **Performance Focus**: Optimized for large datasets with efficient SwiftData queries
6. **SwiftData Patterns**: Use @Query for UI updates, explicit order properties for relationships
7. **Testing First**: Use Swift Testing framework with struct-based suites and fresh containers per test

### **Domain-Specific Patterns**
1. **Recurrence Rules**: Shared RecurrenceRule struct used by both Tasks and Habits
2. **Streak Calculations**: Simple consecutive day streak logic for habits
3. **Completion Tracking**: Separate HabitCompletion model for individual completion entries
4. **Data Retention**: Tiered retention system (90 days → 365 days → deletion)
5. **Charts Integration**: Charts framework prepared for habit analytics (not yet implemented)

## Development Guidelines

### Architecture Validation Status
**Component Reusability:**
- TaskRowView proven reusable across multiple contexts (TasksView, search results, Logbook)
- HabitRowView follows identical patterns with action closure composition
- Shared micro-components (TagsSectionView, RowActionButton) working across features
- Cross-context consistency validated and performant

**Quality Metrics:**
- Build Status: Builds cleanly with only minor warnings
- Performance: Handles 100+ tasks/habits efficiently with optimized queries
- Accessibility: Full VoiceOver support with proper labels and 44pt touch targets

**Known Patterns:**
- @Observable models with business logic (no ViewModels)
- Composition pattern with action closures for UI components
- SwiftData @Query for reactive UI updates
- Manual Swift filtering when SwiftData #Predicate has limitations
- Fresh ModelContainer per test for perfect isolation

Refer to `/Docs/implementation_roadmap.md` for detailed feature planning.

---

## Testing Infrastructure

### Production-Ready Testing

**Status:** 118 tests, 100% pass rate, 0.226s execution time

**Framework:** Swift Testing (modern @Test macro, #expect assertions)

**Test Coverage:**
- RecurrenceRule: 35 tests (date calculations, leap years, boundaries)
- Habit Model: 20 tests (streak logic, completion tracking)
- Task Model: 24 tests (completion cascading, relationships)
- TaskManager: 20 tests (CRUD operations, filtering)
- HabitSkip: 15 tests (impact analysis)
- Infrastructure: 4 tests (container validation, isolation)

**Key Testing Pattern:**
```swift
@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testFeature() async throws {
        // Fresh container per test = perfect isolation
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let manager = FeatureManager(modelContext: context)
        let result = manager.performOperation()

        // Pattern matching for Result types
        guard case .success(let value) = result else {
            Issue.record("Failed to perform operation")
            return
        }

        #expect(value.isValid)
    }
}
```

**Best Practices:**
- ✅ Struct-based test suites (value semantics, isolation)
- ✅ Fresh container per test (no shared state)
- ✅ Pattern match Result types (`guard case .success`)
- ✅ Use #expect assertions (not XCTAssert)
- ❌ Don't store containers in properties
- ❌ Don't share state between tests

**Documentation:** See `/DaisyDosTests/Documentation/TestingGuide.md` for comprehensive patterns, examples, and how-to guides

---

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies.**

