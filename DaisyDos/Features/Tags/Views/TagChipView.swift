//
//  TagChipView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI

struct TagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let isRemovable: Bool
    let onTap: (() -> Void)?
    let onRemove: (() -> Void)?

    init(
        tag: Tag,
        isSelected: Bool = false,
        isRemovable: Bool = false,
        onTap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.tag = tag
        self.isSelected = isSelected
        self.isRemovable = isRemovable
        self.onTap = onTap
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            // Tag icon
            Image(systemName: tag.sfSymbolName)
                .font(.caption)
                .foregroundColor(isSelected ? .white : tag.color)

            // Tag name
            Text(tag.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(isSelected ? .white : .daisyText)

            // Remove button for removable chips
            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .daisyTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(tag.name) tag")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: 200) // Prevent tags from being too wide
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(chipBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(chipBorderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tag.name) tag")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    private var chipBackgroundColor: Color {
        if isSelected {
            return tag.color
        } else {
            return .daisySurface
        }
    }

    private var chipBorderColor: Color {
        if isSelected {
            return tag.color.opacity(0.3)
        } else {
            return Colors.Semantic.separator
        }
    }
}

// MARK: - Icon-Only Tag Chip

struct IconOnlyTagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: (() -> Void)?

    @State private var isPressed = false
    @State private var showTagSheet = false

    init(
        tag: Tag,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.tag = tag
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        Image(systemName: tag.sfSymbolName)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(chipBackgroundColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(chipBorderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .opacity(isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(minimumDuration: 0.5,
                               perform: {
                                   // Haptic feedback for discoverability
                                   let impact = UIImpactFeedbackGenerator(style: .light)
                                   impact.impactOccurred()

                                   showTagSheet = true
                               },
                               onPressingChanged: { pressing in
                                   isPressed = pressing
                               })
        .sheet(isPresented: $showTagSheet) {
            TagInfoSheet(tag: tag)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tag: \(tag.name)")
        .accessibilityHint("Long press to see tag details")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    private var chipBackgroundColor: Color {
        if isSelected {
            return tag.color.opacity(0.9)
        } else {
            return tag.color
        }
    }

    private var chipBorderColor: Color {
        if isSelected {
            return .white.opacity(0.3)
        } else {
            return tag.color.opacity(0.3)
        }
    }
}

// MARK: - Tag Info Sheet

struct TagInfoSheet: View {
    let tag: Tag
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Tag Preview
                VStack(spacing: 12) {
                    TagChipView(tag: tag, isSelected: true)
                        .scaleEffect(1.5)

                    Text(tag.name)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(.top)

                // Tag Description
                if !tag.descriptionText.isEmpty {
                    ScrollView {
                        Text(tag.tagDescriptionAttributed)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 150)
                }

                // Tag Statistics
                HStack {
                    Text("Total Items")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tag.totalItemCount)")
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .navigationTitle("Tag Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

#Preview("Regular Chip") {
    let tag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")

    return VStack(spacing: 16) {
        TagChipView(tag: tag)
        TagChipView(tag: tag, isSelected: true)
        TagChipView(tag: tag, isRemovable: true, onRemove: {})
        TagChipView(tag: tag, isSelected: true, isRemovable: true, onRemove: {})
    }
    .padding()
}

#Preview("Icon-Only Chip") {
    let workTag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
    let personalTag = Tag(name: "Personal Development", sfSymbolName: "graduationcap", colorName: "green")
    let fitnessTag = Tag(name: "Fitness & Health", sfSymbolName: "heart", colorName: "red")

    return VStack(spacing: 16) {
        Text("Icon-Only Tags (Long press to see name)")
            .font(.headline)

        HStack(spacing: 6) {
            IconOnlyTagChipView(tag: workTag) {}
            IconOnlyTagChipView(tag: personalTag, isSelected: true) {}
            IconOnlyTagChipView(tag: fitnessTag) {}
        }

        Text("Long press any tag to see tooltip")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Tag Info Sheet") {
    let tag = Tag(name: "Work Projects", sfSymbolName: "briefcase", colorName: "blue")

    return TagInfoSheet(tag: tag)
}