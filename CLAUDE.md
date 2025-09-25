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

### Available Simulators
- iPhone 16, iPhone 16 Plus, iPhone 16 Pro, iPhone 16 Pro Max
- iPad (A16), iPad Air 11-inch (M3), iPad Air 13-inch (M3)
- iPad Pro 11-inch (M4), iPad Pro 13-inch (M4), iPad mini (A17 Pro)

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
- Models: @Observable classes with business logic (TaskManager, HabitManager)
- Views: Pure SwiftUI presentation, no business logic
- Services: External I/O operations (EventKit, PhotoKit, UserNotifications)
- No ViewModels: Business logic lives directly in observable models

**Shared Component Strategy:**
- TaskRowView and HabitRowView designed for maximum reusability
- Components work across different contexts (lists, search, Today view)
- Composition pattern with closure-based actions for flexibility

**Navigation Structure (✅ Phase 1.6 Complete):**
- Tab-based navigation with independent NavigationStack per tab
- NavigationManager @Observable class with separate NavigationPath per tab
- Value-based navigation prepared for deep linking
- Production TabView with 5 main sections (Today, Tasks, Habits, Tags, Settings)

### SwiftData Foundation (✅ Phase 1.1 & 1.2 Complete)

**ModelContainer Infrastructure:**
- `DaisyDosSchemaV1.swift`: Versioned schema conforming to `VersionedSchema` protocol
- `DaisyDosMigrationPlan.swift`: Migration plan conforming to `SchemaMigrationPlan` protocol
- `DaisyDosApp.swift`: Updated to use versioned schema and migration plan
- **Status**: ModelContainer initializes successfully with production models

**Core Data Models (✅ Phase 1.2 Complete):**
- `Task.swift`: Task model with @Model macro, tag relationships, validation logic
- `Habit.swift`: Habit model with streak tracking, completion logic, tag relationships
- `Tag.swift`: Tag model with SF Symbol icons, colors, unique constraints, system limits
- **Relationships**: Bidirectional many-to-many Task-Tag and Habit-Tag associations
- **Constraints**: Unique tag names/IDs, max 3 tags per item, max 30 total tags
- **Testing**: Comprehensive validation via ModelTestView with constraint/relationship testing

**@Observable Manager Classes (✅ Phase 1.3 Complete):**
- `TaskManager.swift`: @Observable business logic layer with reactive computed properties (allTasks, completedTasks, pendingTasks)
- `HabitManager.swift`: @Observable habit management with streak tracking, analytics, and completion logic
- `TagManager.swift`: @Observable tag operations with system limits, validation, and usage analytics
- **Dependency Injection**: ModelContext injected via initializers, not environment
- **Environment Setup**: All managers available via @Environment throughout app
- **Reactivity**: Computed properties automatically update SwiftUI views via @Observable
- **Testing**: ManagerTestView validates @Observable reactivity, environment injection, and @Bindable wrapper

### CloudKit Foundation (✅ Phase 1.1 Complete)

**Privacy-First CloudKit Integration:**
- `CloudKitManager.swift`: CloudKit initialization wrapper (DEBUG only, disabled by default)
- `LocalOnlyModeManager.swift`: @Observable privacy control manager with local-only mode default
- `DaisyDos.entitlements`: CloudKit container `iCloud.com.yourteam.DaisyDos` configured
- **Status**: CloudKit foundation ready but disabled, local-only mode functional

**Key Features:**
- Local-only mode is the default (privacy-first approach)
- CloudKit schema initialization ready but only runs in DEBUG builds
- Foundation prepared for Phase 10.0 CloudKit sync activation
- No production CloudKit operations until explicitly enabled

### Error Handling Architecture (✅ Phase 1.4 Complete)

**Three-Tier Error Transformation System:**
- `DaisyDosError.swift`: App-specific error enum with contextual error cases
- `RecoverableError.swift`: Protocol for user-facing errors with recovery actions
- `ErrorTransformer.swift`: Platform → App → User error transformation utilities
- `ErrorPresentationModifiers.swift`: SwiftUI error presentation components
- **Status**: Production-ready error handling with user-friendly messages and recovery options

