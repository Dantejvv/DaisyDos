# DaisyDos - Consolidated Technical Plan

## Technologies Stack

### Core Technologies
- **Development**: Xcode, Swift 6.2, SwiftUI, Swift Testing
- **Data & State**: SwiftData, @Observable pattern, Swift Concurrency, #Predicate macro
- **UI & Design**: SF Symbols, Apple HIG, Charts Framework, Accessibility Modifiers
- **System Integration**: EventKit, PhotoKit, UserNotifications, App Groups
- **Drag & Drop**: Transferable Protocol, UniformTypeIdentifiers, NSItemProvider
- **Storage**: UserDefaults (UI prefs), Keychain (sensitive data), FileManager
- **Logging**: os.log for system logging

### Future Features
- **Cloud & Sync**: CloudKit, conflict resolution UI
- **Extensions**: WidgetKit, App Shortcuts, App Intents Framework  
- **Advanced**: CryptoKit, UNNotificationContentExtension, TimelineProvider

## Architecture Decisions & Implementation

### Core Pattern: Model-View with Services
- **Models**: @Observable classes with business logic, computed properties
- **Views**: SwiftUI presentation only, no business logic
- **Services**: External I/O operations (CloudKit, EventKit, etc.)
- **Managers**: @Observable coordinators bridging models and services
- **No ViewModels**: Business logic lives directly in observable models

### Navigation: Hybrid Tab+Stack Pattern
```swift
TabView(selection: $selectedTab) {
    NavigationStack(path: $navigationManager.todayPath) {
        TodayView()
    }
    .tabItem { Label("Today", systemImage: "calendar") }
    // Additional tabs...
}
```
- Independent NavigationStack per tab for feature isolation
- Value-based navigation with .navigationDestination(for: Type.self)
- NavigationManager maintains separate NavigationPath per tab
- Future: URL structure for deep linking (design now, implement post-MVP)

### State Management: @Observable Framework
```swift
@Observable class TaskManager {
    private let modelContext: ModelContext
    
    // Computed properties for filtered data
    var todaysTasks: [Task] {
        // Dynamic filtering logic
    }
    
    func fetchTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { /* conditions */ }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
```
- Dependency injection via Environment (.environment(), NOT .environmentObject())
- ModelContext injected to managers via initializer
- Two-way bindings with @Bindable for mutable references

### Data Architecture: SwiftData with Hybrid Settings
- **Primary Data**: SwiftData @Model classes (Task, Habit, Tag) with CloudKit integration
- **UI Preferences**: @AppStorage for non-synced settings (theme, sounds)
- **Sensitive Data**: Keychain for local-only mode, privacy settings
- **Business Settings**: UserPreferences @Model for synced preferences

### Schema & Migration
```swift
enum DaisyDosSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Task.self, Habit.self, Tag.self, /* others */]
    }
}

struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [DaisyDosSchemaV1.self] }
    static var stages: [MigrationStage] { [] } // V1 baseline
}
```

### Component Strategy: Single Definition Pattern
- Shared components (TaskRowView, HabitRowView) across all contexts
- Composition over duplication - Today View reuses existing row components
- Action injection via closures vs tight coupling

### Data Retention: Tiered Storage Strategy
- **Raw events**: 90-day retention (~5-10MB)
- **Daily aggregates**: 365-day retention for analytics
- **Monthly statistics**: Indefinite retention for trends
- **Total storage**: ~8-12MB per user with automatic aggregation

### Error Handling: Three-Tier Transformation
1. **Service layer**: Platform errors → App-specific errors
2. **Manager layer**: Add business context
3. **View layer**: User-friendly presentation with recovery options

### Tag System Constraints
- Shared pool across Tasks and Habits (max 30 total)
- Maximum 3 tags per item (enforced at model level)
- Custom SF Symbol icons and system colors
- Flat structure, drag & drop assignment

