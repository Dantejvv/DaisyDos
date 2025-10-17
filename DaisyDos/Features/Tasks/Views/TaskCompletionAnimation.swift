//
//  TaskCompletionAnimation.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//

import SwiftUI

/// A view modifier that adds a celebratory completion animation to task rows
struct TaskCompletionAnimation: ViewModifier {
    let isAnimating: Bool
    let onAnimationComplete: () -> Void

    @State private var checkmarkScale: CGFloat = 1.0
    @State private var highlightOpacity: Double = 0.0
    @State private var rowOpacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .background(
                // Success highlight background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.daisySuccess.opacity(0.15))
                    .opacity(highlightOpacity)
            )
            .opacity(rowOpacity)
            .onChange(of: isAnimating) { _, animating in
                if animating {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        // Phase 1: Checkmark scale + highlight (0.3s)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            checkmarkScale = 1.3
            highlightOpacity = 1.0
        }

        // Phase 2: Settle checkmark (0.2s delay + 0.2s duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                checkmarkScale = 1.0
            }
        }

        // Phase 3: Fade out (0.3s delay + 0.4s duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                rowOpacity = 0.0
                highlightOpacity = 0.0
            }
        }

        // Phase 4: Completion callback (allow animation to finish)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            onAnimationComplete()
        }
    }
}

/// Extension to make the modifier easier to use
extension View {
    func taskCompletionAnimation(
        isAnimating: Bool,
        onAnimationComplete: @escaping () -> Void
    ) -> some View {
        self.modifier(
            TaskCompletionAnimation(
                isAnimating: isAnimating,
                onAnimationComplete: onAnimationComplete
            )
        )
    }
}
