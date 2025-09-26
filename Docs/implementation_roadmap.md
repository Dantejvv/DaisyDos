# DaisyDos Implementation Roadmap & Checklist

## Overview

This roadmap provides both strategic direction and granular implementation tasks. Each task is designed to be completable in a day or less, with clear acceptance criteria. The phased approach ensures architectural validation at each step while building toward a production-ready application.

**Key Architectural Decisions Validated:**
- Apple's Model-View (MV) pattern with @Observable models containing business logic
- Rich domain models replacing traditional Manager-heavy architectures
- Lightweight Service layer for queries and external operations
- Privacy-first approach with local-only mode
- Feature-based organization aligning with SwiftUI's reactive nature

---

## Phase 1.0: Foundation & Architecture
**Goals:** Establish solid technical foundation, validate core patterns, set up development infrastructure  
**Total Effort:** Large - Critical foundation work  
**Dependencies:** None - Starting point

### 1.1 Project Setup & Architecture (Effort: Medium)

#### ✅ Xcode Project Configuration
- [X] Create new iOS project in Xcode 15+ with minimum iOS 17.0 deployment target
- [X] Configure project settings: Bundle Identifier, Team, Code Signing
- [X] Add required frameworks to project: SwiftUI, SwiftData, CloudKit, EventKit, PhotoKit, UserNotifications
- [X] Set up SwiftData entitlements in project configuration
- [X] Configure Info.plist with required usage descriptions for Calendar, Photos, Notifications
- [X] **Acceptance:** Project builds successfully, all frameworks import without errors

#### ✅ SwiftData ModelContainer Foundation
- [X] Create `DaisyDosSchemaV1` conforming to `VersionedSchema` protocol:
```swift
enum DaisyDosSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Task.self, Habit.self, Tag.self]
    }
}
```
- [X] Implement `DaisyDosMigrationPlan` conforming to `SchemaMigrationPlan`:
```swift
struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [DaisyDosSchemaV1.self] }
    static var stages: [MigrationStage] { [] } // V1 baseline
}
```
- [X] Configure ModelContainer in `DaisyDosApp.swift` with schema and migration plan
- [X] Test ModelContainer initialization succeeds without CloudKit (local-only mode)
- [X] **Acceptance:** ModelContainer initializes successfully, SwiftData ready for model creation

#### ✅ CloudKit Foundation Setup (Disabled)
- [X] Add CloudKit capability in Xcode project settings
- [X] Create CloudKit container in Developer Portal (name: `iCloud.com.yourteam.DaisyDos`)
- [X] Add CloudKit container to app's entitlements
- [X] Implement CloudKit initialization wrapper (disabled by default):
```swift
#if DEBUG
private func initializeCloudKitSchemaIfNeeded() throws {
    let config = ModelConfiguration()
    let desc = NSPersistentStoreDescription(url: config.url)
    let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourteam.DaisyDos")
    desc.cloudKitContainerOptions = opts
    desc.shouldAddStoreAsynchronously = false
    // Schema initialization code here
}
#endif
```
- [X] Create `LocalOnlyModeManager` @Observable class to control sync features
- [X] **Acceptance:** CloudKit container exists, schema initialization ready but disabled, local-only mode functional

### 1.2 Core Data Models (Effort: Medium)

#### ✅ Essential @Model Classes
- [X] Create base `Task` model with `@Model` macro:
```swift
@Model
class Task {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdDate: Date
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdDate = Date()
    }
}
```
- [X] Create base `Habit` model with `@Model` macro and streak tracking properties
- [X] Create `Tag` model with `@Model` macro, SF Symbol icon, and color properties
- [X] Implement model relationships: Task-Tag (many-to-many), Habit-Tag (many-to-many)
- [X] Add validation logic for tag limits (max 3 per item, max 30 total)
- [X] **Acceptance:** All models compile, relationships work, validation prevents exceeding limits

#### ✅ SwiftData Relationships & Constraints
- [X] Implement `@Relationship` macros for Task-Tag associations
- [X] Implement `@Relationship` macros for Habit-Tag associations  
- [X] Add `@Attribute(.unique)` constraints where appropriate
- [X] Test model creation, relationship assignment, and constraint validation
- [X] Verify SwiftData persistence across app launches
- [X] **Acceptance:** Models persist correctly, relationships maintain integrity, constraints enforced

### 1.3 Apple MV Pattern Implementation (Effort: Medium)

#### ✅ Rich @Observable Models with Business Logic
- [X] Enhance `Task` model with business logic and validation:
```swift
@Model
@Observable
class Task {
    var title: String
    var isCompleted: Bool = false
    @Relationship var tags: [Tag] = []

    // Business logic in the model
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }

    func toggleCompletion() {
        isCompleted.toggle()
    }

    func addTag(_ tag: Tag) -> Bool {
        guard tags.count < 3 else { return false }
        tags.append(tag)
        return true
    }
}
```
- [X] Enhance `Habit` model with streak calculation and completion logic
- [X] Enhance `Tag` model with usage analytics and validation methods
- [X] Move business logic from managers into model classes
- [X] **Acceptance:** Models contain business logic, validation, computed properties; rich domain objects

#### ✅ Lightweight Service Layer
- [X] Create `TaskService` for queries and persistence operations:
```swift
@Observable
class TaskService {
    private let modelContext: ModelContext

    var todaysTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.dueDate?.isToday == true }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func save() throws {
        try modelContext.save()
    }
}
```
- [X] Create lightweight `HabitService` and `TagService` classes
- [X] Services handle only queries, persistence, and external I/O
- [X] Configure services in `DaisyDosApp.swift` using `.environment()` modifier
- [X] **Acceptance:** Services are lightweight coordinators, business logic lives in models

### 1.4 Error Handling Architecture (Effort: Small-Medium)