### Recurrence System
```swift
struct RecurrenceRule: Codable {
    enum Frequency: String, Codable {
        case daily, weekly, monthly, yearly, custom
    }
    let frequency: Frequency
    let interval: Int
    let daysOfWeek: Set<Int>?
    
    func nextOccurrence(after date: Date) -> Date? {
        // Dynamic calculation - no pre-generated instances
    }
}
```
- Dynamic occurrence calculation (no storage of future instances)
- Shared by Tasks and Habits via optional property
- Rule changes immediately affect future dates

## File Structure

```
📱 DaisyDos/
├── 📂 App/
│   ├── 📄 DaisyDosApp.swift          # Entry point, ModelContainer + CloudKit setup
│   └── 📄 ContentView.swift          # Root TabView with NavigationStacks
│
├── 📂 Models/
│   ├── 📂 Core/                      # @Model classes: Task, Habit, Tag, Subtask, HabitStreak
│   ├── 📂 Recurring/                 # RecurrenceRule business logic
│   ├── 📂 Settings/                  # UserPreferences, LocalSettings, PrivacySettings
│   ├── 📂 Errors/                    # DaisyDosError app-specific types
│   ├── 📂 Search/                    # SmartList, SearchFilter, SearchableProtocol
│   └── 📂 Activity/                  # ActivityLog, ActivityDailyAggregate, ActivityMonthlyStats
│
├── 📂 Views/
│   ├── 📂 Tasks/                     # TaskListView, TaskDetailView, TaskRowView (SHARED)
│   ├── 📂 Habits/                    # HabitListView, HabitDetailView, HabitRowView (SHARED)
│   ├── 📂 Today/                     # TodayView (composes shared row components)
│   ├── 📂 Calendar/                  # CalendarView, DayView, WeekView, MonthView
│   ├── 📂 Search/                    # SearchView, SearchResultsView, filters
│   ├── 📂 Settings/                  # SettingsView, various setting screens
│   └── 📂 Components/                # Reusable UI: TagView, DateTimePicker, etc.
│
├── 📂 Services/                      # External I/O: CloudKit, Notifications, Calendar, Data
│
├── 📂 Managers/                      # @Observable coordinators: TaskManager, HabitManager, etc.
│
├── 📂 Extensions/                    # Helpers: View+, Date+, Color+, ModelContext+
├── 📂 Modifiers/                     # SwiftUI modifiers: GlassEffect, ErrorPresentation
├── 📂 Protocols/                     # Syncable, Exportable, Searchable, RecoverableError
└── 📂 Resources/                     # Assets, localization, Info.plist
└-- 📂 AppIntents/                    # Siri & Shortcuts
```

## Features

### Core Functionality
- **Tasks**: CRUD operations, subtasks, priorities, due/start dates, tags (max 3), attachments, recurring
- **Habits**: CRUD operations, streak tracking, heatmap, progress charts, custom schedules, tags (max 3)
- **Today View**: Unified dashboard showing filtered tasks/habits for today, reuses shared row components
- **Calendar**: Day/Week/Month views with task distribution, read-only
- **Search**: Global text search, saved searches/smart lists, advanced filters
- **Tags**: Shared pool (max 30), SF Symbol icons, system colors, drag & drop assignment

### Data Management
- **Tiered Retention**: 90-day raw events, 365-day aggregates, indefinite monthly stats
- **Hybrid Storage**: SwiftData (primary), UserDefaults (UI prefs), Keychain (sensitive)
- **Local-Only Mode**: Complete privacy option gating all sync operations

### User Interface
- **Design**: Liquid glass aesthetic, 8pt grid, accessibility compliant
- **Navigation**: Tab-based with independent NavigationStacks
- **Drag & Drop**: Reordering within same type (tasks/habits), tag assignment
- **Themes**: Light/dark mode with system awareness

