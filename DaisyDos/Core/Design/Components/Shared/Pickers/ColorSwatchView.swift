//
//  ColorSwatchView.swift
//  DaisyDos
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Reusable color swatch component with 44pt minimum tap target
/// Displays a circular color preview with optional checkmark for selection
struct ColorSwatchView: View {
    let colorOption: AppearanceManager.AccentColorOption
    let isSelected: Bool
    let showLabel: Bool
    let size: SwatchSize
    let onTap: () -> Void

    enum SwatchSize {
        case small  // 32pt - for compact displays
        case medium // 44pt - standard (HIG minimum)
        case large  // 56pt - for emphasis

        var diameter: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var checkmarkSize: Font {
            switch self {
            case .small: return .caption.weight(.bold)
            case .medium: return .body.weight(.bold)
            case .large: return .title3.weight(.bold)
            }
        }
    }

    init(
        colorOption: AppearanceManager.AccentColorOption,
        isSelected: Bool,
        showLabel: Bool = false,
        size: SwatchSize = .medium,
        onTap: @escaping () -> Void
    ) {
        self.colorOption = colorOption
        self.isSelected = isSelected
        self.showLabel = showLabel
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Color circle
                ZStack {
                    if colorOption == .none {
                        // Special visual for "None" option
                        Circle()
                            .stroke(Color.daisyTextSecondary, lineWidth: 2)
                            .frame(width: size.diameter, height: size.diameter)

                        Path { path in
                            let offset = size.diameter * 0.25
                            let length = size.diameter * 0.5
                            path.move(to: CGPoint(x: offset, y: offset))
                            path.addLine(to: CGPoint(x: offset + length, y: offset + length))
                        }
                        .stroke(Color.daisyTextSecondary, lineWidth: 2)
                        .frame(width: size.diameter, height: size.diameter)
                    } else {
                        Circle()
                            .fill(colorOption.color)
                            .frame(width: size.diameter, height: size.diameter)
                    }

                    // Selection indicator
                    if isSelected {
                        if colorOption == .none {
                            // For "None", use a border
                            Circle()
                                .stroke(Color.daisyText, lineWidth: 3)
                                .frame(width: size.diameter + 4, height: size.diameter + 4)
                        } else {
                            // For colors, use checkmark
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(size.checkmarkSize)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                    }
                }

                // Optional label
                if showLabel {
                    Text(colorOption.displayName)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .daisyText : .daisyTextSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: size.diameter + 8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(colorOption.displayName) color")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select")
    }
}

#Preview("All Sizes") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ColorSwatchView(
                colorOption: .blue,
                isSelected: false,
                showLabel: true,
                size: .small
            ) {}

            ColorSwatchView(
                colorOption: .blue,
                isSelected: true,
                showLabel: true,
                size: .small
            ) {}
        }

        HStack(spacing: 16) {
            ColorSwatchView(
                colorOption: .purple,
                isSelected: false,
                showLabel: true,
                size: .medium
            ) {}

            ColorSwatchView(
                colorOption: .purple,
                isSelected: true,
                showLabel: true,
                size: .medium
            ) {}
        }

        HStack(spacing: 16) {
            ColorSwatchView(
                colorOption: .teal,
                isSelected: false,
                showLabel: true,
                size: .large
            ) {}

            ColorSwatchView(
                colorOption: .teal,
                isSelected: true,
                showLabel: true,
                size: .large
            ) {}
        }

        HStack(spacing: 16) {
            ColorSwatchView(
                colorOption: .none,
                isSelected: false,
                showLabel: true,
                size: .medium
            ) {}

            ColorSwatchView(
                colorOption: .none,
                isSelected: true,
                showLabel: true,
                size: .medium
            ) {}
        }
    }
    .padding()
}