#### ✅ Three-Tier Error System
- [X] Create `DaisyDosError` enum with app-specific error cases:
```swift
enum DaisyDosError: Error {
    case modelContextUnavailable
    case dataCorrupted(String)
    case tagLimitExceeded
    case invalidRecurrence
}
```
- [X] Implement `RecoverableError` protocol for user-facing errors:
```swift
protocol RecoverableError: Error {
    var userMessage: String { get }
    var recoveryOptions: [RecoveryAction] { get }
}
```
- [X] Create error transformation utilities (platform → app → user)
- [X] Implement error presentation modifiers for SwiftUI
- [X] Test error handling with user-friendly messages
- [X] **Acceptance:** Errors display user-friendly messages, recovery options available, technical details hidden

### 1.5 UI Foundation & Design System (Effort: Medium)

#### ✅ Design System Implementation
- [X] Create `DesignSystem` structure with 8pt grid spacing constants
- [X] Implement typography scale (max 4 sizes, 2 weights):
```swift
extension Font {
    static let daisyTitle = Font.title2.weight(.semibold)
    static let daisyBody = Font.body.weight(.regular)
    static let daisyCaption = Font.caption.weight(.regular)
}
```
- [X] Define color scheme following 60-30-10 rule
- [X] Create liquid glass design modifiers and components
- [X] Implement accessibility baseline: 44pt touch targets, WCAG AA contrast
- [X] **Acceptance:** Consistent spacing, typography works with Dynamic Type, colors pass contrast tests

#### ✅ Core Reusable Components
- [X] Create base `CardView` component with liquid glass aesthetic
- [X] Create `PrimaryButton` and `SecondaryButton` with proper accessibility
- [X] Create `InputField` wrapper with validation and accessibility labels
- [X] Implement `LoadingView` and `EmptyStateView` components
- [X] Test all components with VoiceOver for accessibility compliance
- [X] **Acceptance:** Components render correctly, pass accessibility audit, reusable across contexts

### 1.6 Navigation Foundation (Effort: Small)

#### ✅ Tab-Based Navigation Shell
- [X] Create `ContentView` with `TabView` and independent `NavigationStack` per tab:
```swift
TabView(selection: $selectedTab) {
    NavigationStack(path: $navigationManager.todayPath) {
        TodayView()
    }.tabItem { Label("Today", systemImage: "calendar") }
}
```
- [X] Create `NavigationManager` @Observable class with separate `NavigationPath` per tab
- [X] Implement tab switching logic with state preservation
- [X] Add accessibility labels for tab items
- [X] Test navigation between tabs maintains independent state
- [X] **Acceptance:** Tab navigation works, independent navigation stacks, state preserved

### 1.7 Performance & Accessibility Baselines (Effort: Small)

#### ✅ Performance Monitoring
- [X] Implement launch time measurement (target: <2 seconds)
- [X] Add memory usage monitoring and reporting
- [X] Create UI response time measurement utilities (target: <100ms)
- [X] Set up basic performance test suite
- [X] Document baseline performance metrics
- [X] **Acceptance:** Performance monitoring active, baselines documented, meets targets

#### ✅ Accessibility Audit Framework
- [X] Configure VoiceOver testing for all implemented components
- [X] Validate Dynamic Type support from xSmall to xxxLarge
- [X] Test touch target sizes meet 44pt minimum requirement
- [X] Implement accessibility audit automation
- [X] Document accessibility compliance checklist
- [X] **Acceptance:** 100% VoiceOver navigation, Dynamic Type works, touch targets compliant

### Phase 1.0 Success Criteria
- [X] App launches in <2 seconds and navigates between tabs
- [X] Can create, read, delete basic tasks and habits using SwiftData
- [X] @Observable pattern proven with automatic UI updates
- [X] Error handling displays user-friendly messages
- [X] CloudKit foundation configured but disabled
- [X] Performance baselines established and documented
- [X] Accessibility compliance validated with audit
- [X] Local-only mode toggle functional
- [X] All architectural patterns validated through unit tests

---

## Phase 2.0: Core Task Management & Shared Component Validation
**Goals:** Complete task management, prove shared component strategy  
**Total Effort:** Large - Proves core architectural decisions  
**Dependencies:** Phase 1.0 complete

### 2.1 Complete Task Data Models (Effort: Medium)

#### ✅ Enhanced Task Model
- [ ] Extend `Task` model with priority levels (Low, Medium, High):
```swift
enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"  
    case high = "High"
}
```
- [ ] Add due date and start date properties with proper Date handling
- [ ] Implement subtask relationships with unlimited nesting:
```swift
@Relationship(deleteRule: .cascade) var subtasks: [Task] = []
@Relationship(inverse: \Task.subtasks) var parentTask: Task?
```
- [ ] Add attachment properties for PhotoKit integration
- [ ] Create `RecurrenceRule` struct with dynamic calculation
- [ ] **Acceptance:** Enhanced models persist correctly, relationships maintain integrity

#### ✅ Tag System Implementation
- [ ] Implement tag assignment validation (max 3 per task):
```swift
var tags: [Tag] = [] {
    didSet { 
        if tags.count > 3 { tags = Array(tags.prefix(3)) }
    }
}
```
- [ ] Create tag pool management (max 30 total tags system-wide)
- [ ] Implement SF Symbol icon selection and system color assignment
- [ ] Add drag & drop support for tag assignment
- [ ] Test tag validation across multiple task instances
- [ ] **Acceptance:** Tag limits enforced, visual feedback works, drag & drop functional

### 2.2 TaskRowView - Reusable Component Strategy (Effort: Medium)

#### ✅ TaskRowView Design for Maximum Reusability
- [ ] Create `TaskRowView` with composition pattern:
```swift
struct TaskRowView: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let showsSubtasks: Bool
    
    var body: some View {
        // Reusable row implementation
    }
}
```
- [ ] Implement configurable action closures for different contexts
- [ ] Add accessibility support with proper labels and hints
- [ ] Support multiple display modes (compact, detailed, today view)
- [ ] Test component in isolation with preview providers
- [ ] **Acceptance:** TaskRowView renders correctly, actions work, accessibility compliant