**Key Features:**
- **Platform → App**: Transform SwiftData, CloudKit, and system errors to DaisyDosError
- **App → User**: Transform DaisyDosError to user-friendly RecoverableError with actions
- **SwiftUI Integration**: Error alerts, banners, and overlays with recovery action handling
- **Manager Integration**: All Manager classes use Result<T, AnyRecoverableError> pattern
- **Testing**: Comprehensive ErrorHandlingTestView validates all error scenarios
- **No Technical Exposure**: Users never see raw Swift/SwiftData error messages

### Design System & Core Components (✅ Phase 1.5 Complete)

**Design System Foundation:**
- `DesignSystem.swift`: Central design system structure with 8pt grid, constants, and guidelines
- `Spacing.swift`: 8pt grid spacing system with semantic naming and responsive values
- `Typography.swift`: 4-size font scale with full Dynamic Type support (xSmall to xxxLarge)
- `Colors.swift`: 60-30-10 color scheme with WCAG AA compliance and light/dark mode support
- `LiquidGlassModifiers.swift`: SwiftUI modifiers implementing liquid glass design aesthetic
- `AccessibilityHelpers.swift`: 44pt touch targets, WCAG validation, and VoiceOver optimization
- **Status**: Complete design system with accessibility excellence and liquid glass aesthetic

**Core Reusable Components:**
- `CardView.swift`: Base card component with multiple elevation levels, interactive states, and accessibility
- `DaisyButton.swift`: Comprehensive button system (4 styles, 3 sizes, loading states, haptic feedback)
- `InputField.swift`: Input wrapper with validation, error states, character limits, and accessibility
- `StateViews.swift`: Loading, empty state, shimmer, and inline loading components
- **Status**: Production-ready component library with consistent API and accessibility compliance

**Component Features:**
- **Liquid Glass Aesthetic**: Subtle transparency, blur effects, soft shadows, smooth animations
- **Accessibility Excellence**: 48pt touch targets, full VoiceOver support, Dynamic Type scaling
- **Design System Integration**: Uses established spacing, typography, colors throughout
- **Performance Optimized**: Efficient for lists and large datasets with proper view lifecycle

### Navigation Foundation & Production Views (✅ Phase 1.6 Complete)

**NavigationManager System:**
- `NavigationManager.swift`: @Observable class managing independent NavigationPath per tab
- `TabConfiguration.swift`: Complete tab system with accessibility labels and SF Symbol icons
- **Tab Structure**: Today, Tasks, Habits, Tags, Settings with independent navigation stacks
- **Deep Linking Ready**: Foundation prepared for URL-based navigation in future phases

**Production View Implementation:**
- `TodayView.swift`: Today's overview dashboard with task summaries and quick actions
- `TasksView.swift`: Complete task management with search, CRUD operations, and empty states
- `HabitsView.swift`: Habit tracking interface ready for future implementation
- `TagsView.swift`: Tag organization with visual cards and usage statistics
- `SettingsView.swift`: App settings with privacy controls and developer tools access

**Technical Achievement:**
- **Production TabView**: Replaced test-focused ContentView with professional navigation
- **CloudKit Issues Resolved**: Local-only mode working perfectly with ModelConfiguration
- **Accessibility Compliant**: Full VoiceOver support and proper touch targets throughout
- **Performance Optimized**: Efficient navigation state management and view lifecycle
- **Architecture Consistent**: Maintains all patterns from Phase 1.1-1.5

### Privacy-First Design
- Local-only mode is the default (CloudKit disabled)
- iCloud container configured but not active
- Privacy controls will be comprehensive when implemented

## Development Context

This project is in active development following a detailed implementation roadmap. **Phase 1.6 (Navigation Foundation & Production Views) is complete.**

### Current Implementation Status:

