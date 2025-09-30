//
//  HabitCompletionUndoToast.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct HabitCompletionUndoToast: View {
    // MARK: - Properties

    let habit: Habit
    let onUndo: () -> Void
    @Binding var isVisible: Bool

    @State private var timeRemaining: Double = 5.0
    @State private var timer: Timer?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.daisySuccess)

            // Message
            VStack(alignment: .leading, spacing: 2) {
                Text("Habit Completed!")
                    .font(.headline)
                    .foregroundColor(.daisyText)

                Text(habit.title)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.daisyTextSecondary.opacity(0.3), lineWidth: 2)

                Circle()
                    .trim(from: 0, to: timeRemaining / 5.0)
                    .stroke(Color.daisySuccess, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timeRemaining)

                Text("\(Int(timeRemaining) + 1)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.daisyTextSecondary)
            }
            .frame(width: 24, height: 24)

            // Undo Button
            Button(action: {
                performUndo()
            }) {
                Text("Undo")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyHabit)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Color.daisyHabit.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.daisySurface,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .offset(y: isVisible ? 0 : 100)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                hideToast()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func performUndo() {
        stopTimer()
        onUndo()
        hideToast()
    }

    private func hideToast() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
    }
}

// MARK: - Toast Manager

@Observable
class HabitCompletionToastManager {
    private(set) var activeToast: ToastItem?

    struct ToastItem: Identifiable {
        let id = UUID()
        let habit: Habit
        let onUndo: () -> Void
    }

    func showCompletionToast(for habit: Habit, onUndo: @escaping () -> Void) {
        activeToast = ToastItem(habit: habit, onUndo: onUndo)

        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [self] in
            if self.activeToast?.id == activeToast?.id {
                self.hideToast()
            }
        }
    }

    func hideToast() {
        activeToast = nil
    }
}

// MARK: - Toast Container View

struct HabitCompletionToastContainer<Content: View>: View {
    @State private var toastManager = HabitCompletionToastManager()
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .environment(toastManager)

            if let toast = toastManager.activeToast {
                VStack {
                    Spacer()

                    HabitCompletionUndoToast(
                        habit: toast.habit,
                        onUndo: toast.onUndo,
                        isVisible: .constant(true)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Account for tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: toastManager.activeToast?.id)
    }
}

// MARK: - Preview

#Preview("Undo Toast") {
    struct PreviewWrapper: View {
        var body: some View {
            let container = try! ModelContainer(
                for: Habit.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let habit = Habit(
                title: "Morning Exercise",
                habitDescription: "30 minutes of cardio",
            )
            context.insert(habit)

            return VStack {
                Spacer()

                HabitCompletionUndoToast(
                    habit: habit,
                    onUndo: {
                        print("Undo tapped")
                    },
                    isVisible: .constant(true)
                )
                .padding()

                Spacer()
            }
            .background(Color.daisyBackground)
            .modelContainer(container)
        }
    }

    return PreviewWrapper()
}

#Preview("Toast Container") {
    HabitCompletionToastContainer {
        VStack {
            Text("Main Content")
                .font(.title)

            Button("Test Toast") {
                // This would trigger a toast in real usage
            }
            .padding()
        }
    }
}