#### ✅ Cross-Context Validation
- [ ] Test TaskRowView in `TaskListView` context
- [ ] Test TaskRowView in search results context
- [ ] Test TaskRowView in Today View mockup context
- [ ] Validate consistent styling across all contexts
- [ ] Performance test with 100+ TaskRowView instances
- [ ] **Acceptance:** Component works identically in all contexts, performance acceptable

### 2.3 Complete Task Management Features (Effort: Large)

#### ✅ Task CRUD Operations
- [ ] Implement create task functionality with validation
- [ ] Implement task editing with proper state management
- [ ] Implement task deletion with cascade to subtasks
- [ ] Add bulk operations for multiple task selection
- [ ] Implement task duplication functionality
- [ ] **Acceptance:** All CRUD operations work reliably, data integrity maintained

#### ✅ Subtask Management
- [ ] Create subtask creation interface with nesting support
- [ ] Implement subtask reordering with drag & drop
- [ ] Add subtask completion propagation logic
- [ ] Create subtask progress indicators
- [ ] Test unlimited nesting depth functionality
- [ ] **Acceptance:** Subtasks work at any nesting level, UI remains performant

#### ✅ Advanced Task Features
- [ ] Implement PhotoKit integration for task attachments:
```swift
import PhotoKit

func requestPhotoLibraryPermission() {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        // Handle permission response
    }
}
```
- [ ] Create file attachment picker with proper permissions
- [ ] Implement recurrence rule creation and editing
- [ ] Add task priority sorting and filtering
- [ ] Create task search within task management
- [ ] **Acceptance:** Attachments work, recurrence calculates correctly, sorting/filtering responsive

### 2.4 Task Management UI Implementation (Effort: Medium)

#### ✅ TaskListView with Sections
- [ ] Create `TaskListView` using proven `TaskRowView` component
- [ ] Implement sectioning by priority, date, or completion status
- [ ] Add pull-to-refresh functionality
- [ ] Implement infinite scrolling for large task lists
- [ ] Create empty state handling with motivation
- [ ] **Acceptance:** List performs well with 500+ tasks, sectioning clear, empty states helpful

#### ✅ TaskDetailView
- [ ] Create comprehensive task detail view with all properties
- [ ] Implement inline editing for all task properties
- [ ] Add subtask management within detail view
- [ ] Create attachment gallery with PhotoKit integration
- [ ] Implement sharing functionality for tasks
- [ ] **Acceptance:** Detail view shows all data, editing works, attachments display correctly

#### ✅ Task Creation & Editing Forms
- [ ] Create intuitive task creation form with validation
- [ ] Implement date picker for due dates and start dates
- [ ] Add priority selection with visual feedback
- [ ] Create tag selection interface with visual assignment
- [ ] Implement form validation and error presentation
- [ ] **Acceptance:** Forms validate correctly, UX smooth, accessibility compliant

### Phase 2.0 Success Criteria
- [ ] Complete task management workflow functional
- [ ] TaskRowView proven reusable across 3+ different contexts without modification
- [ ] Shared component performance excellent with 100+ items
- [ ] Component composition patterns validated for future use
- [ ] Tag system working seamlessly for tasks with proper validation
- [ ] Accessibility compliance validated for all task components
- [ ] Error handling working end-to-end for all task operations
- [ ] Performance acceptable with moderate data loads (500+ tasks)
- [ ] Architectural patterns ready for habit implementation

---

## Phase 3.0: Core Habit Management & Component Consistency
**Goals:** Implement habit tracking using proven patterns from Phase 2.0  
**Total Effort:** Large - Validates architectural consistency  
**Dependencies:** Phase 2.0 complete, TaskRowView patterns established

### 3.1 Complete Habit Data Models (Effort: Medium)

#### ✅ Enhanced Habit Model
- [ ] Create comprehensive `Habit` model with `@Model` macro:
```swift
@Model
class Habit {
    var id: UUID
    var title: String
    var description: String
    var currentStreak: Int
    var longestStreak: Int
    var createdDate: Date
    var recurrenceRule: RecurrenceRule?
    @Relationship var completionEntries: [HabitCompletion] = []
    @Relationship var tags: [Tag] = []
}
```
- [ ] Create `HabitCompletion` model for tracking individual completions
- [ ] Create `HabitStreak` model for streak calculation and management
- [ ] Implement grace period logic for streak maintenance
- [ ] Add skip functionality with reason tracking
- [ ] **Acceptance:** Models persist correctly, streak calculations accurate, grace periods functional

#### ✅ Recurrence System Integration
- [ ] Implement `RecurrenceRule` struct with shared usage across tasks and habits:
```swift
struct RecurrenceRule: Codable {
    enum Frequency: String, CaseIterable, Codable {
        case daily, weekly, monthly, yearly, custom
    }
    
    let frequency: Frequency
    let interval: Int
    let daysOfWeek: Set<Int>?
    
    func nextOccurrence(after date: Date) -> Date? {
        // Dynamic calculation implementation
    }
}
```
- [ ] Test recurrence calculations for complex patterns
- [ ] Validate recurrence rule editing updates future occurrences
- [ ] Implement timezone handling for recurrence calculations
- [ ] **Acceptance:** Recurrence works for both tasks and habits, calculations accurate across time zones

### 3.2 HabitRowView - Component Consistency Validation (Effort: Medium)

#### ✅ HabitRowView Following TaskRowView Patterns
- [ ] Create `HabitRowView` using identical composition patterns as `TaskRowView`:
```swift
struct HabitRowView: View {
    let habit: Habit
    let onMarkComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void
    let showsStreak: Bool
    
    var body: some View {
        // Implementation following TaskRowView patterns
    }
}
```
- [ ] Ensure consistent styling and behavior with task components
- [ ] Add habit-specific features: streak display, completion status
- [ ] Implement accessibility patterns matching TaskRowView exactly
- [ ] Test component isolation with preview providers
- [ ] **Acceptance:** HabitRowView behaves consistently with TaskRowView, habit-specific features work

