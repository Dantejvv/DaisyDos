//
//  AppearanceSettingsView.swift
//  DaisyDos
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var showingAccentColorPicker = false
    @State private var showingPriorityColorPicker = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Theme Section
                Section {
                    ForEach(AppearanceManager.ColorSchemePreference.allCases) { scheme in
                        Button(action: {
                            appearanceManager.preferredColorScheme = scheme
                        }) {
                            HStack {
                                Label(scheme.displayName, systemImage: scheme.icon)
                                    .foregroundColor(.daisyText)
                                Spacer()
                                if appearanceManager.preferredColorScheme == scheme {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                }
                            }
                        }
                        .accessibilityLabel("\(scheme.displayName) theme")
                        .accessibilityAddTraits(
                            appearanceManager.preferredColorScheme == scheme ? [.isSelected] : []
                        )
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose how DaisyDos appears. System automatically switches between light and dark based on your device settings.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Accent Color Section
                Section {
                    Button(action: {
                        showingAccentColorPicker = true
                    }) {
                        HStack {
                            Label("Accent Color", systemImage: "paintpalette.fill")
                                .foregroundColor(.daisyText)

                            Spacer()

                            // Current color preview
                            Circle()
                                .fill(appearanceManager.accentColor.color)
                                .frame(width: 28, height: 28)

                            Image(systemName: "chevron.right")
                                .foregroundColor(.daisyTextSecondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text("Choose your preferred accent color for interactive elements.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Priority Colors Section
                Section {
                    Button(action: {
                        showingPriorityColorPicker = true
                    }) {
                        HStack {
                            Label("Priority Colors", systemImage: "square.fill.on.square.fill")
                                .foregroundColor(.daisyText)

                            Spacer()

                            if appearanceManager.showPriorityBackgrounds {
                                // Show preview of priority colors
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(appearanceManager.highPriorityColor.color)
                                        .frame(width: 12, height: 12)
                                    Circle()
                                        .fill(appearanceManager.mediumPriorityColor.color)
                                        .frame(width: 12, height: 12)
                                    Circle()
                                        .fill(appearanceManager.lowPriorityColor.color)
                                        .frame(width: 12, height: 12)
                                }
                            } else {
                                Text("Off")
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            Image(systemName: "chevron.right")
                                .foregroundColor(.daisyTextSecondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text(appearanceManager.showPriorityBackgrounds
                        ? "Priority colors are enabled. Tap to customize."
                        : "Enable priority backgrounds to show colored indicators.")
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAccentColorPicker) {
                AccentColorPickerSheet()
                    .environment(appearanceManager)
            }
            .sheet(isPresented: $showingPriorityColorPicker) {
                PriorityColorPickerSheet()
                    .environment(appearanceManager)
            }
        }
        .applyAppearance(appearanceManager)
    }
}

#Preview {
    AppearanceSettingsView()
        .environment(AppearanceManager())
}