## Testing Strategy
- **Unit Tests**: Critical path coverage (recurrence calculations, streak logic, data operations)
- **Integration Tests**: SwiftData + CloudKit sync, notifications, calendar integration
- **UI Tests**: Critical user flows, accessibility, error scenarios
- **Framework**: Swift Testing with dependency injection for mocking

## Accessibility Requirements
- **WCAG 2.1 Level AA**: 4.5:1 contrast ratio, 44pt touch targets
- **VoiceOver**: Complete navigation support, semantic labels
- **Dynamic Type**: xSmall to xxxLarge support
- **Additional**: Reduce motion, increase contrast, bold text support

## Critical Implementation Rules

### Always Do:
- Reuse UI components across contexts
- Filter data at manager level via computed properties
- Use value-based navigation with .navigationDestination
- Maintain independent navigation state per tab
- Convert platform errors to user-friendly messages
- Aggregate data before cleanup
- Validate tag limits at model level
- Use .environment() for @Observable (never .environmentObject())
- Inject ModelContext via initializer to managers
- Always use FetchDescriptor for querying (not storing arrays)
- Always check Local-Only mode flag before sync operations
- Always validate constraints at model level when possible


### Never Do:
- Duplicate UI components for different contexts
- Filter data in views
- Pre-generate recurring instances (calculate dynamically)
- Use singleton ErrorManager (inject via Environment)
- Store arrays of @Model objects in managers (use FetchDescriptor)
- Mix navigation logic between tabs
- Expose technical errors to users
- Implement cross-device drag & drop
- Don't use inheritance with @Model classes
- Don't use only UserDefaults for complex settings
- Don't fetch ModelContext from Environment in managers
- Don't store arrays of @Model objects in managers

## Future Features (Post-MVP)
- CloudKit sync with conflict resolution
- Widgets with deep linking
- Siri integration via App Intents
- Push notifications
- Export/backup functionality
- Advanced analytics

## Visual Design Principles

### Design System Foundation
- **8pt spacing grid system**: Consistent spacing throughout the app
- **Typography scale**: Maximum 4 sizes, 2 weights for hierarchy and readability
- **Color scheme**: 60-30-10 rule for balanced visual composition
- **Liquid Glass design**: Modern aesthetic with translucent elements and depth
- **Reusable UI components**: Consistent design patterns across all screens

## Wireframe Development Phases
*Total: 52 wireframes (enhanced UX-focused structure)*

### Phase 1: Foundation & Core MVP (18 wireframes)
**Priority**: Validate core concept and essential user journeys

#### **App Foundation (4 wireframes)**
1. **App Launch & Loading** - Initial app loading with branding
2. **Onboarding Flow** - Welcome, feature introduction, value prop
3. **Permission Requests** - Calendar, notifications, photo access
4. **Tab Navigation Shell** - Root container with 4 tabs

#### **Today View - The Star Feature (5 wireframes)**
5. **Today Dashboard** - Unified tasks + habits for today
6. **Today Empty State** - First-time user, no items scheduled
7. **Today Quick Actions** - Swipe actions, quick completion
8. **Today Success State** - All items completed celebration
9. **Today Mixed Progress** - Some completed, some pending

#### **Core Task Management (5 wireframes)**
10. **Task List View** - Main tasks screen with sections
11. **Task Creation Form** - New task with basic fields
12. **Task Row Component** - Individual task display (reusable)
13. **Task Empty State** - No tasks created yet
14. **Task Quick Edit** - Inline editing mode

#### **Core Habit Management (4 wireframes)**
15. **Habit List View** - Main habits screen
16. **Habit Creation Form** - New habit with scheduling
17. **Habit Row Component** - Individual habit display (reusable)
18. **Habit Empty State** - No habits created yet

### Phase 2: Enhanced Functionality (20 wireframes)
**Priority**: Rich features that differentiate the product

