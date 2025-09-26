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

### Key Architectural Patterns

**Model-View with Services Pattern:**
- Models: @Observable classes with business logic (TaskManager, HabitManager, TagManager)
- Views: Pure SwiftUI presentation, no business logic
- Services: External I/O operations (EventKit, PhotoKit, UserNotifications)
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
- Manager classes: `TaskManager.swift`, `HabitManager.swift`, `TagManager.swift` with @Observable business logic
- Three-tier error handling: Platform → App → User error transformation
- Privacy-first approach with local-only mode default

**UI Layer:**
- Design system with 8pt grid, WCAG AA colors, liquid glass aesthetic
- Reusable components: `CardView`, `DaisyButton`, `InputField`, `StateViews`
- Full accessibility compliance with VoiceOver support and Dynamic Type scaling
- Performance optimized for large datasets (1000+ items)

## Development Context

**Phase 1.0 Complete - Phase 2.0 In Progress**

### Current Status
DaisyDos has a solid architectural foundation with all core systems implemented. The app currently features:
- Complete tab-based navigation (Today, Tasks, Habits, Tags, Settings)
- Full task management capabilities (CRUD operations, search)
- Privacy-first local-only data storage
- WCAG AA accessibility compliance
- Professional UI with liquid glass design aesthetic
- Performance monitoring and developer tools

### Phase 2.0 Goals
Enhanced task management features:
- **Due dates and reminders**: EventKit integration for calendar sync
- **Priority levels**: High/Medium/Low priority system with visual indicators
- **Advanced filtering**: Filter by status, priority, due date, tags
- **Quick actions**: Swipe gestures and context menus
- **Task dependencies**: Basic task relationships

### File Organization
- **Models**: `Task.swift`, `Habit.swift`, `Tag.swift` - SwiftData models with @Model macro
- **Managers**: `TaskManager.swift`, `HabitManager.swift`, `TagManager.swift` - @Observable business logic
- **Views**: Production views in main navigation structure
- **Components**: `CardView`, `DaisyButton`, `InputField`, `StateViews` - reusable UI components
- **Design System**: Complete system with spacing, typography, colors, accessibility helpers
- **Infrastructure**: CloudKit foundation (disabled), error handling, schema management

## Key Implementation Principles

1. **Component Reusability**: TaskRowView and HabitRowView must work identically across all contexts using established CardView patterns
2. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
3. **Privacy by Default**: All features work locally before any cloud integration
4. **Error Handling Excellence**: Three-tier system transforms all errors to user-friendly messages with recovery actions
5. **Accessibility Excellence**: WCAG 2.1 AA compliance from the start with 48pt touch targets and full VoiceOver support
6. **Performance Focus**: Designed to handle large datasets efficiently with optimized components
7. **Design System Consistency**: All UI components use established spacing, typography, colors, and liquid glass aesthetic
8. **Developer Experience**: Semantic APIs (`.asCard()`, `DaisyButton.primary()`) with comprehensive documentation and previews

Refer to `/Docs/implementation_roadmap.md` for the detailed development plan and `/Docs/daisydos_prd.md` and `/Docs/daisydos_plan.md` for comprehensive product requirements.

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies. This ensures accurate and current implementation patterns.**