#### ✅ Cross-Context Consistency Testing
- [ ] Test HabitRowView in `HabitListView` context
- [ ] Test HabitRowView in search results context  
- [ ] Test HabitRowView in Today View mockup context
- [ ] Validate visual consistency with TaskRowView
- [ ] Performance test with 100+ HabitRowView instances
- [ ] **Acceptance:** Component works consistently across contexts, performance matches TaskRowView

### 3.3 Habit Analytics & Progress Tracking (Effort: Medium)

#### ✅ Streak Calculation System
- [ ] Implement accurate streak calculation logic with grace periods
- [ ] Create streak history tracking for analytics
- [ ] Add longest streak tracking and celebration
- [ ] Implement streak reset logic with user confirmation
- [ ] Test streak calculations across various scenarios
- [ ] **Acceptance:** Streak logic accurate, handles edge cases, user-friendly

#### ✅ Progress Visualization
- [ ] Implement basic progress charts using Charts framework:
```swift
import Charts

struct HabitProgressChart: View {
    let completionData: [HabitCompletion]
    
    var body: some View {
        Chart(completionData) { completion in
            // Chart implementation
        }
    }
}
```
- [ ] Create heatmap view for habit completion history
- [ ] Add weekly/monthly trend visualization
- [ ] Implement completion rate calculation and display
- [ ] Create motivational progress feedback
- [ ] **Acceptance:** Charts display correctly, heatmap intuitive, performance good with large datasets

### 3.4 Habit Management Features (Effort: Medium-Large)

#### ✅ Habit CRUD Operations
- [ ] Implement create habit functionality with validation
- [ ] Create habit editing interface with schedule customization
- [ ] Implement habit deletion with completion history handling
- [ ] Add habit archiving functionality for inactive habits
- [ ] Create habit template system for common habits
- [ ] **Acceptance:** All operations work reliably, data preserved, templates useful

#### ✅ Habit Completion System
- [ ] Implement mark complete functionality with timestamp
- [ ] Create undo completion functionality
- [ ] Add skip functionality with reason selection
- [ ] Implement bulk completion for multiple days
- [ ] Create completion reminder system
- [ ] **Acceptance:** Completion system intuitive, undo works, reminders functional

### 3.5 Habit Management UI Implementation (Effort: Medium)

#### ✅ HabitListView with Progress Indicators
- [ ] Create `HabitListView` using proven `HabitRowView` component
- [ ] Implement sectioning by frequency, streak status, or tags
- [ ] Add progress indicators showing completion rates
- [ ] Create sorting options (streak length, creation date, completion rate)
- [ ] Implement habit archival interface
- [ ] **Acceptance:** List performs well, progress clear, sorting responsive

#### ✅ HabitDetailView with Analytics
- [ ] Create comprehensive habit detail view with statistics
- [ ] Implement inline editing for habit properties
- [ ] Add completion history view with calendar display
- [ ] Create streak milestone celebrations
- [ ] Implement habit sharing functionality
- [ ] **Acceptance:** Detail view comprehensive, statistics accurate, celebrations motivating

#### ✅ Habit Creation & Scheduling Forms
- [ ] Create intuitive habit creation form
- [ ] Implement flexible scheduling interface (daily, weekly, custom)
- [ ] Add goal setting functionality (streak targets, completion rates)
- [ ] Create habit category selection
- [ ] Implement form validation specific to habits
- [ ] **Acceptance:** Scheduling flexible, goals motivating, validation appropriate

### Phase 3.0 Success Criteria
- [ ] Complete habit tracking workflow functional
- [ ] HabitRowView proven reusable across multiple contexts using identical patterns as TaskRowView
- [ ] Shared UI patterns consistent between Task and Habit components
- [ ] Accurate streak calculations with proper grace period handling
- [ ] Visual progress feedback compelling and motivating
- [ ] Tag system validated for both content types simultaneously
- [ ] Recurrence system working for both tasks and habits
- [ ] Performance benchmarks met for habit-specific calculations
- [ ] Component reusability patterns proven scalable

---

## Phase 4.0: Today View - Architectural Validation
**Goals:** Validate shared component architecture, deliver core value proposition  
**Total Effort:** Medium - Proves architecture works in practice  
**Dependencies:** Phases 2.0 & 3.0 complete with proven shared components

### 4.1 Today View Logic Implementation (Effort: Small-Medium)

#### ✅ Unified Data Filtering
- [ ] Implement `TodayManager` @Observable class:
```swift
@Observable
class TodayManager {
    private let taskManager: TaskManager
    private let habitManager: HabitManager
    
    var todaysItems: [TodayItem] {
        // Combine today's tasks and habits
    }
    
    var completedItems: [TodayItem] {
        // Filter completed items
    }
}
```
- [ ] Create `TodayItem` protocol for unified handling
- [ ] Implement intelligent prioritization algorithms
- [ ] Add date-based filtering logic for "today"
- [ ] Test data filtering performance with large datasets
- [ ] **Acceptance:** Filtering accurate, performance good, prioritization sensible

#### ✅ Today View Architecture
- [ ] Create `TodayView` using ONLY existing TaskRowView and HabitRowView:
```swift
struct TodayView: View {
    @Environment(TodayManager.self) private var todayManager
    
    var body: some View {
        // Use TaskRowView for tasks, HabitRowView for habits
        // NO custom components - pure reuse test
    }
}
```
- [ ] Implement mixed content display without modifying existing components
- [ ] Add sectioning (Morning, Afternoon, Evening) using existing patterns
- [ ] Test component reuse in unified context
- [ ] Validate accessibility in mixed content view
- [ ] **Acceptance:** Today View works using ONLY existing components without modification