#### **Deep Task Management (6 wireframes)**
19. **Task Detail View** - Full task information and editing
20. **Subtask Management** - Hierarchical breakdown view
21. **Task Attachment Picker** - Photo/file selection
22. **Task Priority & Due Date** - Priority picker and date selection
23. **Recurring Task Setup** - Recurrence rule configuration
24. **Task Tag Assignment** - Drag & drop tag interface

#### **Deep Habit Management (6 wireframes)**
25. **Habit Detail View** - Statistics and settings
26. **Habit Streak Visualization** - Current streak with history
27. **Habit Progress Heatmap** - GitHub-style yearly view
28. **Habit Analytics Charts** - Weekly/monthly trends
29. **Habit Skip Interface** - Grace periods and skip reasons
30. **Habit Schedule Customization** - Flexible scheduling options

#### **Search & Organization (4 wireframes)**
31. **Global Search Interface** - Search bar with filters
32. **Search Results Mixed** - Tasks + habits in results
33. **Tag Management System** - Create, edit, organize tags
34. **Smart Lists/Saved Searches** - Filtered view management

#### **Calendar Integration (4 wireframes)**
35. **Calendar Day View** - Hourly schedule with tasks
36. **Calendar Week View** - 7-day task distribution
37. **Calendar Month View** - Monthly overview with density
38. **Calendar Event Integration** - iOS Calendar events display

### Phase 3: Polish & Advanced Features (14 wireframes)
**Priority**: Edge cases, advanced features, and system integration

#### **Advanced Features (5 wireframes)**
39. **Advanced Filter Sheet** - Complex filtering options
40. **Drag & Drop States** - Reordering and tag assignment
41. **Batch Operations** - Multi-select and bulk actions
42. **Notification Management** - Custom notification settings
43. **Deep Link Handling** - Entry from notifications/widgets

#### **Settings & Configuration (5 wireframes)**
44. **Settings Main Screen** - Primary settings navigation
45. **Appearance Customization** - Themes, accessibility options
46. **Privacy & Data Controls** - Local-only mode, permissions
47. **Sync & Backup Settings** - CloudKit configuration
48. **Data Management** - Export, retention, storage usage

#### **Error Handling & States (4 wireframes)**
49. **Error States Collection** - Network errors, sync issues
50. **Confirmation Dialogs** - Delete confirmations, destructive actions
51. **Offline Mode Interface** - Limited functionality states
52. **Loading & Progress States** - Various loading indicators

## Key UX Principles Reflected in Wireframes

### **Unified Experience**
- Today View wireframes emphasize the "one app, complete picture" value prop
- Shared row components (Task/Habit) ensure consistency
- Tag system integration across both content types

### **Accessibility First**
- Every wireframe should include accessibility annotations
- Large touch targets (44pt minimum)
- Clear visual hierarchy and contrast considerations

### **Progressive Disclosure**
- Phase 1 focuses on core value delivery
- Advanced features introduced gradually
- Empty states guide users to first actions

### **iOS Native Patterns**
- Tab-based navigation with independent stacks
- Standard iOS interaction patterns (swipe, drag & drop)
- System integration (Calendar, notifications)

**Advanced Features**
- Advanced Filter Sheet - Complex filtering options
- Saved Searches - Smart lists management
- Calendar Event Detail - Individual event information
- Drag & Drop - Reordering and organization

**Data Management**
- Sync Settings - CloudKit configuration
- Data Management - Backup/export/retention
- Export Options - Data export format selection
- Backup Restore - Restore from backup interface
- Storage Usage - Data usage breakdown

**Edge Cases & Polish**
- Deep Link Landing - How users arrive from notifications/widgets
- Confirmation Dialogs - Delete confirmations, etc.
- Offline Mode - Limited functionality states

## Future Features (Post-MVP)
- CloudKit sync with conflict resolution
- Widgets with deep linking
- Siri integration via App Intents
- Push notifications
- Export/backup functionality
- Advanced analytics

## Repository
https://github.com/Dantejvv/DaisyDos.git
