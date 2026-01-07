# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DaisyDos is a unified iOS productivity application built with SwiftUI that integrates task management and habit tracking. The app targets iOS 17.0+ and uses SwiftData for data persistence with CloudKit integration prepared but disabled by default for privacy.

## Document Navigation

**This document:** Architecture guide and AI assistant quick reference
**For detailed feature checklists:** [implementation_roadmap.md](Docs/implementation_roadmap.md)
**For testing guide:** [TestingGuide.md](DaisyDosTests/Documentation/TestingGuide.md)

## Build Commands

This is a standard Xcode project. Use Xcode to build and run:

- **Build**: Cmd+B in Xcode or `xcodebuild build -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Run**: Cmd+R in Xcode to run on simulator/device
- **Test**: Cmd+U in Xcode or `xcodebuild test -scheme DaisyDos -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Archive**: Product → Archive in Xcode for distribution

### Simulator Destination Notes

When running xcodebuild from CLI, use a specific simulator name. If there are multiple simulators with the same name (different iOS versions), you may need to specify by ID:

```bash
# List available simulators
xcrun simctl list devices available | grep iPhone

# Use specific simulator by ID if name is ambiguous
xcodebuild build -scheme DaisyDos -destination 'platform=iOS Simulator,id=05C5E451-7DF0-4243-9E28-9B5D6641EC77'
```

### Framework Compatibility Notes

- **PhotoKit**: Not available on iOS Simulator. Code uses conditional import `#if canImport(PhotoKit)` to handle simulator builds
- **UserNotifications/CloudKit**: Work on both simulator and device


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

All core features are production-ready. See [implementation_roadmap.md](Docs/implementation_roadmap.md) for detailed checklists.

**Completed Systems:**
- ✅ **Task Management** - Full CRUD, subtasks, attachments, recurrence, notifications
- ✅ **Habit Tracking** - Completion tracking, streaks, analytics, notifications
- ✅ **Tag System** - 5-tag per item limit, 30-tag system limit
- ✅ **Logbook** - Tiered retention (90/365 days)
- ✅ **Today View** - Unified task/habit overview
- ✅ **Settings** - Appearance, privacy, notifications, CloudKit
- ✅ **CloudKit Integration** - User-controlled sync with offline queue
- ✅ **Habit Analytics** - Charts, trends, period selection

**Partially Complete:**
- 🔄 **Advanced Notifications** - Core complete (95%), edge cases remain

For granular implementation details and checkboxes, see [implementation_roadmap.md](Docs/implementation_roadmap.md).


## Testing Infrastructure

**Framework:** Swift Testing (modern @Test macro, #expect assertions)
**Status:** 199 tests, 100% pass rate, ~0.35s execution time

**Quick Reference:**
- Run tests: `Cmd+U` in Xcode
- Struct-based test suites with fresh container per test
- Pattern match Result types: `guard case .success(let value)`

**Complete testing guide:** See [TestingGuide.md](DaisyDosTests/Documentation/TestingGuide.md)

---

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies.**

