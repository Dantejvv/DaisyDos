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

**Navigation Structure:**
- Tab-based navigation with independent NavigationStack per tab
- Value-based navigation prepared for deep linking
- NavigationManager maintains separate NavigationPath per tab

### SwiftData Foundation (✅ Phase 1.1 Complete)

**ModelContainer Infrastructure:**
- `DaisyDosSchemaV1.swift`: Versioned schema conforming to `VersionedSchema` protocol
- `DaisyDosMigrationPlan.swift`: Migration plan conforming to `SchemaMigrationPlan` protocol
- `DaisyDosApp.swift`: Updated to use versioned schema and migration plan
- **Status**: ModelContainer initializes successfully, ready for model creation

**Current Models:**
- `Item.swift`: Basic SwiftData model with timestamp (placeholder, will be replaced)
- **Next Phase**: Task, Habit, Tag models per implementation roadmap (Phase 1.2)

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

### Privacy-First Design
- Local-only mode is the default (CloudKit disabled)
- iCloud container configured but not active
- Privacy controls will be comprehensive when implemented

## Development Context

This project is in early development following a detailed implementation roadmap. **Phase 1.1 (Foundation & Architecture) is complete.**

### Current Implementation Status:

1. **✅ Xcode project setup** with all required frameworks imported
2. **✅ SwiftData ModelContainer Foundation** with versioned schema and migration plan
3. **✅ CloudKit Foundation Setup** with privacy-first local-only mode (disabled by default)
4. **✅ Git configuration** with comprehensive .gitignore for iOS development
5. **✅ Architecture foundation** ready for core model implementation
6. **📋 Comprehensive planning documents** in `/Docs` folder containing detailed implementation strategy

### Ready for Phase 1.2:
- Core Data Models creation (Task, Habit, Tag)
- @Model class implementation with relationships
- SwiftData @Relationship macros and constraints

The architecture is designed to support:
- Unified task and habit management in single views
- Shared UI components (TaskRowView/HabitRowView) across multiple contexts
- Privacy-first approach with local-only mode
- Future CloudKit sync when users opt-in
- Accessibility-first design approach
- Performance optimization for large datasets (1000+ items)

## Development Setup

### Repository Configuration
- **✅ Comprehensive .gitignore**: Configured for iOS/Xcode development with DaisyDos-specific exclusions
- **✅ Git cleanup**: Removed user-specific files from tracking (xcuserdata, .DS_Store)
- **✅ Privacy protection**: Local settings and certificates excluded from version control

### File Organization
- `CloudKitManager.swift` and `LocalOnlyModeManager.swift` in main app target
- Schema management files: `DaisyDosSchemaV1.swift`, `DaisyDosMigrationPlan.swift`
- Documentation: `Models_README.md` tracks planned model structure

## Key Implementation Principles

1. **Component Reusability**: TaskRowView and HabitRowView must work identically across all contexts
2. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
3. **Privacy by Default**: All features work locally before any cloud integration
4. **Accessibility Excellence**: WCAG 2.1 AA compliance from the start
5. **Performance Focus**: Designed to handle large datasets efficiently

Refer to `/Docs/implementation_roadmap.md` for the detailed development plan and `/Docs/daisydos_prd.md` and `/Docs/daisydos_plan.md` for comprehensive product requirements.
- Use Context7 to check up-to-date docs when needed for implementing new libraries or frameworks, or adding features using them.
