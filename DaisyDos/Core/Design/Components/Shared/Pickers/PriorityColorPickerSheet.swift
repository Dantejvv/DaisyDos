//
//  PriorityColorPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Modern iOS-style sheet for selecting priority colors
/// Features: semantic color groupings, toggle for backgrounds, recent colors
struct PriorityColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var showPriorityBackgrounds: Bool
    @State private var highPriorityColor: AppearanceManager.AccentColorOption
    @State private var mediumPriorityColor: AppearanceManager.AccentColorOption
    @State private var lowPriorityColor: AppearanceManager.AccentColorOption

    // Semantic color groups
    private let urgentColors: [AppearanceManager.AccentColorOption] = [.red, .pink, .orange]
    private let cautionColors: [AppearanceManager.AccentColorOption] = [.orange, .yellow, .brown]
    private let calmColors: [AppearanceManager.AccentColorOption] = [.blue, .teal, .cyan, .green, .mint]
    private let neutralColors: [AppearanceManager.AccentColorOption] = [.none, .indigo, .purple]

    init() {
        let manager = AppearanceManager()
        _showPriorityBackgrounds = State(initialValue: manager.showPriorityBackgrounds)
        _highPriorityColor = State(initialValue: manager.highPriorityColor)
        _mediumPriorityColor = State(initialValue: manager.mediumPriorityColor)
        _lowPriorityColor = State(initialValue: manager.lowPriorityColor)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Toggle Section
                Section {
                    Toggle(isOn: $showPriorityBackgrounds) {
                        Label("Show Priority Backgrounds", systemImage: "square.fill.on.square.fill")
                    }
                    .tint(appearanceManager.currentAccentColor)
                } footer: {
                    Text(showPriorityBackgrounds
                        ? "Priority colors will be shown as subtle backgrounds on tasks and habits."
                        : "Enable to show colored backgrounds based on priority level.")
                }

                // MARK: - Priority Color Sections
                if showPriorityBackgrounds {
                    highPrioritySection
                    mediumPrioritySection
                    lowPrioritySection
                }
            }
            .navigationTitle("Priority Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - High Priority Section

    @ViewBuilder
    private var highPrioritySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Preview
                previewRow(
                    title: "High Priority Task",
                    icon: "exclamationmark.triangle.fill",
                    color: highPriorityColor
                )

                // Recent colors
                if !recentColors(for: .highPriority).isEmpty {
                    colorRow(
                        label: "Recent",
                        colors: recentColors(for: .highPriority),
                        selection: $highPriorityColor
                    )
                }

                // Urgent colors
                colorRow(
                    label: "Urgent",
                    colors: urgentColors,
                    selection: $highPriorityColor
                )

                // All colors
                colorRow(
                    label: "Other",
                    colors: allOtherColors(excluding: urgentColors),
                    selection: $highPriorityColor
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("High Priority")
        } footer: {
            Text("Used for urgent and important items.")
        }
    }

    // MARK: - Medium Priority Section

    @ViewBuilder
    private var mediumPrioritySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Preview
                previewRow(
                    title: "Medium Priority Task",
                    icon: "triangle.fill",
                    color: mediumPriorityColor
                )

                // Recent colors
                if !recentColors(for: .mediumPriority).isEmpty {
                    colorRow(
                        label: "Recent",
                        colors: recentColors(for: .mediumPriority),
                        selection: $mediumPriorityColor
                    )
                }

                // Caution colors
                colorRow(
                    label: "Caution",
                    colors: cautionColors,
                    selection: $mediumPriorityColor
                )

                // All colors
                colorRow(
                    label: "Other",
                    colors: allOtherColors(excluding: cautionColors),
                    selection: $mediumPriorityColor
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("Medium Priority")
        } footer: {
            Text("Used for moderately important items.")
        }
    }

    // MARK: - Low Priority Section

    @ViewBuilder
    private var lowPrioritySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Preview
                previewRow(
                    title: "Low Priority Task",
                    icon: "triangle",
                    color: lowPriorityColor
                )

                // Recent colors
                if !recentColors(for: .lowPriority).isEmpty {
                    colorRow(
                        label: "Recent",
                        colors: recentColors(for: .lowPriority),
                        selection: $lowPriorityColor
                    )
                }

                // Calm colors
                colorRow(
                    label: "Calm",
                    colors: calmColors,
                    selection: $lowPriorityColor
                )

                // All colors
                colorRow(
                    label: "Other",
                    colors: allOtherColors(excluding: calmColors),
                    selection: $lowPriorityColor
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("Low Priority")
        } footer: {
            Text("Used for less urgent items.")
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func previewRow(
        title: String,
        icon: String,
        color: AppearanceManager.AccentColorOption
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color == .none ? .daisyTextSecondary : color.color)
                .font(.title3)

            Text(title)
                .foregroundColor(.daisyText)

            Spacer()
        }
        .padding()
        .background(
            color == .none
                ? Color.clear
                : color.color.opacity(0.1)
        )
        .cornerRadius(8)
    }

    @ViewBuilder
    private func colorRow(
        label: String,
        colors: [AppearanceManager.AccentColorOption],
        selection: Binding<AppearanceManager.AccentColorOption>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.rawValue) { color in
                        ColorSwatchView(
                            colorOption: color,
                            isSelected: selection.wrappedValue == color,
                            showLabel: false,
                            size: .small
                        ) {
                            selection.wrappedValue = color
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func recentColors(for category: RecentColorsManager.ColorCategory) -> [AppearanceManager.AccentColorOption] {
        appearanceManager.recentColorsManager.getRecentColorOptions(for: category)
    }

    private func allOtherColors(excluding: [AppearanceManager.AccentColorOption]) -> [AppearanceManager.AccentColorOption] {
        AppearanceManager.AccentColorOption.allCases.filter { color in
            !excluding.contains(color)
        }
    }

    private func saveChanges() {
        appearanceManager.showPriorityBackgrounds = showPriorityBackgrounds
        appearanceManager.highPriorityColor = highPriorityColor
        appearanceManager.mediumPriorityColor = mediumPriorityColor
        appearanceManager.lowPriorityColor = lowPriorityColor
    }
}

#Preview {
    PriorityColorPickerSheet()
        .environment(AppearanceManager())
}
