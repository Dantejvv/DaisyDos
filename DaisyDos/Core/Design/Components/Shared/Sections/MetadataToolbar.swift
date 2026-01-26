//
//  MetadataToolbar.swift
//  DaisyDos
//
//  Standardized metadata toolbar for Add/Edit views
//  Displays date, recurrence, alert, and priority with compact icons
//
//  FEATURE FLAG SYSTEM:
//  ════════════════════════════════════════════════════════════════════════════
//  Use MetadataToolbarConfig to control which features appear in the toolbar.
//  This makes it easy to add new features or create custom configurations.
//
//  PREDEFINED CONFIGURATIONS:
//  - .task      → Due date, recurrence, alert, priority
//  - .habit     → Recurrence, alert, priority (no due date)
//  - .full      → All features enabled (future-proof)
//  - .minimal   → Only priority (for simple use cases)
//  - .custom()  → Build your own feature set
//
//  ADDING NEW FEATURES:
//  1. Add new Bool property to MetadataToolbarConfig (e.g., showLocation)
//  2. Update static configurations as needed
//  3. Add conditional UI in MetadataToolbar body
//  4. Add corresponding parameter and action to init
//
//  Example for future "location" feature:
//  ```swift
//  struct MetadataToolbarConfig {
//      var showDate: Bool
//      var showRecurrence: Bool
//      var showAlert: Bool
//      var showPriority: Bool
//      var showLocation: Bool  // ← New feature
//  }
//  ```
//

import SwiftUI

/// Configuration for which metadata features to display in the toolbar
///
/// **Feature Flags Control**:
/// - `showDate`: Due date picker (Tasks only)
/// - `showRecurrence`: Recurrence rule picker (Tasks & Habits)
/// - `showReminder`: Reminder date/time picker (Tasks & Habits - both use absolute Date)
/// - `showPriority`: Priority picker (Tasks & Habits)
///
/// **Usage**:
/// ```swift
/// // Use predefined configurations
/// MetadataToolbar(config: .task, ...)
/// MetadataToolbar(config: .habit, ...)
///
/// // Or create custom configuration
/// let customConfig = MetadataToolbarConfig(
///     showDate: true,
///     showRecurrence: true,
///     showAlert: false,
///     showPriority: true
/// )
/// MetadataToolbar(config: customConfig, ...)
/// ```
struct MetadataToolbarConfig {
    var showDate: Bool
    var showRecurrence: Bool
    var showReminder: Bool  // For both tasks and habits (absolute date or alert time)
    var showPriority: Bool

    // MARK: - Predefined Configurations

    /// Full configuration - all features enabled
    /// Use this as default for maximum functionality
    static let full = MetadataToolbarConfig(
        showDate: true,
        showRecurrence: true,
        showReminder: true,
        showPriority: true
    )

    /// Task configuration - includes due date and reminder
    /// Rationale: Tasks are deadline-oriented work items with absolute reminders
    static let task = full

    /// Habit configuration - no due date, uses reminder (alert time)
    /// Rationale: Habits use alert time for time-of-day notifications
    static let habit = MetadataToolbarConfig(
        showDate: false,
        showRecurrence: true,
        showReminder: true,
        showPriority: true
    )

    /// Minimal configuration - priority only
    /// Use for simple use cases or progressive disclosure
    static let minimal = MetadataToolbarConfig(
        showDate: false,
        showRecurrence: false,
        showReminder: false,
        showPriority: true
    )

    // MARK: - Custom Configuration Builder

    /// Create a custom configuration with specific features
    /// - Parameters:
    ///   - features: Set of features to enable
    /// - Returns: Configuration with only specified features enabled
    ///
    /// Example:
    /// ```swift
    /// let config = MetadataToolbarConfig.custom([.recurrence, .priority])
    /// ```
    static func custom(_ features: Set<Feature>) -> MetadataToolbarConfig {
        MetadataToolbarConfig(
            showDate: features.contains(.date),
            showRecurrence: features.contains(.recurrence),
            showReminder: features.contains(.reminder),
            showPriority: features.contains(.priority)
        )
    }

    /// Available metadata features
    enum Feature: String, CaseIterable {
        case date = "Due Date"
        case recurrence = "Recurrence"
        case reminder = "Reminder"
        case priority = "Priority"
    }
}