### 4.2 Today-Specific Features (Effort: Small)

#### ✅ Daily Planning Interface
- [ ] Implement daily goal setting using existing form patterns
- [ ] Add quick rescheduling functionality
- [ ] Create daily motivation/inspiration display
- [ ] Implement quick task/habit creation from Today view
- [ ] Add daily progress summary
- [ ] **Acceptance:** Planning intuitive, rescheduling works, motivation helpful

#### ✅ Quick Actions Implementation
- [ ] Implement bulk completion actions
- [ ] Add quick edit functionality using existing forms
- [ ] Create rapid task/habit creation
- [ ] Implement smart suggestions based on patterns
- [ ] Add daily review functionality
- [ ] **Acceptance:** Quick actions save time, suggestions relevant, review valuable

### 4.3 Today View Polish (Effort: Small)

#### ✅ Success & Empty States
- [ ] Create motivational empty state for days with no items
- [ ] Implement success celebration when all items complete
- [ ] Add progress indicators for partially completed days
- [ ] Create helpful onboarding for first-time users
- [ ] Implement weather/context integration for enhanced daily planning
- [ ] **Acceptance:** States feel motivating, celebrations satisfying, onboarding helpful

### Phase 4.0 Success Criteria
- [ ] Today View delivers unified experience without component duplication
- [ ] Component reuse working effectively with zero modifications to TaskRowView or HabitRowView
- [ ] Performance excellent with realistic mixed daily loads (50+ items)
- [ ] Daily workflow feels natural and efficient
- [ ] Architectural validation complete - shared component strategy proven
- [ ] User testing validates core value proposition ("one app, complete picture")
- [ ] Accessibility working perfectly in mixed content context

---

## Phase 5.0: Search & Organization
**Goals:** Enable efficient content discovery across both tasks and habits  
**Total Effort:** Medium - Uses proven patterns from previous phases  
**Dependencies:** Phase 4.0 complete

### 5.1 Global Search Implementation (Effort: Medium)

#### ✅ Full-Text Search System
- [ ] Implement `SearchManager` @Observable class:
```swift
@Observable 
class SearchManager {
    private let taskManager: TaskManager
    private let habitManager: HabitManager
    
    func search(_ query: String) -> SearchResults {
        let taskDescriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.title.contains(query) || task.description.contains(query)
            }
        )
        // Combined search implementation
    }
}
```
- [ ] Implement real-time search with debouncing
- [ ] Create search result ranking algorithm
- [ ] Add search history functionality
- [ ] Test search performance with large datasets (1000+ items)
- [ ] **Acceptance:** Search fast and accurate, results ranked sensibly, history useful

#### ✅ Search Results Display
- [ ] Create `SearchResultsView` using existing TaskRowView and HabitRowView
- [ ] Implement mixed results display with proper sectioning
- [ ] Add search result highlighting
- [ ] Create "no results found" state with suggestions
- [ ] Implement search suggestions based on user patterns
- [ ] **Acceptance:** Results clear, highlighting helpful, suggestions relevant

### 5.2 Advanced Filtering System (Effort: Medium)

#### ✅ Filter Implementation
- [ ] Create comprehensive filter options: tags, dates, completion status, priority
- [ ] Implement filter combination logic (AND/OR operations)
- [ ] Add quick filter buttons for common searches
- [ ] Create filter persistence across app sessions
- [ ] Implement filter clearing and reset functionality
- [ ] **Acceptance:** Filters powerful and intuitive, combinations work correctly, persistence helpful

#### ✅ Smart Lists (Saved Searches)
- [ ] Implement saved search creation and management
- [ ] Create smart list automatic updating
- [ ] Add smart list sharing functionality
- [ ] Implement template smart lists for common use cases
- [ ] Create smart list performance optimization for large datasets
- [ ] **Acceptance:** Smart lists save time, update automatically, templates useful

### 5.3 Organization Features (Effort: Small-Medium)

#### ✅ Enhanced Tag Management
- [ ] Create comprehensive tag management interface
- [ ] Implement tag usage analytics
- [ ] Add tag merging and splitting functionality
- [ ] Create tag-based organization views
- [ ] Implement tag color and icon customization
- [ ] **Acceptance:** Tag management powerful, analytics insightful, customization intuitive

#### ✅ Bulk Operations
- [ ] Implement multi-select functionality for both tasks and habits
- [ ] Add bulk tag assignment/removal
- [ ] Create bulk status changes (completion, priority, etc.)
- [ ] Implement bulk delete with confirmation
- [ ] Add bulk export functionality
- [ ] **Acceptance:** Bulk operations save time, confirmations prevent mistakes, export useful

### Phase 5.0 Success Criteria
- [ ] Fast, accurate search results across all content
- [ ] Intuitive filtering interface with saved configurations
- [ ] Smart Lists provide ongoing value to users
- [ ] Search scales efficiently with larger datasets (1000+ items)
- [ ] Consistent experience using proven shared components
- [ ] Tag management comprehensive and user-friendly

---

## Phase 6.0: Calendar Integration
**Goals:** Provide temporal visualization and iOS ecosystem integration  
**Total Effort:** Medium - New integration complexity  
**Dependencies:** Phase 5.0 complete

### 6.1 EventKit Integration (Effort: Medium)

#### ✅ Calendar Permission & Setup
- [ ] Implement EventKit permission request:
```swift
import EventKit

func requestCalendarPermission() async -> Bool {
    let eventStore = EKEventStore()
    let status = await eventStore.requestFullAccessToEvents()
    return status == .authorized
}
```
- [ ] Create `CalendarManager` @Observable class for EventKit operations
- [ ] Implement calendar event reading with privacy considerations
- [ ] Add error handling for denied permissions
- [ ] Test with various calendar configurations and data sizes
- [ ] **Acceptance:** Permission flow clear, error handling graceful, performance good with large calendars

