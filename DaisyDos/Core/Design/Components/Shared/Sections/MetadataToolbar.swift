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
/// - `showAlert`: Alert/notification picker (Tasks & Habits)
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
    var showAlert: Bool
    var showPriority: Bool

    // MARK: - Predefined Configurations

    /// Full configuration - all features enabled
    /// Use this as default for maximum functionality
    static let full = MetadataToolbarConfig(
        showDate: true,
        showRecurrence: true,
        showAlert: true,
        showPriority: true
    )

    /// Task configuration - includes due date
    /// Rationale: Tasks are deadline-oriented work items
    static let task = full

    /// Habit configuration - no due date
    /// Rationale: Habits use recurrence patterns, not deadlines
    static let habit = MetadataToolbarConfig(
        showDate: false,
        showRecurrence: true,
        showAlert: true,
        showPriority: true
    )

    /// Minimal configuration - priority only
    /// Use for simple use cases or progressive disclosure
    static let minimal = MetadataToolbarConfig(
        showDate: false,
        showRecurrence: false,
        showAlert: false,
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
            showAlert: features.contains(.alert),
            showPriority: features.contains(.priority)
        )
    }

    /// Available metadata features
    enum Feature: String, CaseIterable {
        case date = "Due Date"
        case recurrence = "Recurrence"
        case alert = "Alert"
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
///     alert: $alert,
///     priority: $priority,
///     accentColor: .daisyTask,
///     onDateTap: { showingDatePicker = true },
///     onRecurrenceTap: { showingRecurrencePicker = true },
///     onAlertTap: { showingAlertPicker = true },
///     onPriorityTap: { showingPriorityPicker = true }
/// )
/// ```
struct MetadataToolbar: View {
    @Environment(AppearanceManager.self) private var appearanceManager

    let config: MetadataToolbarConfig
    let dueDate: Date?
    let recurrenceRule: RecurrenceRule?
    let alert: AlertOption?
    let priority: Priority?
    let accentColor: Color
    let onDateTap: () -> Void
    let onRecurrenceTap: () -> Void
    let onAlertTap: () -> Void
    let onPriorityTap: () -> Void

    init(
        config: MetadataToolbarConfig = .full,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        alert: AlertOption? = nil,
        priority: Priority? = nil,
        accentColor: Color = .daisyTask,
        onDateTap: @escaping () -> Void = {},
        onRecurrenceTap: @escaping () -> Void = {},
        onAlertTap: @escaping () -> Void = {},
        onPriorityTap: @escaping () -> Void = {}
    ) {
        self.config = config
        self.dueDate = dueDate
        self.recurrenceRule = recurrenceRule
        self.alert = alert
        self.priority = priority
        self.accentColor = accentColor
        self.onDateTap = onDateTap
        self.onRecurrenceTap = onRecurrenceTap
        self.onAlertTap = onAlertTap
        self.onPriorityTap = onPriorityTap
    }

    private var hasDueDate: Bool {
        dueDate != nil
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

                // Alert Icon with label
                if config.showAlert {
                    VStack(spacing: 2) {
                        CompactIconButton(
                            icon: alert != nil ? "bell.fill" : "bell",
                            isActive: alert != nil,
                            accentColor: accentColor,
                            action: onAlertTap
                        )
                        .accessibilityLabel(alert != nil ? "Alert: \(alert!.shortLabel)" : "Set alert")

                        if let alert = alert {
                            Text(alert.shortLabel)
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
            onAlertTap: { print("Alert tapped") },
            onPriorityTap: { print("Priority tapped") }
        )
        .padding()

        // Task - All metadata set
        MetadataToolbar(
            config: .task,
            dueDate: Date(),
            recurrenceRule: RecurrenceRule(frequency: .daily, interval: 1),
            alert: .fiveMinutesBefore,
            priority: .high,
            accentColor: .daisyTask,
            onDateTap: { print("Date tapped") },
            onRecurrenceTap: { print("Recurrence tapped") },
            onAlertTap: { print("Alert tapped") },
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

        // Habit - No due date (by design)
        MetadataToolbar(
            config: .habit,
            recurrenceRule: RecurrenceRule(frequency: .weekly, interval: 1),
            alert: .oneDayBefore,
            priority: .medium,
            accentColor: .daisyHabit,
            onRecurrenceTap: { print("Recurrence tapped") },
            onAlertTap: { print("Alert tapped") },
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

        // Custom - Alert only
        Text(".custom([.alert])")
            .font(.caption)
        MetadataToolbar(
            config: .custom([.alert]),
            alert: .thirtyMinutesBefore,
            accentColor: .cyan,
            onAlertTap: { print("Alert tapped") }
        )
        .padding(.horizontal)
    }
    .padding()
    .background(Color.daisyBackground)
}