/// A standardized toolbar for displaying and editing task/habit metadata.
///
/// Features:
/// - Configurable button display (date, recurrence, alert, priority)
/// - Compact icon buttons with labels
/// - Active/inactive visual states
/// - Due date display on left when active
/// - Consistent styling and spacing
///
/// Example:
/// ```swift
/// MetadataToolbar(
///     config: .task,
///     dueDate: $dueDate,
///     recurrenceRule: $recurrenceRule,
///     reminderDate: $reminderDate,
///     priority: $priority,
///     accentColor: .daisyTask,
///     onDateTap: { showingDatePicker = true },
///     onRecurrenceTap: { showingRecurrencePicker = true },
///     onReminderTap: { showingReminderPicker = true },
///     onPriorityTap: { showingPriorityPicker = true }
/// )
/// ```
struct MetadataToolbar: View {
    @Environment(AppearanceManager.self) private var appearanceManager

    let config: MetadataToolbarConfig
    let dueDate: Date?
    let recurrenceRule: RecurrenceRule?
    let reminderDate: Date?  // For non-recurring items - absolute reminder date/time
    let alertTimeHour: Int?  // For recurring items - alert time hour (0-23)
    let alertTimeMinute: Int?  // For recurring items - alert time minute (0-59)
    let priority: Priority?
    let accentColor: Color
    let onDateTap: () -> Void
    let onRecurrenceTap: () -> Void
    let onReminderTap: () -> Void  // For tasks and habits
    let onPriorityTap: () -> Void

    init(
        config: MetadataToolbarConfig = .full,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        reminderDate: Date? = nil,
        alertTimeHour: Int? = nil,
        alertTimeMinute: Int? = nil,
        priority: Priority? = nil,
        accentColor: Color = .daisyTask,
        onDateTap: @escaping () -> Void = {},
        onRecurrenceTap: @escaping () -> Void = {},
        onReminderTap: @escaping () -> Void = {},
        onPriorityTap: @escaping () -> Void = {}
    ) {
        self.config = config
        self.dueDate = dueDate
        self.recurrenceRule = recurrenceRule
        self.reminderDate = reminderDate
        self.alertTimeHour = alertTimeHour
        self.alertTimeMinute = alertTimeMinute
        self.priority = priority
        self.accentColor = accentColor
        self.onDateTap = onDateTap
        self.onRecurrenceTap = onRecurrenceTap
        self.onReminderTap = onReminderTap
        self.onPriorityTap = onPriorityTap
    }

    private var hasDueDate: Bool {
        dueDate != nil
    }

    private var hasReminder: Bool {
        // Has reminder if either absolute date or alert time is set
        reminderDate != nil || alertTimeHour != nil
    }

