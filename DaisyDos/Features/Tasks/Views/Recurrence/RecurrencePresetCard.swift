//
//  RecurrencePresetCard.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct RecurrencePresetCard: View {
    let preset: RecurrenceRulePickerView.PresetType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundColor(iconForegroundColor)
                }

                // Title
                Text(preset.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                // Description
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(descriptionColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.rawValue), \(preset.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Tap to select this recurrence pattern")
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        if isSelected {
            return Colors.Secondary.blue.opacity(0.1)
        } else {
            return Color.daisySurface
        }
    }

    private var borderColor: Color {
        Colors.Secondary.blue
    }

    private var iconBackgroundColor: Color {
        if isSelected {
            return Colors.Secondary.blue.opacity(0.2)
        } else {
            return Colors.Secondary.blue.opacity(0.1)
        }
    }

    private var iconForegroundColor: Color {
        if isSelected {
            return Colors.Secondary.blue
        } else {
            return Colors.Secondary.blue.opacity(0.8)
        }
    }

    private var titleColor: Color {
        isSelected ? .daisyText : .daisyText
    }

    private var descriptionColor: Color {
        isSelected ? .daisyTextSecondary : .daisyTextSecondary
    }
}

#Preview {
    VStack(spacing: 16) {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            RecurrencePresetCard(
                preset: .daily,
                isSelected: false,
                onTap: {}
            )

            RecurrencePresetCard(
                preset: .weekdays,
                isSelected: true,
                onTap: {}
            )

            RecurrencePresetCard(
                preset: .weekly,
                isSelected: false,
                onTap: {}
            )

            RecurrencePresetCard(
                preset: .monthly,
                isSelected: false,
                onTap: {}
            )
        }
        .padding()

        Spacer()
    }
    .background(Color.daisyBackground)
}