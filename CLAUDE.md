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
- **Charts Framework**: Available for habit progress visualization (iOS 16+)

## Architecture Overview

### Core Technologies
- **SwiftUI + SwiftData**: Modern declarative UI with Core Data successor
- **@Observable Pattern**: State management using Swift's @Observable macro
- **CloudKit Foundation**: Configured but disabled by default (local-only mode)
- **iOS 17.0+ Target**: Leverages latest SwiftData and SwiftUI features

### Key Architectural Patterns

**Apple's Model-View (MV) Pattern:**
- Models: @Observable classes with business logic (Task, Habit models + Manager services)
- Views: Pure SwiftUI presentation, no business logic
- Services: Lightweight coordinators for queries and external I/O
- No ViewModels: Business logic lives directly in observable models

**Shared Component Strategy:**
- TaskRowView and HabitRowView designed for maximum reusability
- Components work across different contexts (lists, search, Today view)
- Composition pattern with closure-based actions for flexibility

**Navigation Structure:**
- Tab-based navigation with independent NavigationStack per tab
- NavigationManager @Observable class with separate NavigationPath per tab
- Production TabView with 6 main sections (Today, Tasks, Habits, Logbook, Tags, Settings)

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

## Current Development Status

### ✅ **Phase 1.0 Complete: Foundation & Architecture**
- Complete tab-based navigation (Today, Tasks, Habits, Tags, Settings)
- Privacy-first local-only data storage
- WCAG AA accessibility compliance
- Professional UI with liquid glass design aesthetic
- Performance monitoring and developer tools

### ✅ **Phase 2.0 Complete: Advanced Task Management**
**Task Model & Features:**
- Priority System: Low/Medium/High with visual indicators
- Due Dates & Start Dates: Full date management with validation
- Task Descriptions: Rich text descriptions
- Subtask Relationships: One-level subtasks only (tasks can have subtasks, subtasks cannot have subtasks)
- File Attachments: PhotoKit integration, 50MB per file, 200MB per task limit
- Recurrence Rules: Daily/weekly/monthly/yearly patterns with dynamic calculations
- Advanced Filtering: Priority, due date, overdue, smart sectioning

**TaskRowView Reusability Pattern (PROVEN ARCHITECTURE):**
- ✅ **Composition Pattern API**: Action closures for maximum reusability
- ✅ **Environment Dependencies Removed**: Pure presentation component
- ✅ **Multiple Display Modes**: .compact, .detailed, .today modes
- ✅ **Cross-Context Validation**: Works identically across TasksView, search, Today view
- ✅ **Performance Optimized**: Efficient rendering with conditional UI

**Complete Task Management:**
- TaskDetailView: Comprehensive display with subtask and attachment management
- TaskEditView: Dedicated editing with validation and change detection
- Enhanced TasksView: Multi-select, bulk operations, context menus
- Subtask Management: One-level hierarchy, order-based reordering, progress visualization
- Attachment System: Complete PhotoKit integration with gallery and preview
- Recurrence System: Full UI integration with preset and custom patterns

**Tag System:**
- 3-tag limit per task/habit with automatic enforcement
- 30-tag system limit with real-time validation
- SF Symbol & Color selection interfaces
- Full CRUD operations with tag assignment UI

### ✅ **Phase 3.1 Complete: Enhanced Habit Data Models**
- ✅ Enhanced Habit model with RecurrenceRule integration
- ✅ HabitCompletion model for individual completion tracking
- ✅ HabitStreak model for advanced streak management
- ✅ Simple streak tracking with consecutive day logic
- ✅ Simplified skip functionality with optional reason text
- ✅ SwiftData schema integration and build validation

### ✅ **Phase 3.2 Complete: HabitRowView Component Consistency**
- ✅ Standalone HabitRowView following TaskRowView patterns exactly
- ✅ Composition pattern with action closures (onMarkComplete, onEdit, onDelete, onSkip)
- ✅ Display modes: .compact, .detailed, .today matching TaskRowView
- ✅ Habit-specific features: streak display, grace period indicators, recurrence integration
- ✅ Comprehensive accessibility support with VoiceOver labels and 44pt touch targets
- ✅ Extracted embedded HabitRowView from HabitsView for true reusability
- ✅ Build validation with clean compilation

### ✅ **Phase 3.3 Complete: Analytics & Progress Tracking**
- ✅ **Enhanced Streak Calculation System**
  - Accurate streak calculation with grace period logic in `HabitManager+Analytics.swift`
  - Milestone progress tracking (7, 14, 21, 30, 50, 75, 100+ day milestones)
  - Streak quality scoring based on consistency and grace period usage
  - Momentum indicators (accelerating, strong, steady, slowing, stagnant)

