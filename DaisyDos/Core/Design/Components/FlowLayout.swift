//
//  FlowLayout.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//

import SwiftUI

/// A layout that arranges views in a flowing manner, wrapping to new rows as needed
/// Perfect for tag chips, category badges, or any collection that should wrap naturally
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(
        _ data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: self.calculateHeight(in: UIScreen.main.bounds.width - 32)) // Account for padding
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .alignmentGuide(.leading, computeValue: { dimension in
                        if (abs(width - dimension.width) > geometry.size.width) {
                            width = 0
                            height -= (dimension.height + spacing)
                        }
                        let result = width
                        if index == data.count - 1 {
                            width = 0
                        } else {
                            width -= (dimension.width + spacing)
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { dimension in
                        let result = height
                        if index == data.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }
    }

    private func calculateHeight(in width: CGFloat) -> CGFloat {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0

        // Estimate heights based on typical tag chip dimensions
        let estimatedItemHeight: CGFloat = 34 // Typical tag chip height

        for _ in data {
            let estimatedWidth: CGFloat = 150 // Estimate based on maxWidth constraint

            if currentX + estimatedWidth > width {
                // Move to next row
                currentY += maxRowHeight + spacing
                currentX = 0
                maxRowHeight = 0
            }

            currentX += estimatedWidth + spacing
            maxRowHeight = max(maxRowHeight, estimatedItemHeight)
        }

        // Add the last row height
        currentY += maxRowHeight

        return max(currentY, estimatedItemHeight) // Ensure minimum height
    }
}

// MARK: - Preview

#Preview("Flow Layout - Few Items") {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let text: String
    }

    let items = [
        PreviewItem(text: "Short"),
        PreviewItem(text: "Medium Tag"),
        PreviewItem(text: "Long Tag Name")
    ]

    return VStack {
        FlowLayout(items, spacing: 8) { item in
            Text(item.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(16)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Flow Layout - Many Items") {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let text: String
    }

    let items = [
        PreviewItem(text: "Work"),
        PreviewItem(text: "Personal Development"),
        PreviewItem(text: "Health"),
        PreviewItem(text: "Finance"),
        PreviewItem(text: "Family"),
        PreviewItem(text: "Hobbies"),
        PreviewItem(text: "Learning"),
        PreviewItem(text: "Social")
    ]

    return VStack {
        FlowLayout(items, spacing: 8) { item in
            Text(item.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(16)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Flow Layout - Very Long Names") {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let text: String
    }

    let items = [
        PreviewItem(text: "Maxtitieloooooooooooo"),
        PreviewItem(text: "Maxtitleoneooooooooooo"),
        PreviewItem(text: "maxtitlezoooooooooooo")
    ]

    return VStack {
        FlowLayout(items, spacing: 8) { item in
            Text(item.text)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(16)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
