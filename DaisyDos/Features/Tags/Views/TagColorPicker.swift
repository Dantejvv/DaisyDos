//
//  TagColorPicker.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI

struct TagColorPicker: View {
    @Binding var selectedColor: String
    let availableColors: [String] = Tag.availableColors()

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(availableColors, id: \.self) { colorName in
                ColorOption(
                    colorName: colorName,
                    isSelected: selectedColor == colorName
                ) {
                    selectedColor = colorName
                }
            }
        }
        .padding()
    }
}

private struct ColorOption: View {
    let colorName: String
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        switch colorName.lowercased() {
        case "red": return Color(.systemRed)
        case "orange": return Color(.systemOrange)
        case "yellow": return Color(.systemYellow)
        case "green": return Color(.systemGreen)
        case "blue": return Color(.systemBlue)
        case "purple": return Color(.systemPurple)
        case "pink": return Color(.systemPink)
        case "brown": return Color(.systemBrown)
        case "gray": return Color(.systemGray)
        default: return Color(.systemBlue)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )

                Text(colorName.capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(colorName.capitalized) color")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selectedColor = "blue"

    TagColorPicker(selectedColor: $selectedColor)
        .padding()
}