#### ✅ Calendar Data Integration
- [ ] Implement calendar event fetching with date ranges
- [ ] Create conflict detection between tasks and calendar events
- [ ] Add calendar event display alongside tasks and habits
- [ ] Implement smart scheduling suggestions based on calendar availability
- [ ] Create calendar-based task reminder system
- [ ] **Acceptance:** Integration seamless, conflicts detected, suggestions helpful

### 6.2 Calendar Views Implementation (Effort: Medium)

#### ✅ Day/Week/Month Views
- [ ] Create `CalendarDayView` showing tasks, habits, and calendar events
- [ ] Implement `CalendarWeekView` with task distribution visualization
- [ ] Create `CalendarMonthView` with density indicators for busy days
- [ ] Add navigation between calendar views
- [ ] Implement date selection with detail display
- [ ] **Acceptance:** Views informative and navigable, density indicators helpful

#### ✅ Calendar-Specific Features
- [ ] Implement task scheduling directly from calendar interface
- [ ] Add visual density indicators for overloaded days
- [ ] Create drag-and-drop rescheduling within calendar views
- [ ] Implement calendar export functionality
- [ ] Add calendar view preferences (week start day, time format, etc.)
- [ ] **Acceptance:** Scheduling intuitive, rescheduling smooth, preferences respected

### Phase 6.0 Success Criteria
- [ ] Calendar views provide useful task and habit overview
- [ ] iOS Calendar integration feels seamless and natural
- [ ] Performance acceptable with full calendar data access
- [ ] Privacy and permissions handled transparently
- [ ] Visual design consistent with app aesthetic
- [ ] Conflict detection and scheduling suggestions valuable

---

## Phase 7.0: Settings & Privacy Controls
**Goals:** Complete user customization and privacy implementation  
**Total Effort:** Small-Medium - Foundation for future cloud features  
**Dependencies:** Phase 6.0 complete

### 7.1 Settings Architecture (Effort: Small)

#### ✅ Settings Navigation & Structure
- [ ] Create hierarchical settings navigation structure
- [ ] Implement settings persistence using UserDefaults + SwiftData hybrid
- [ ] Create settings validation and constraint enforcement
- [ ] Add settings search functionality
- [ ] Implement settings import/export foundation
- [ ] **Acceptance:** Settings well-organized, persistence reliable, search helpful

### 7.2 Privacy Controls Implementation (Effort: Small-Medium)

#### ✅ Local-Only Mode
- [ ] Implement comprehensive local-only mode toggle:
```swift
@Observable
class PrivacyManager {
    @AppStorage("localOnlyMode") var isLocalOnlyMode: Bool = true
    
    func enableCloudSync() {
        guard !isLocalOnlyMode else { return }
        // Cloud sync logic
    }
}
```
- [ ] Create data retention controls with user-selectable options
- [ ] Implement permission management interface for all integrations
- [ ] Add privacy dashboard showing data usage and sharing status
- [ ] Create data deletion functionality with confirmation
- [ ] **Acceptance:** Local-only mode completely functional, privacy controls transparent

#### ✅ Data Retention Management
- [ ] Implement tiered data retention system (90/365/indefinite days)
- [ ] Create automatic cleanup processes with user notification
- [ ] Add manual data cleanup functionality
- [ ] Implement storage usage monitoring and reporting
- [ ] Create data export before deletion
- [ ] **Acceptance:** Data retention automatic and transparent, cleanup works correctly

### 7.3 Customization Options (Effort: Small)

#### ✅ Appearance & Behavior Settings
- [ ] Implement theme controls (light/dark/auto) with system integration
- [ ] Create notification preferences with granular control
- [ ] Add default behavior settings for task/habit creation
- [ ] Implement workflow customization options
- [ ] Create accessibility preference overrides
- [ ] **Acceptance:** Customizations enhance experience, preferences persist correctly

### Phase 7.0 Success Criteria
- [ ] Comprehensive settings coverage for all user preferences
- [ ] Local-only mode completely functional and respected throughout app
- [ ] Settings persist correctly and sync when appropriate
- [ ] Privacy controls give users confidence and transparency
- [ ] Customization options enhance rather than complicate experience
- [ ] Data retention working automatically without user intervention

---

## Phase 8.0: Data Management & Sync Preparation
**Goals:** Implement data management and prepare CloudKit integration  
**Total Effort:** Medium - Foundation for Phase 10.0 cloud sync  
**Dependencies:** Phase 7.0 complete with privacy controls

### 8.1 Data Retention System (Effort: Small-Medium)

#### ✅ Tiered Retention Implementation
- [ ] Implement 90-day raw event retention with automatic aggregation
- [ ] Create daily aggregation processes for analytics
- [ ] Implement monthly statistics generation
- [ ] Add automatic cleanup processes with user notification
- [ ] Create storage optimization and monitoring
- [ ] **Acceptance:** Data aggregates correctly, cleanup automatic, storage optimized

### 8.2 CloudKit Preparation Enhancement (Effort: Medium)

#### ✅ Complete CloudKit Foundation
- [ ] Implement full CloudKit container setup and validation
- [ ] Create comprehensive sync preparation with all models ready
- [ ] Implement conflict resolution framework
- [ ] Add network error handling and offline capability
- [ ] Create sync progress monitoring and user feedback
- [ ] **Acceptance:** CloudKit integration complete but disabled, ready for activation

### 8.3 Backup & Export Systems (Effort: Small-Medium)

#### ✅ Backup System
- [ ] Implement encrypted local backup creation
- [ ] Create backup restoration functionality with validation
- [ ] Add automatic backup scheduling
- [ ] Implement backup integrity verification
- [ ] Create backup management interface
- [ ] **Acceptance:** Backups reliable and secure, restoration works correctly