1. **✅ Xcode project setup** with all required frameworks imported
2. **✅ SwiftData ModelContainer Foundation** with versioned schema and migration plan
3. **✅ CloudKit Foundation Setup** with privacy-first local-only mode (disabled by default)
4. **✅ Core Data Models** with Task, Habit, and Tag @Model classes including relationships and constraints
5. **✅ @Observable Manager Classes** with TaskManager, HabitManager, and TagManager providing reactive business logic
6. **✅ Environment Setup** with proper dependency injection and @Bindable wrapper support
7. **✅ Error Handling Architecture** with three-tier error transformation (Platform → App → User)
8. **✅ Design System Foundation** with 8pt grid, typography scale, 60-30-10 colors, and liquid glass aesthetic
9. **✅ Core Reusable Components** with CardView, DaisyButton, InputField, and StateViews
10. **✅ Navigation Foundation** with NavigationManager, TabConfiguration, and production TabView structure
11. **✅ Production Views** with TodayView, TasksView, HabitsView, TagsView, and SettingsView
12. **✅ CloudKit Issues Resolved** with local-only ModelConfiguration and privacy-first approach
13. **✅ Comprehensive testing infrastructure** via ModelTestView, ManagerTestView, ErrorHandlingTestView, DesignSystemTestView, and ComponentTestView
14. **✅ Git configuration** with comprehensive .gitignore for iOS development
15. **📋 Comprehensive planning documents** in `/Docs` folder containing detailed implementation strategy

### Ready for Phase 1.7 or Phase 2.0:
- **Phase 1.7**: Performance baseline validation and accessibility compliance testing
- **Phase 2.0**: Enhanced task management features (due dates, priorities, advanced filtering)
- **Phase 3.0**: Full habit tracking implementation with streak analytics

**Current Application State:**
DaisyDos is now a **fully functional productivity app** with professional-grade navigation. The app features:
- Complete tab-based navigation with 5 main sections working seamlessly
- Full task management capabilities (create, read, update, delete tasks)
- Privacy-first local-only data storage (no cloud sync required)
- Accessibility-compliant interface with VoiceOver support
- Professional UI with established design system integration
- Developer tools accessible via Settings for testing and validation

The architecture is designed to support:
- Unified task and habit management in single views
- Shared UI components across multiple contexts
- Privacy-first approach with local-only mode
- Future CloudKit sync when users opt-in
- Accessibility-first design approach
- Performance optimization for large datasets (1000+ items)
- Scalable navigation system ready for deep linking

## Development Setup

### Repository Configuration
- **✅ Comprehensive .gitignore**: Configured for iOS/Xcode development with DaisyDos-specific exclusions
- **✅ Git cleanup**: Removed user-specific files from tracking (xcuserdata, .DS_Store)
- **✅ Privacy protection**: Local settings and certificates excluded from version control

### File Organization
- **Core Models**: `Task.swift`, `Habit.swift`, `Tag.swift` with full @Model implementation
- **Manager Classes**: `TaskManager.swift`, `HabitManager.swift`, `TagManager.swift` with @Observable business logic
- **Error Handling**: `DaisyDosError.swift`, `RecoverableError.swift`, `ErrorTransformer.swift`, `ErrorPresentationModifiers.swift`
- **Design System**: `DesignSystem.swift`, `Spacing.swift`, `Typography.swift`, `Colors.swift`, `LiquidGlassModifiers.swift`, `AccessibilityHelpers.swift`
- **Core Components**: `CardView.swift`, `DaisyButton.swift`, `InputField.swift`, `StateViews.swift`
- **Infrastructure**: `CloudKitManager.swift`, `LocalOnlyModeManager.swift` in main app target
- **Schema management**: `DaisyDosSchemaV1.swift`, `DaisyDosMigrationPlan.swift`
- **Testing**: `ModelTestView.swift`, `ManagerTestView.swift`, `ErrorHandlingTestView.swift`, `DesignSystemTestView.swift`, `ComponentTestView.swift` for comprehensive validation
- **Documentation**: `Models_README.md`, `phase_1_5_design_system_plan.md` track current structure and implementation plans

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
- Use Context7 to check up-to-date docs when needed for implementing new libraries or frameworks, or adding features using them.