    private var formattedDueDate: String {
        guard let date = dueDate else { return "Due Date" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hasTime = components.hour != 0 || components.minute != 0

        if hasTime {
            return date.formatted(date: .abbreviated, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    /// Short label for reminder display in toolbar
    /// Shows alert time for recurring items, absolute date/time for non-recurring
    private var reminderShortLabel: String {
        // For recurring items with alert time
        if recurrenceRule != nil, let hour = alertTimeHour, let minute = alertTimeMinute {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            if let date = Calendar.current.date(from: components) {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: date)
            }
        }

        // For non-recurring items with absolute date
        guard let date = reminderDate else { return "" }
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tmrw"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: 12) {
                // Due Date - Show as text on left when active
                if config.showDate && hasDueDate {
                    Button(action: onDateTap) {
                        Text(formattedDueDate)
                            .font(.caption.weight(.medium))
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Due date: \(formattedDueDate)")
                }

                Spacer()

                // Calendar icon - only shows when no date is set
                if config.showDate && !hasDueDate {
                    CompactIconButton(
                        icon: "calendar",
                        isActive: false,
                        accentColor: accentColor,
                        action: onDateTap
                    )
                    .accessibilityLabel("Set due date")
                }

                // Recurrence Icon with label
                if config.showRecurrence {
                    VStack(spacing: 2) {
                        CompactIconButton(
                            icon: recurrenceRule != nil ? "repeat.circle.fill" : "repeat",
                            isActive: recurrenceRule != nil,
                            accentColor: accentColor,
                            action: onRecurrenceTap
                        )
                        .accessibilityLabel(recurrenceRule != nil ? "Recurrence: \(recurrenceRule!.frequencyDisplayName)" : "Set recurrence")

                        if let rule = recurrenceRule {
                            Text(rule.frequencyDisplayName)
                                .font(.system(size: 9))
                                .foregroundColor(accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                }

                // Reminder Icon with label (for Tasks - absolute date/time)
                if config.showReminder {
                    VStack(spacing: 2) {
                        CompactIconButton(
                            icon: hasReminder ? "bell.fill" : "bell",
                            isActive: hasReminder,
                            accentColor: accentColor,
                            action: onReminderTap
                        )
                        .accessibilityLabel(hasReminder ? "Reminder: \(reminderShortLabel)" : "Set reminder")

                        if hasReminder {
                            Text(reminderShortLabel)
                                .font(.system(size: 9))
                                .foregroundColor(accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                }

                // Priority Icon with label
                if config.showPriority {
                    VStack(spacing: 2) {
                        let priorityValue = priority ?? .none
                        let priorityColor = priorityValue != .none ? priorityValue.color(from: appearanceManager) : accentColor

                        CompactIconButton(
                            icon: priorityValue.sfSymbol ?? "flag",
                            isActive: priorityValue != .none,
                            accentColor: priorityColor,
                            action: onPriorityTap
                        )
                        .accessibilityLabel(priorityValue != .none ? "Priority: \(priorityValue.rawValue)" : "Set priority")

                        if priorityValue != .none {
                            Text(priorityValue.rawValue)
                                .font(.system(size: 9))
                                .foregroundColor(priorityColor)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview("Task Configuration") {
    VStack(spacing: 20) {
        Text("Task Toolbar (.task)")
            .font(.headline)

        // Task - Empty state
        MetadataToolbar(
            config: .task,
            accentColor: .daisyTask,
            onDateTap: { print("Date tapped") },
            onRecurrenceTap: { print("Recurrence tapped") },
            onReminderTap: { print("Reminder tapped") },
            onPriorityTap: { print("Priority tapped") }
        )
        .padding()

        // Task - All metadata set
        MetadataToolbar(
            config: .task,
            dueDate: Date(),
            recurrenceRule: RecurrenceRule(frequency: .daily, interval: 1),
            reminderDate: Date().addingTimeInterval(3600),
            priority: .high,
            accentColor: .daisyTask,
            onDateTap: { print("Date tapped") },
            onRecurrenceTap: { print("Recurrence tapped") },
            onReminderTap: { print("Reminder tapped") },
            onPriorityTap: { print("Priority tapped") }
        )
        .padding()
    }
    .background(Color.daisyBackground)
}

#Preview("Habit Configuration") {
    VStack(spacing: 20) {
        Text("Habit Toolbar (.habit)")
            .font(.headline)

        // Habit - No due date (by design), uses alert time
        MetadataToolbar(
            config: .habit,
            recurrenceRule: RecurrenceRule(frequency: .weekly, interval: 1),
            alertTimeHour: 9,
            alertTimeMinute: 0,
            priority: .medium,
            accentColor: .daisyHabit,
            onRecurrenceTap: { print("Recurrence tapped") },
            onReminderTap: { print("Alert tapped") },
            onPriorityTap: { print("Priority tapped") }
        )
        .padding()
    }
    .background(Color.daisyBackground)
}

#Preview("Custom Configurations") {
    VStack(spacing: 20) {
        Text("Custom Feature Combinations")
            .font(.headline)

        // Minimal - Priority only
        Text(".minimal (priority only)")
            .font(.caption)
        MetadataToolbar(
            config: .minimal,
            priority: .high,
            accentColor: .orange,
            onPriorityTap: { print("Priority tapped") }
        )
        .padding(.horizontal)

        // Custom - Recurrence + Priority
        Text(".custom([.recurrence, .priority])")
            .font(.caption)
        MetadataToolbar(
            config: .custom([.recurrence, .priority]),
            recurrenceRule: RecurrenceRule(frequency: .monthly, interval: 1),
            priority: .low,
            accentColor: .purple,
            onRecurrenceTap: { print("Recurrence tapped") },
            onPriorityTap: { print("Priority tapped") }
        )
        .padding(.horizontal)

        // Custom - Reminder only
        Text(".custom([.reminder])")
            .font(.caption)
        MetadataToolbar(
            config: .custom([.reminder]),
            reminderDate: Date().addingTimeInterval(7200),
            accentColor: .cyan,
            onReminderTap: { print("Reminder tapped") }
        )
        .padding(.horizontal)
    }
    .padding()
    .background(Color.daisyBackground)
}
