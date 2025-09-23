# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DaisyDos is a unified iOS productivity application built with SwiftUI that integrates task management and habit tracking. The app targets iOS 17.0+ and uses SwiftData for data persistence with CloudKit integration prepared but disabled by default for privacy.

## Build Commands

This is a standard Xcode project. Use Xcode to build and run:

- **Build**: Cmd+B in Xcode or `xcodebuild build -scheme DaisyDos`
- **Run**: Cmd+R in Xcode to run on simulator/device
- **Test**: Cmd+U in Xcode or `xcodebuild test -scheme DaisyDos`
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

### Data Models (Currently Basic)

Current models are minimal stubs:
- `Item.swift`: Basic SwiftData model with timestamp (placeholder)
- Future: Task, Habit, Tag models per comprehensive roadmap

### Privacy-First Design
- Local-only mode is the default (CloudKit disabled)
- iCloud container configured but not active
- Privacy controls will be comprehensive when implemented

## Development Context

This project is in early development following a detailed implementation roadmap. The current codebase contains:

1. **Basic Xcode project setup** with SwiftData configuration
2. **CloudKit entitlements** configured but functionality disabled
3. **Placeholder models** (Item.swift) that will be replaced with full Task/Habit/Tag system
4. **Comprehensive planning documents** in `/Docs` folder containing detailed implementation strategy

The architecture is designed to support:
- Unified task and habit management in single views
- Shared UI components (TaskRowView/HabitRowView) across multiple contexts
- Privacy-first approach with local-only mode
- Future CloudKit sync when users opt-in
- Accessibility-first design approach
- Performance optimization for large datasets (1000+ items)

## Key Implementation Principles

1. **Component Reusability**: TaskRowView and HabitRowView must work identically across all contexts
2. **@Observable First**: Use @Observable pattern throughout, no traditional ViewModels
3. **Privacy by Default**: All features work locally before any cloud integration
4. **Accessibility Excellence**: WCAG 2.1 AA compliance from the start
5. **Performance Focus**: Designed to handle large datasets efficiently

Refer to `/Docs/implementation_roadmap.md` for the detailed development plan and `/Docs/daisydos_prd.md` for comprehensive product requirements.