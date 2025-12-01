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
    @State private var showingCustomColorPicker = false
    @State private var customColor = Color.blue

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
                        appearanceManager.accentColor = selectedColor
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingCustomColorPicker) {
            customColorPickerView
        }
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
                        .background(selectedColor.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Sample toolbar icon
                HStack {
                    Text("Toolbar Icon:")
                        .foregroundColor(.daisyTextSecondary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(selectedColor.color)
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
                            isSelected: selectedColor == color,
                            showLabel: false,
                            size: .medium
                        ) {
                            selectedColor = color
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
                        isSelected: selectedColor == color,
                        showLabel: true,
                        size: .medium
                    ) {
                        selectedColor = color
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

            Button(action: {
                customColor = selectedColor.color
                showingCustomColorPicker = true
            }) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(selectedColor.color)
                    Text("Choose Custom Color")
                        .foregroundColor(.daisyText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.daisyTextSecondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.daisySurface)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Custom Color Picker View

    @ViewBuilder
    private var customColorPickerView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Select Color", selection: $customColor, supportsOpacity: false)
                    .padding()

                Text("Note: Custom colors are converted to the nearest preset color.")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomColorPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Choose") {
                        // Convert custom color to nearest preset
                        selectedColor = nearestPresetColor(to: customColor)
                        showingCustomColorPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Computed Properties

    private var recentColors: [AppearanceManager.AccentColorOption] {
        appearanceManager.recentColorsManager.getRecentColorOptions(for: .accent)
            .filter { presetColors.contains($0) }
    }

    // MARK: - Helper Methods

    /// Finds the nearest preset color to a custom color
    private func nearestPresetColor(to color: Color) -> AppearanceManager.AccentColorOption {
        // Simple heuristic: find closest by comparing hue
        // In a production app, you'd use proper color space conversion
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        // Map hue to closest color
        switch hue {
        case 0.0..<0.05: return .red
        case 0.05..<0.1: return .orange
        case 0.1..<0.2: return .yellow
        case 0.2..<0.4: return .green
        case 0.4..<0.5: return .mint
        case 0.5..<0.55: return .cyan
        case 0.55..<0.65: return .blue
        case 0.65..<0.75: return .indigo
        case 0.75..<0.85: return .purple
        case 0.85..<0.95: return .pink
        default: return .blue
        }
    }
}

#Preview {
    AccentColorPickerSheet()
        .environment(AppearanceManager())
}
