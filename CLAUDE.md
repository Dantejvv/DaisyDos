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
- Production TabView with 5 main sections (Today, Tasks, Habits, Tags, Settings)

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
- Subtask Relationships: Unlimited nesting with circular reference protection
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
- Subtask Management: Order-based reordering, progress visualization
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
- ✅ Grace period logic with smart streak maintenance
- ✅ Skip functionality with reason tracking
- ✅ SwiftData schema integration and build validation

### ✅ **Phase 3.2 Complete: HabitRowView Component Consistency**
- ✅ Standalone HabitRowView following TaskRowView patterns exactly
- ✅ Composition pattern with action closures (onMarkComplete, onEdit, onDelete, onSkip)
- ✅ Display modes: .compact, .detailed, .today matching TaskRowView
- ✅ Habit-specific features: streak display, grace period indicators, recurrence integration
- ✅ Comprehensive accessibility support with VoiceOver labels and 44pt touch targets
- ✅ Extracted embedded HabitRowView from HabitsView for true reusability
- ✅ Build validation with clean compilation

### 🚧 **Phase 3.3 In Progress: Analytics & Progress Tracking**
**Current Status: Ready to Begin**

**Next Development Priorities:**

#### **Priority 1: Streak Calculation System**
**Advanced Streak Logic:**
- Accurate streak calculation with grace periods
- Streak history tracking for analytics
- Longest streak tracking and celebration
- Streak reset logic with user confirmation

#### **Priority 2: Progress Visualization**
**Charts Framework Integration:**
- HabitProgressChart components for trend visualization
- Heatmap views for completion history (GitHub-style)
- Weekly/monthly trend visualization
- Completion rate calculation and display

#### **Priority 3: Remaining UI Components**
**Missing Habit Management UI:**
- `HabitDetailView.swift` - Comprehensive statistics and editing
- `HabitEditView.swift` - Dedicated editing interface
- `AddHabitView.swift` - Standalone creation form (currently embedded)

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
│   ├── Habits/ ✅ SUBSTANTIAL PROGRESS - Data Models & Component Complete
│   │   ├── Models/ (Habit.swift ✅ enhanced, HabitCompletion.swift ✅, HabitStreak.swift ✅)
│   │   ├── Views/ (HabitsView.swift ✅ updated, HabitRowView.swift ✅ standalone component)
│   │   └── Services/ (HabitManager.swift ✅ functional)
│   │
│   ├── Tags/ ✅ COMPLETE
│   ├── Today/ ⚠️ BLOCKED - Needs Phase 3 completion
│   └── Settings/ ✅ BASIC
│
├── Core/ ✅ COMPLETE
│   ├── Design/ (Complete design system)
│   ├── Data/ (SwiftData schemas, CloudKit foundation)
│   ├── ErrorHandling/ (Three-tier error system)
│   └── Navigation/ (NavigationManager, TabConfiguration)
```

### Target Architecture for Phase 3
```
Features/Habits/
├── Models/
│   ├── Habit.swift ✅ (enhance with RecurrenceRule)
│   ├── HabitCompletion.swift ❌ TO CREATE
│   └── HabitStreak.swift ❌ TO CREATE
├── Views/
│   ├── HabitRowView.swift ❌ TO CREATE (standalone, reusable)
│   ├── HabitDetailView.swift ❌ TO CREATE
│   ├── HabitEditView.swift ❌ TO CREATE
│   ├── AddHabitView.swift ❌ TO CREATE (extract from HabitsView)
│   ├── HabitsView.swift ✅ (refactor to use new components)
│   └── Analytics/
│       ├── HabitProgressChart.swift ❌ TO CREATE
│       ├── HabitHeatmapView.swift ❌ TO CREATE
│       └── StreakVisualizationView.swift ❌ TO CREATE
└── Services/
    └── HabitManager.swift ✅ (enhance with advanced features)
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
2. **Streak Calculations**: Implement grace periods and intelligent streak logic
3. **Completion Tracking**: Separate HabitCompletion model for individual completion entries
4. **Visual Feedback**: Rich progress indicators and heatmap visualizations

## Development Guidelines

### **Phase 3 Success Criteria (MUST ACHIEVE)**
- [ ] HabitRowView proven reusable across 3+ contexts (HabitsView, Today view, search)
- [ ] Shared UI patterns consistent with TaskRowView (composition pattern, display modes)
- [ ] Accurate streak calculations with grace periods
- [ ] Visual progress feedback compelling and motivating
- [ ] Recurrence system working for both tasks and habits
- [ ] Component reusability patterns proven scalable

### **Quality Gates**
- **Build Status**: Must build cleanly with no warnings
- **Cross-Context Testing**: HabitRowView must work in Today view context
- **Performance**: Must handle 100+ habits efficiently
- **Accessibility**: Full VoiceOver support with proper labels and navigation

### **Phase 4 Readiness Checklist**
- [ ] Standalone HabitRowView component created and tested
- [ ] HabitRowView supports all display modes (.compact, .detailed, .today)
- [ ] Action closure pattern implemented for cross-context reusability
- [ ] Basic habit completion and streak tracking functional
- [ ] Performance validated with realistic data sets

Refer to `/Docs/implementation_roadmap.md` for detailed development tasks and `/Docs/daisydos_prd.md` for comprehensive requirements.

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies.**

**🚨 CRITICAL: Phase 4 (Today View) cannot proceed until HabitRowView reusability is proven. Focus on component consistency first.**