- ✅ **Charts Framework Integration**
  - `HabitProgressChart.swift` - Interactive line/area charts with tap-to-explore functionality
  - `HabitHeatmapView.swift` - GitHub-style calendar heatmap with intensity visualization
  - `StreakVisualizationView.swift` - Bar chart visualization with milestone tracking
  - Smooth animations and responsive design across device sizes

- ✅ **Comprehensive Analytics UI**
  - `HabitDetailView.swift` - Complete detail view with tabbed interface (Overview, Analytics, History)
  - `HabitEditView.swift` - Dedicated editing interface for habit properties
  - Progress metrics dashboard with completion rates, consistency scoring, and mood correlation
  - Professional visualizations following Apple's design guidelines

- ✅ **Advanced Data Models & Analytics**
  - `ChartDataPoint`, `HeatmapDataPoint`, `MilestoneProgress` supporting types
  - Comprehensive analytics methods in `HabitManager+Analytics.swift`
  - Real-time data aggregation with performance optimization for large datasets
  - Privacy-first approach with all analytics computed locally

### ✅ **Phase 3.4 COMPLETE: Advanced Habit Management Features**
**Status: Production Ready**

**Successfully Implemented:**

#### ✅ **Priority 1: Habit Creation & Editing Enhancement**
**Enhanced Habit Management:**
- ✅ Enhanced `AddHabitView.swift` - Advanced validation with character limits and severity levels
- ✅ Real-time form validation with error/warning separation
- ✅ Character count indicators with color-coded feedback (50 chars title, 200 chars description)
- ✅ Improved user experience with ValidationSeverity enum system

#### ✅ **Priority 2: Enhanced Completion System**
**Improved Completion Experience:**
- ✅ Undo completion functionality with `undoTodaysCompletion()` method and automatic streak recalculation
- ✅ HabitCompletionUndoToast integration with 5-second countdown timer
- ✅ Enhanced skip functionality with `SimpleHabitSkipView` and reason input
- ✅ Complete HabitSkip SwiftData model with analytics and impact assessment
- ✅ Visual feedback for completed, skipped, and pending habit states in HabitRowView

#### ✅ **Priority 3: UserNotifications Integration**
**Smart Reminder System:**
- ✅ HabitNotificationManager with comprehensive @Observable notification service
- ✅ Smart scheduling supporting daily, weekly, monthly, yearly, and custom recurrence patterns
- ✅ Notification actions for quick completion and skip directly from notifications
- ✅ HabitNotificationSettingsView with complete permission management UI
- ✅ Settings integration in main SettingsView for easy access

### ✅ **Phase 3.6 COMPLETE: Logbook - Task History & Auto-Archive System**
**Status: Production Ready**

**Successfully Implemented:**

#### ✅ **Task History Tracking**
**Simple History Management:**
- ✅ TaskLogEntry model - Lightweight snapshots of completed tasks
- ✅ Tiered retention: 0-90 days (full Task), 91-365 days (TaskLogEntry), 365+ (deleted)
- ✅ Automatic archival system runs every 24 hours on app launch
- ✅ No analytics or statistics - focused on simple history viewing

#### ✅ **Real-Time Logbook UI**
**Reactive History Display:**
- ✅ LogbookView with @Query for automatic real-time updates
- ✅ Period filtering: 7 days, 30 days, 90 days, This Year
- ✅ Search by title and description across completed tasks
- ✅ LogEntryRow component for lightweight archived task display
- ✅ TaskRowView reused for recent completions (0-90 days)
- ✅ Completed tasks automatically hidden from TasksView

