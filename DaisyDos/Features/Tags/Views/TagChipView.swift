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

#Preview("Draggable Chip") {
    let tag = Tag(name: "Personal", sfSymbolName: "house", colorName: "green")

    return DraggableTagChipView(tag: tag, isSelected: false) {
        print("Tag tapped")
    }
    .padding()
}