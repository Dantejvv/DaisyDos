//
//  AccentColorPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Modern iOS-style sheet for selecting accent colors
/// Features: preset colors, recent colors, custom color picker, live preview
struct AccentColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var selectedColor: AppearanceManager.AccentColorOption
    @State private var customColor: Color
    @State private var isUsingCustomColor: Bool

    // Preset color options (excluding .none for accent colors)
    private let presetColors: [AppearanceManager.AccentColorOption] = [
        .blue, .purple, .teal, .green,
        .indigo, .cyan, .mint, .pink,
        .red, .orange, .yellow, .brown
    ]

    init() {
        // Initialize with current accent color
        let manager = AppearanceManager()
        _selectedColor = State(initialValue: manager.accentColor)

        // Initialize custom color state
        if let customColor = manager.customAccentColor {
            _customColor = State(initialValue: customColor)
            _isUsingCustomColor = State(initialValue: true)
        } else {
            _customColor = State(initialValue: manager.accentColor.color)
            _isUsingCustomColor = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Live Preview
                    previewSection

                    // MARK: - Recent Colors
                    if !recentColors.isEmpty {
                        recentColorsSection
                    }

                    // MARK: - Preset Colors
                    presetColorsSection

                    // MARK: - Custom Color
                    customColorSection
                }
                .padding()
            }
            .background(Color.daisyBackground)
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if isUsingCustomColor {
                            // Save custom color
                            appearanceManager.customAccentColor = customColor
                        } else {
                            // Save preset color (this will auto-clear custom color via didSet)
                            appearanceManager.accentColor = selectedColor
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Sample button
                Button(action: {}) {
                    Label("Sample Button", systemImage: "star.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUsingCustomColor ? customColor : selectedColor.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Sample toolbar icon
                HStack {
                    Text("Toolbar Icon:")
                        .foregroundColor(.daisyTextSecondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(isUsingCustomColor ? customColor : selectedColor.color)
                        .font(.title2)
                    Spacer()
                }
            }
            .padding()
            .background(Color.daisySurface)
            .cornerRadius(12)
        }
    }

    // MARK: - Recent Colors Section

    @ViewBuilder
    private var recentColorsSection: some View {
        VStack(spacing: 12) {
            Text("Recent")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recentColors, id: \.rawValue) { color in
                        ColorSwatchView(
                            colorOption: color,
                            isSelected: !isUsingCustomColor && selectedColor == color,
                            showLabel: false,
                            size: .medium
                        ) {
                            selectedColor = color
                            isUsingCustomColor = false
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Preset Colors Section

    @ViewBuilder
    private var presetColorsSection: some View {
        VStack(spacing: 12) {
            Text("Colors")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 20
            ) {
                ForEach(presetColors, id: \.rawValue) { color in
                    ColorSwatchView(
                        colorOption: color,
                        isSelected: !isUsingCustomColor && selectedColor == color,
                        showLabel: true,
                        size: .medium
                    ) {
                        selectedColor = color
                        isUsingCustomColor = false
                    }
                }
            }
        }
    }

    // MARK: - Custom Color Section

    @ViewBuilder
    private var customColorSection: some View {
        VStack(spacing: 12) {
            Text("Custom")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Show custom color swatch if active
                if isUsingCustomColor {
                    HStack(spacing: 16) {
                        // Custom color swatch
                        Button(action: {
                            // Tapping the swatch deselects it (reverts to last preset)
                            isUsingCustomColor = false
                        }) {
                            ZStack {
                                Circle()
                                    .fill(customColor)
                                    .frame(width: 44, height: 44)

                                // Selection indicator
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.body.weight(.bold))
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Color")
                                .font(.body)
                                .foregroundColor(.daisyText)
                            Text("Tap to deselect")
                                .font(.caption2)
                                .foregroundColor(.daisyTextSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.daisySurface)
                    .cornerRadius(12)
                }

                // ColorPicker button (always visible)
                ColorPicker(
                    selection: $customColor,
                    supportsOpacity: false,
                    label: {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(isUsingCustomColor ? customColor : selectedColor.color)
                            Text(isUsingCustomColor ? "Edit Custom Color" : "Choose Custom Color")
                                .foregroundColor(.daisyText)
                            Spacer()
                        }
                    }
                )
                .onChange(of: customColor) { oldValue, newValue in
                    // When user selects a color, mark as using custom
                    isUsingCustomColor = true
                }
                .padding()
                .background(Color.daisySurface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Computed Properties

    private var recentColors: [AppearanceManager.AccentColorOption] {
        appearanceManager.recentColorsManager.getRecentColorOptions(for: .accent)
            .filter { presetColors.contains($0) }
    }

}

#Preview {
    AccentColorPickerSheet()
        .environment(AppearanceManager())
}