#### ✅ **Technical Implementation**
**Key Architectural Decisions:**
- ✅ Manual Swift filtering (SwiftData #Predicate has issues with optional Date comparisons)
- ✅ @Query-based real-time updates (automatic cross-tab sync)
- ✅ Environment injection of LogbookManager in DaisyDosApp
- ✅ 6-tab navigation: Today, Tasks, Habits, **Logbook**, Tags, Settings

## File Organization

### Current Architecture
```
DaisyDos/
├── Features/
│   ├── Tasks/ ✅ COMPLETE
│   │   ├── Models/ (Task.swift, Priority.swift, RecurrenceRule.swift, TaskAttachment.swift)
│   │   ├── Views/ (TaskRowView.swift, TaskDetailView.swift, TaskEditView.swift, etc.)
│   │   ├── Services/ (TaskManager.swift, TaskManager+Subtasks.swift, TaskManager+Attachments.swift)
│   │   └── Subtasks/, Attachments/, Recurrence/ (Complete subsystems)
│   │
│   ├── Habits/ ✅ PHASE 3.3 COMPLETE - Advanced Analytics & Full UI
│   │   ├── Models/ (Habit.swift ✅, HabitCompletion.swift ✅, HabitStreak.swift ✅)
│   │   ├── Views/ (HabitsView.swift ✅, HabitRowView.swift ✅, HabitDetailView.swift ✅, HabitEditView.swift ✅)
│   │   │   └── Analytics/ (HabitProgressChart.swift ✅, HabitHeatmapView.swift ✅, StreakVisualizationView.swift ✅)
│   │   └── Services/ (HabitManager.swift ✅, HabitManager+Analytics.swift ✅)
│   │
│   ├── Tags/ ✅ COMPLETE
│   ├── Today/ ✅ READY - Phase 3.3 complete, awaiting integration
│   └── Settings/ ✅ BASIC
│
├── Core/ ✅ COMPLETE
│   ├── Design/ (Complete design system)
│   ├── Data/ (SwiftData schemas, CloudKit foundation)
│   ├── ErrorHandling/ (Three-tier error system)
│   └── Navigation/ (NavigationManager, TabConfiguration)
```

### ✅ **Phase 3.3 Achievement: Analytics System Architecture**
```
Features/Habits/Analytics/ ✅ COMPLETE
├── HabitProgressChart.swift ✅ - Interactive line/area charts with Charts framework
├── HabitHeatmapView.swift ✅ - GitHub-style calendar heatmap
└── StreakVisualizationView.swift ✅ - Bar chart with milestone tracking

Services/HabitManager+Analytics.swift ✅ - Comprehensive analytics engine:
├── Enhanced streak calculation with grace periods
├── Milestone progress tracking (7-365 day milestones)
├── Progress metrics (completion rate, consistency, momentum)
├── Chart data generation for all visualization types
├── Heatmap data with intensity-based visualization
└── Performance optimized for large datasets (1000+ completions)

Supporting Types ✅:
├── ChartDataPoint, HeatmapDataPoint (with Equatable conformance)
├── MilestoneProgress, ProgressMetrics
├── AnalyticsPeriod, TrendDirection, ChartType
└── All chart visualization supporting structures
```

## Key Implementation Principles

### **Critical: Component Consistency**
1. **HabitRowView MUST follow TaskRowView patterns exactly** - This is non-negotiable for Phase 4
2. **Composition over Inheritance** - Use action closures for reusability
3. **Display Mode Support** - .compact, .detailed, .today modes required
4. **Cross-Context Validation** - Must work in HabitsView, Today view, search results

### **Established Patterns (DO NOT CHANGE)**
1. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
2. **Privacy by Default**: All features work locally before any cloud integration
3. **Error Handling Excellence**: Three-tier system transforms errors to user-friendly messages
4. **Accessibility Excellence**: WCAG 2.1 AA compliance with 44pt touch targets
5. **Performance Focus**: Optimized for large datasets with efficient SwiftData queries
6. **SwiftData Patterns**: Use @Query for UI updates, explicit order properties for relationships

### **New Patterns for Phase 3**
1. **Charts Integration**: Use Charts framework for habit progress visualization
2. **Streak Calculations**: Implement simple consecutive day streak logic
3. **Completion Tracking**: Separate HabitCompletion model for individual completion entries
4. **Visual Feedback**: Rich progress indicators and heatmap visualizations

## Development Guidelines

### ✅ **Phase 3 Success Criteria ACHIEVED**
- ✅ HabitRowView proven reusable across 3+ contexts (HabitsView, Today view, search)
- ✅ Shared UI patterns consistent with TaskRowView (composition pattern, display modes)
- ✅ Accurate streak calculations with grace periods and milestone tracking
- ✅ Visual progress feedback compelling and motivating (Charts framework integration)
- ✅ Recurrence system working for both tasks and habits
- ✅ Component reusability patterns proven scalable and performant

### ✅ **Quality Gates PASSED**
- ✅ **Build Status**: Builds cleanly with only minor warnings (unused preview variables)
- ✅ **Cross-Context Testing**: HabitRowView works identically across all contexts
- ✅ **Performance**: Handles 100+ habits efficiently with optimized data aggregation
- ✅ **Accessibility**: Full VoiceOver support with proper labels and 44pt touch targets

### ✅ **Phase 4 Readiness Checklist COMPLETE**
- ✅ Standalone HabitRowView component created and tested extensively
- ✅ HabitRowView supports all display modes (.compact, .detailed, .today)
- ✅ Action closure pattern implemented for maximum cross-context reusability
- ✅ Advanced habit completion, streak tracking, and analytics functional
- ✅ Performance validated with realistic data sets and large completion histories
- ✅ **NEW**: Comprehensive analytics system with Charts framework integration
- ✅ **NEW**: Professional data visualizations (progress charts, heatmaps, streak visualization)
- ✅ **NEW**: Complete HabitDetailView with tabbed analytics interface

Refer to `/Docs/implementation_roadmap.md` for detailed development tasks and `/Docs/daisydos_prd.md` for comprehensive requirements.

---

## Testing Infrastructure

### ✅ **Production-Ready Testing (October 2025)**

**Status:** ✅ **COMPLETE** - 118 tests, 100% pass rate, 0.226s execution time

**Test Organization:**
```
DaisyDosTests/
├── Helpers/
│   └── TestHelpers.swift (Production-ready helpers with DaisyDosSchemaV4)
├── Unit/
│   ├── InfrastructureTests.swift (4 tests - container validation)
│   ├── Models/
│   │   ├── RecurrenceRuleTests.swift (35 tests - date calculations)
│   │   ├── HabitModelTests.swift (20 tests - streak logic)
│   │   ├── HabitSkipTests.swift (15 tests - impact analysis)
│   │   └── TaskModelTests.swift (24 tests - completion cascading)
│   └── Services/
│       └── TaskManagerTests.swift (20 tests - CRUD operations)
└── Documentation/
    └── TestingGuide.md (Comprehensive testing guide)
```

**Running Tests:**
- **All tests:** `Cmd+U` in Xcode or `xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Specific suite:** `xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DaisyDosTests/RecurrenceRuleTests`
- **Test Navigator:** `Cmd+6` in Xcode

**Framework:** 100% Swift Testing (modern @Test macro, #expect, pattern matching)

**Test Coverage:**
- ✅ **118 tests** covering critical business logic
- ✅ **RecurrenceRule (35 tests):** Daily/weekly/monthly/yearly patterns, leap years, boundaries
- ✅ **Habit Model (20 tests):** Streak calculations, completion tracking, tag management
- ✅ **Task Model (24 tests):** Parent-child completion cascading, subtask relationships
- ✅ **TaskManager (20 tests):** CRUD operations, filtering, search, tag management
- ✅ **HabitSkip (15 tests):** Impact calculation (6 severity levels), frequency analysis
- ✅ **Infrastructure (4 tests):** Container creation, test isolation verification

**Performance:**
- ⚡ **0.226 seconds** for all 118 tests (~1.9ms per test)
- 🚀 **Perfect isolation** - Fresh in-memory container per test
- 🔄 **Parallel execution** - Tests run concurrently by default
- 💯 **100% reliability** - No flaky tests

**Key Patterns:**
```swift
// Modern Swift Testing pattern
@Suite("Feature Tests")
struct FeatureTests {
    @Test("Test description")
    func testFeature() async throws {
        // Fresh container per test = perfect isolation
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Test logic
        let manager = TaskManager(modelContext: context)
        let result = manager.createTask(title: "Test")

        // Pattern matching for Result types
        guard case .success(let task) = result else {
            Issue.record("Failed to create task")
            return
        }

        #expect(task.title == "Test")
    }
}
```

**Critical Edge Cases Tested:**
- ✅ Feb 29 (leap) → Feb 28 (non-leap) transitions
- ✅ Month boundaries (Jan 31 → Feb 28/29)
- ✅ Year boundaries (Dec 31 → Jan 1)
- ✅ Parent→Subtask completion cascading (bidirectional)
- ✅ Multiple completions same day
- ✅ Out-of-order completion entries
- ✅ Tag limit enforcement (3 tags max)
- ✅ Skip impact calculation (6 severity levels)

**Documentation:**
- 📚 `/Docs/TESTING_MIGRATION_SUMMARY.md` - Complete migration report
- 📚 `/Docs/FRESH_TESTING_PLAN.md` - Testing strategy and patterns
- 📚 `/DaisyDosTests/Documentation/TestingGuide.md` - How to write tests

**Best Practices Established:**
- ✅ Struct-based test suites (value semantics)
- ✅ Local container creation per test (no shared state)
- ✅ Pattern matching for Result types (`guard case .success`)
- ✅ CloudKit explicitly disabled (`.none`) for testing
- ✅ DaisyDosSchemaV4 integration (same as production)
- ✅ Parameterized tests for edge cases
- ✅ Clear test names (self-documenting)
- ✅ Issue.record() for descriptive failures

---

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies.**

