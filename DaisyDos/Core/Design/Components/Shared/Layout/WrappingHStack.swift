//
//  WrappingHStack.swift
//  DaisyDos
//
//  Standardized wrapping horizontal stack layout component
//  Automatically wraps content to multiple lines when needed
//

import SwiftUI

/// A horizontal stack that automatically wraps content to multiple lines
/// when the content width exceeds the available width.
///
/// Perfect for tag chips, button collections, and other dynamic width content.
///
/// Example:
/// ```swift
/// WrappingHStack(spacing: 8) {
///     ForEach(tags) { tag in
///         TagChipView(tag: tag)
///     }
/// }
/// ```
@available(iOS 16.0, *)
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var layout = FlexLayout(spacing: spacing, sizes: subviews.map { $0.sizeThatFits(.unspecified) })
        return layout.size(containerWidth: proposal.width ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var layout = FlexLayout(spacing: spacing, sizes: sizes)
        _ = layout.size(containerWidth: proposal.width ?? bounds.width)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + layout.frames[index].minX,
                                      y: bounds.minY + layout.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    private struct FlexLayout {
        let spacing: CGFloat
        let sizes: [CGSize]
        var frames: [CGRect] = []

        init(spacing: CGFloat, sizes: [CGSize]) {
            self.spacing = spacing
            self.sizes = sizes
            self.frames = []
        }

        mutating func size(containerWidth: CGFloat) -> CGSize {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            frames.removeAll()

            for size in sizes {
                if currentX + size.width > containerWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            return CGSize(width: containerWidth, height: currentY + lineHeight)
        }
    }
}
