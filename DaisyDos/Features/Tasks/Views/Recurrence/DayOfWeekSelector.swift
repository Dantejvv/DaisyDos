//
//  DayOfWeekSelector.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>

    private let weekdays = [
        (1, "S"), // Sunday
        (2, "M"), // Monday
        (3, "T"), // Tuesday
        (4, "W"), // Wednesday
        (5, "T"), // Thursday
        (6, "F"), // Friday
        (7, "S")  // Saturday
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Day selector buttons
            HStack(spacing: 8) {
                ForEach(weekdays, id: \.0) { day, letter in
                    DayButton(
                        day: day,
                        letter: letter,
                        isSelected: selectedDays.contains(day),
                        onTap: {
                            toggleDay(day)
                        }
                    )
                }
            }

            // Quick preset buttons
            HStack(spacing: 12) {
                PresetButton(
                    title: "Weekdays",
                    isActive: selectedDays == Set([2, 3, 4, 5, 6]),
                    onTap: {
                        selectedDays = Set([2, 3, 4, 5, 6])
                    }
                )

                PresetButton(
                    title: "Weekends",
                    isActive: selectedDays == Set([1, 7]),
                    onTap: {
                        selectedDays = Set([1, 7])
                    }
                )

                PresetButton(
                    title: "All Days",
                    isActive: selectedDays == Set(1...7),
                    onTap: {
                        selectedDays = Set(1...7)
                    }
                )

                Spacer()

                Button(action: {
                    selectedDays.removeAll()
                }) {
                    Text("Clear")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
                .disabled(selectedDays.isEmpty)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Methods

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

// MARK: - Day Button

private struct DayButton: View {
    let day: Int
    let letter: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter)
                .font(.subheadline.weight(.medium))
                .foregroundColor(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundColor, in: Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel("\(dayName), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Tap to toggle selection")
    }

    private var backgroundColor: Color {
        isSelected ? Colors.Secondary.blue : Color.clear
    }

    private var textColor: Color {
        isSelected ? .white : .daisyText
    }

    private var borderColor: Color {
        isSelected ? Colors.Secondary.blue : Color.daisyTextSecondary.opacity(0.3)
    }

    private var dayName: String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Unknown"
        }
    }
}

// MARK: - Preset Button

private struct PresetButton: View {
    let title: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(backgroundColor, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .accessibilityLabel("\(title), \(isActive ? "active" : "inactive")")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var backgroundColor: Color {
        isActive ? Colors.Secondary.blue.opacity(0.1) : Color.clear
    }

    private var textColor: Color {
        isActive ? Colors.Secondary.blue : .daisyTextSecondary
    }

    private var borderColor: Color {
        isActive ? Colors.Secondary.blue.opacity(0.5) : Color.daisyTextSecondary.opacity(0.3)
    }
}

#Preview {
    VStack(spacing: 24) {
        DayOfWeekSelector(selectedDays: .constant(Set([2, 3, 4, 5, 6])))

        DayOfWeekSelector(selectedDays: .constant(Set([1, 7])))

        DayOfWeekSelector(selectedDays: .constant(Set()))
    }
    .padding()
    .background(Color.daisyBackground)
}