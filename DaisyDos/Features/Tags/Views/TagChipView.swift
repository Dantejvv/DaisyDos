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

                // Tag Statistics
                VStack(spacing: 16) {
                    StatRow(title: "Total Items", value: "\(tag.totalItemCount)")
                    StatRow(title: "Tasks", value: "\(tag.tasks.count)")
                    StatRow(title: "Habits", value: "\(tag.habits.count)")
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

// MARK: - Draggable Tag Chip

struct DraggableTagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: (() -> Void)?

    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        TagChipView(
            tag: tag,
            isSelected: isSelected,
            onTap: onTap
        )
        .offset(dragOffset)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragOffset)
        // TODO: Add drag & drop support when Tag conforms to Transferable
        // .draggable(tag) {
        //     TagChipView(tag: tag, isSelected: true)
        //         .opacity(0.8)
        // }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    isDragging = false
                    dragOffset = .zero
                }
        )
    }
}

#Preview("Regular Chip") {
    let tag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")

    return VStack(spacing: 16) {
        TagChipView(tag: tag)
        TagChipView(tag: tag, isSelected: true)
        TagChipView(tag: tag, isRemovable: true, onRemove: {
            print("Remove tapped")
        })
        TagChipView(tag: tag, isSelected: true, isRemovable: true, onRemove: {
            print("Remove tapped")
        })
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
            IconOnlyTagChipView(tag: workTag) {
                print("Work tag tapped")
            }
            IconOnlyTagChipView(tag: personalTag, isSelected: true) {
                print("Personal tag tapped")
            }
            IconOnlyTagChipView(tag: fitnessTag) {
                print("Fitness tag tapped")
            }
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

#Preview("Draggable Chip") {
    let tag = Tag(name: "Personal", sfSymbolName: "house", colorName: "green")

    return DraggableTagChipView(tag: tag, isSelected: false) {
        print("Tag tapped")
    }
    .padding()
}