#### ✅ Data Export/Import
- [ ] Implement multiple export formats (JSON, CSV, PDF)
- [ ] Create comprehensive data import with validation
- [ ] Add selective export/import functionality
- [ ] Implement data integrity verification during import
- [ ] Create export scheduling and automation
- [ ] **Acceptance:** Export/import reliable, formats useful, integrity maintained

### Phase 8.0 Success Criteria
- [ ] Data retention working automatically without user intervention
- [ ] CloudKit integration ready for activation but remains disabled
- [ ] Backup/restore working reliably for all local data
- [ ] Storage usage optimized and transparent to users
- [ ] Export/import functionality validated with real data
- [ ] Network error handling robust for future cloud features

---

## Phase 9.0: Advanced Features & Polish
**Goals:** Complete remaining MVP features and optimize for production  
**Total Effort:** Medium-Large - Production readiness focus  
**Dependencies:** Phase 8.0 complete

### 9.1 Advanced UI Features (Effort: Medium)

#### ✅ Drag & Drop Implementation
- [ ] Implement reordering within task and habit lists
- [ ] Create drag & drop for tag assignment with visual feedback
- [ ] Add cross-context drag & drop (tasks to different lists)
- [ ] Implement haptic feedback for drag operations
- [ ] Test drag & drop accessibility with assistive technologies
- [ ] **Acceptance:** Drag & drop intuitive and accessible, haptics appropriate

#### ✅ Advanced Interaction Patterns
- [ ] Implement comprehensive swipe actions and gesture support
- [ ] Add contextual menus with relevant actions
- [ ] Create keyboard shortcuts for power users
- [ ] Implement advanced selection modes
- [ ] Add gesture-based navigation enhancements
- [ ] **Acceptance:** Interactions feel natural, shortcuts save time, gestures intuitive

### 9.2 Performance Optimization (Effort: Medium)

#### ✅ Large Dataset Handling
- [ ] Implement pagination for lists with 1000+ items
- [ ] Create virtual scrolling for performance
- [ ] Add lazy loading for images and attachments
- [ ] Implement background task optimization
- [ ] Create memory leak prevention and monitoring
- [ ] **Acceptance:** App performs excellently with large datasets (1000+ items)

#### ✅ Launch Time & Responsiveness
- [ ] Optimize app launch sequence for <2 second target
- [ ] Implement perceived performance improvements
- [ ] Create background data preparation
- [ ] Add progressive loading for UI elements
- [ ] Optimize battery usage during background operations
- [ ] **Acceptance:** Launch consistently <2 seconds, interactions always <100ms

### 9.3 Notification System (Effort: Small-Medium)

#### ✅ UserNotifications Implementation
- [ ] Implement comprehensive notification system:
```swift
import UserNotifications

func scheduleTaskReminder(for task: Task, at date: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Task Due Soon"
    content.body = task.title
    // Notification scheduling
}
```
- [ ] Create habit reminder notifications with customizable timing
- [ ] Implement notification action buttons for quick completion
- [ ] Add notification grouping and management
- [ ] Create notification analytics and optimization
- [ ] **Acceptance:** Notifications timely and helpful, actions work correctly

### 9.4 Advanced Error Recovery (Effort: Small)

#### ✅ Data Repair & Recovery
- [ ] Implement data corruption detection and repair
- [ ] Create automatic data recovery from backups
- [ ] Add manual data repair tools for users
- [ ] Implement recovery progress reporting
- [ ] Create data validation and integrity checking
- [ ] **Acceptance:** Data corruption handled gracefully, recovery automated

### Phase 9.0 Success Criteria
- [ ] App feels polished, responsive, and production-ready
- [ ] Performance excellent with large datasets (1000+ items)
- [ ] Accessibility exceeds WCAG 2.1 AA requirements
- [ ] User experience cohesive and delightful throughout
- [ ] All advanced features work reliably without regression
- [ ] Error recovery handles edge cases gracefully

---

## Phase 10.0: CloudKit Sync & Cloud Features
**Goals:** Enable reliable multi-device synchronization  
**Total Effort:** Large - Complex cloud integration  
**Dependencies:** Phase 9.0 complete, Phase 8.0 CloudKit foundation ready

### 10.1 CloudKit Sync Activation (Effort: Large)

#### ✅ Sync Implementation
- [ ] Activate CloudKit sync using prepared foundation from Phase 8.0
- [ ] Implement bidirectional synchronization for all models
- [ ] Create sync conflict resolution UI with user-friendly choices
- [ ] Add sync progress indicators and status reporting
- [ ] Implement offline capability maintenance during sync issues
- [ ] **Acceptance:** Reliable sync across devices, conflicts resolved intuitively

#### ✅ Sync Optimization
- [ ] Implement incremental sync for large datasets
- [ ] Create sync batching and throttling
- [ ] Add network efficiency optimizations
- [ ] Implement sync retry logic with exponential backoff
- [ ] Create sync analytics and monitoring
- [ ] **Acceptance:** Sync efficient and reliable, network usage optimized

### 10.2 Cloud-Enabled Features (Effort: Medium)

#### ✅ Cross-Device Features
- [ ] Implement cross-device tag consistency and management
- [ ] Create shared data validation and integrity checking
- [ ] Add cloud backup integration with local backups
- [ ] Implement sync settings and preferences across devices
- [ ] Create device management interface
- [ ] **Acceptance:** Features work consistently across devices, management intuitive

#### ✅ Collaboration Foundation
- [ ] Prepare framework for future sharing features
- [ ] Implement user identification and management
- [ ] Create permission system for shared data
- [ ] Add sharing invitation framework
- [ ] Implement shared data conflict resolution
- [ ] **Acceptance:** Foundation ready for future collaboration features

### Phase 10.0 Success Criteria
- [ ] Reliable multi-device sync with minimal user intervention
- [ ] Conflict resolution works intuitively for non-technical users
- [ ] Local-only mode remains fully functional for privacy-conscious users
- [ ] Sync performance acceptable across all supported devices
- [ ] Cloud features enhance rather than complicate the experience
- [ ] Data integrity maintained across all sync scenarios

