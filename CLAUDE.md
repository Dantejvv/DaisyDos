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

**Phase 1.0 Complete - Phase 2.2 Complete: TaskRowView Reusability Pattern**

### Current Status
DaisyDos has a robust architectural foundation with enhanced task management, complete tag system, and proven component reusability patterns implemented. The app currently features:

**Core Foundation (Phase 1.0 Complete):**
- Complete tab-based navigation (Today, Tasks, Habits, Tags, Settings)
- Basic task management capabilities (CRUD operations, search)
- Privacy-first local-only data storage
- WCAG AA accessibility compliance
- Professional UI with liquid glass design aesthetic
- Performance monitoring and developer tools

**Enhanced Task Model (Phase 2.1 Complete):**
- ✅ **Priority System**: Low/Medium/High with visual indicators (colors, SF symbols)
- ✅ **Due Dates & Start Dates**: Full date management with timezone support
- ✅ **Task Descriptions**: Rich text descriptions for detailed task information
- ✅ **Subtask Relationships**: Unlimited nesting with circular reference protection
- ✅ **File Attachments**: PhotoKit integration, 50MB per file, 200MB per task limit
- ✅ **Recurrence Rules**: Daily/weekly/monthly/yearly patterns with dynamic calculations
- ✅ **Advanced Filtering**: Priority, due date, overdue, and smart today's tasks
- ✅ **Enhanced TaskManager**: 60+ new methods for comprehensive task operations
- ✅ **SwiftData V2 Schema**: Migration-ready with robust error handling

**Tag System Implementation (Phase 2.1 Complete):**
- ✅ **Tag Assignment Validation**: 3-tag limit per task/habit with automatic enforcement via `didSet` observers
- ✅ **Tag Pool Management**: 30-tag system limit with real-time validation and visual feedback
- ✅ **SF Symbol & Color Selection**: Complete visual picker interfaces with predefined options
- ✅ **Tag Creation & Editing UI**: Full CRUD operations with live preview and validation
- ✅ **Tag Selection Interface**: Multi-select with drag support foundation and 3-tag limit visual feedback
- ✅ **Task Integration**: Tag assignment in TaskRowView and AddTaskView with real-time updates
- ✅ **SwiftData Query Integration**: TagsView uses @Query for automatic database change detection

**TaskRowView Reusability Pattern (Phase 2.2 Complete):**
- ✅ **Composition Pattern API**: Action closures for maximum reusability (onToggleCompletion, onEdit, onDelete, onTagAssignment)
- ✅ **Environment Dependencies Removed**: Pure presentation component with no business logic
- ✅ **Multiple Display Modes**: .compact, .detailed, .today modes for different contexts
- ✅ **Accessibility Excellence**: 44pt touch targets, comprehensive VoiceOver labels, Dynamic Type support
- ✅ **Cross-Context Validation**: Proven to work identically in TasksView, search results, and Today view contexts
- ✅ **Performance Optimized**: Efficient rendering with conditional UI based on display modes
- ✅ **Comprehensive Previews**: Multiple preview configurations for testing all display modes and accessibility

### Phase 2.3 Next Goals
Advanced Task Management Features:
- **Task CRUD Operations**: Complete create/edit/delete functionality with validation
- **Subtask Management**: Nesting interface with drag & drop reordering
- **EventKit Integration**: Calendar sync and reminders
- **Quick Actions**: Swipe gestures and context menus
- **Advanced Tag Features**: Drag & drop with Transferable protocol

### File Organization
- **Enhanced Models**: `Task.swift` (V2), `Priority.swift`, `RecurrenceRule.swift`, `TaskAttachment.swift` - Full featured models
- **Core Models**: `Habit.swift`, `Tag.swift` - SwiftData models with @Model macro and Identifiable conformance
- **Managers**: `TaskManager.swift` (enhanced), `HabitManager.swift`, `TagManager.swift` - @Observable business logic
- **Views**: Production views in main navigation structure
  - `TasksView.swift` - Main task list interface
  - `TagsView.swift` - Complete tag management with @Query integration
  - `TaskRowView.swift` - Maximally reusable task component with composition pattern API and cross-context compatibility
  - `TaskRowCrossContextDemo.swift` - Cross-context validation demo showing TaskRowView in different display modes
  - `AddTaskView.swift` - Enhanced task creation with tag assignment
- **Tag UI Components**: Complete tag system interface
  - `TagCreationView.swift`, `TagEditView.swift` - Tag CRUD operations
  - `TagColorPicker.swift`, `TagSymbolPicker.swift` - Visual selection interfaces
  - `TagChipView.swift` - Reusable tag display component
  - `TagSelectionView.swift`, `TagAssignmentSheet.swift` - Tag assignment interfaces
- **Core Components**: `CardView`, `DaisyButton`, `InputField`, `StateViews` - reusable UI components
- **Design System**: Complete system with spacing, typography, colors, accessibility helpers
- **Schema Management**: `DaisyDosSchemaV2.swift`, migration plan - SwiftData V2 with clean slate approach
- **Infrastructure**: CloudKit foundation (disabled), comprehensive error handling

## Key Implementation Principles

1. **Component Reusability**: TaskRowView proven to work identically across all contexts using composition pattern. HabitRowView will follow identical patterns
2. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
3. **Privacy by Default**: All features work locally before any cloud integration
4. **Error Handling Excellence**: Three-tier system transforms all errors to user-friendly messages with recovery actions
5. **Accessibility Excellence**: WCAG 2.1 AA compliance from the start with 48pt touch targets and full VoiceOver support
6. **Performance Focus**: Designed to handle large datasets efficiently with optimized components
7. **Design System Consistency**: All UI components use established spacing, typography, colors, and liquid glass aesthetic
8. **Developer Experience**: Semantic APIs (`.asCard()`, `DaisyButton.primary()`) with comprehensive documentation and previews
9. **SwiftData Integration**: Use @Query for automatic UI updates and computed properties for business logic in @Observable managers

Refer to `/Docs/implementation_roadmap.md` for the detailed development plan and `/Docs/daisydos_prd.md` and `/Docs/daisydos_plan.md` for comprehensive product requirements.

**🔍 IMPORTANT: Always use Context7 to check up-to-date documentation when implementing new libraries, frameworks, or adding features using external dependencies. This ensures accurate and current implementation patterns.**