---

## Continuous Validation Framework

### Per-Phase Validation Requirements

#### Accessibility Audits (All Phases)
- [ ] **Phase 1.0**: VoiceOver navigation baseline, Dynamic Type foundation, 44pt touch targets
- [ ] **Phase 2.0**: TaskRowView accessibility excellence, task-specific labels and navigation
- [ ] **Phase 3.0**: HabitRowView accessibility consistency, habit-specific patterns
- [ ] **Phase 4.0**: Mixed content accessibility in Today View, unified navigation
- [ ] **Phase 5.0**: Search interface accessibility with complex filtering
- [ ] **Phase 6.0**: Calendar accessibility with temporal navigation
- [ ] **Ongoing**: WCAG 2.1 AA compliance validation and continuous improvement

#### Performance Validation (All Phases)
- [ ] **Phase 1.0**: Baseline establishment (launch <2s, memory usage baseline)
- [ ] **Phase 2.0**: TaskRowView performance with 100+ items, shared component optimization
- [ ] **Phase 3.0**: HabitRowView performance consistency, streak calculation optimization
- [ ] **Phase 4.0**: Today View performance with realistic mixed loads (50+ items)
- [ ] **Phase 5.0**: Search performance with full-text queries across large datasets (1000+ items)
- [ ] **Phase 6.0**: Calendar integration performance with large calendar datasets
- [ ] **Ongoing**: 100ms UI response time validation and optimization

#### Testing Requirements (All Phases)
- [ ] **Phase 1.0**: Architecture unit tests, error handling integration tests, @Observable pattern tests
- [ ] **Phase 2.0**: TaskRowView reusability across contexts, task management integration tests
- [ ] **Phase 3.0**: HabitRowView consistency tests, streak calculation accuracy tests
- [ ] **Phase 4.0**: End-to-end Today View workflow tests, architectural validation
- [ ] **Phase 5.0**: Search functionality and performance tests, filter accuracy tests
- [ ] **Phase 6.0**: Calendar integration tests, EventKit permission handling
- [ ] **Ongoing**: Regression testing, accessibility automation, error recovery tests

### Cross-Phase Dependencies & Blockers

#### Critical Path Dependencies
1. **Phase 1.0 Architecture** → All subsequent phases
   - @Observable + SwiftData patterns must be proven
   - Error handling system must be functional
   - Performance baselines must be established

2. **Phase 2.0 TaskRowView** → Phase 4.0 Today View
   - TaskRowView reusability must be PROVEN across 3+ contexts
   - Component performance must be acceptable with 100+ instances
   - Accessibility patterns must be established

3. **Phase 3.0 HabitRowView** → Phase 4.0 Today View
   - HabitRowView must follow identical patterns as TaskRowView
   - Component consistency must be validated
   - Performance must match TaskRowView benchmarks

4. **Phase 7.0 Privacy Controls** → Phase 10.0 CloudKit Sync
   - Local-only mode must be completely functional
   - Privacy controls must be comprehensive and transparent
   - Data retention system must be working automatically

5. **Phase 8.0 Data Management** → Phase 10.0 CloudKit Sync
   - CloudKit foundation must be complete but disabled
   - Data retention and backup systems must be reliable
   - Conflict resolution framework must be prepared

#### Risk Mitigation Checkpoints
- [ ] **After Phase 1.0**: Architectural patterns validated, performance baseline established
- [ ] **After Phase 2.0**: Shared component strategy proven, reusability confirmed
- [ ] **After Phase 3.0**: Component consistency validated, architectural scalability confirmed
- [ ] **After Phase 4.0**: Core value proposition delivered, shared components proven in production use
- [ ] **After Phase 7.0**: Privacy and local functionality bullet-proof before any cloud features
- [ ] **After Phase 8.0**: CloudKit foundation solid, data management reliable

---

## Quality Gates & Acceptance Criteria

### Definition of Done (All Tasks)
Every task must meet these criteria before being marked complete:

1. **Functionality**: Feature works as specified in all supported scenarios
2. **Accessibility**: Passes VoiceOver navigation, meets 44pt touch targets, supports Dynamic Type
3. **Performance**: Meets phase-specific performance requirements
4. **Error Handling**: Graceful error handling with user-friendly messages
5. **Testing**: Appropriate unit/integration tests written and passing
6. **Documentation**: Implementation documented, architectural decisions recorded
7. **Code Review**: Code reviewed for quality, consistency, and maintainability

### Phase Gate Criteria
Each phase must pass these gates before proceeding:

1. **All tasks completed** and marked with checkboxes
2. **Performance benchmarks met** for phase-specific requirements
3. **Accessibility audit passed** with no critical violations
4. **Integration testing passed** for phase-specific features
5. **User testing completed** (where applicable) with positive feedback
6. **Technical debt assessed** and documented for future phases

---

## Usage Instructions

### Daily Implementation
1. Select tasks from current phase in order
2. Check off completed tasks with ✅
3. Validate acceptance criteria before marking complete
4. Document any architectural decisions or learnings
5. Update performance benchmarks as you go

### Quality Assurance
- Run accessibility audit after each component implementation
- Performance test after each major feature completion  
- Integration test at the end of each phase
- User test key workflows at phase boundaries

### Phase Transitions
1. Complete all tasks in current phase
2. Validate all phase success criteria met
3. Document lessons learned and architectural decisions
4. Update performance baselines for next phase
5. Plan any architectural adjustments needed

### Continuous Tracking
- Maintain performance metrics spreadsheet
- Keep accessibility compliance checklist updated
- Document component reusability validations
- Track technical debt and refactoring needs

This roadmap ensures systematic progress while validating architectural decisions at each step. The shared component strategy is proven early and relied upon throughout, while privacy and performance remain first-class concerns from the beginning.
