//
//  CompletionUndoToast.swift
//  DaisyDos
//
//  Created by Claude Code on 10/28/25.
//  Generic undo toast for task/habit completion with 5-second countdown
//

import SwiftUI
import SwiftData

// MARK: - Toast Configuration

/// Configuration for completion toast appearance and behavior
struct CompletionToastConfig<Entity> {
    let completionMessage: String
    let buttonColor: Color
    let titleExtractor: (Entity) -> String
}

// MARK: - Configuration Factory Methods

extension CompletionToastConfig where Entity == Task {
    static func task() -> CompletionToastConfig<Task> {
        CompletionToastConfig(
            completionMessage: "Task Completed!",
            buttonColor: .daisyTask,
            titleExtractor: { $0.title }
        )
    }
}

extension CompletionToastConfig where Entity == Habit {
    static func habit() -> CompletionToastConfig<Habit> {
        CompletionToastConfig(
            completionMessage: "Habit Completed!",
            buttonColor: .daisyHabit,
            titleExtractor: { $0.title }
        )
    }
}

// MARK: - Generic Toast View

struct CompletionUndoToast<Entity>: View {
    // MARK: - Properties

    let entity: Entity
    let config: CompletionToastConfig<Entity>
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
                Text(config.completionMessage)
                    .font(.headline)
                    .foregroundColor(.daisyText)

                Text(config.titleExtractor(entity))
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
                    .foregroundColor(config.buttonColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        config.buttonColor.opacity(0.1),
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

// MARK: - Generic Toast Manager

@Observable
class CompletionToastManager<Entity> {
    private(set) var activeToast: ToastItem?
    private var autoHideWorkItem: DispatchWorkItem?

    struct ToastItem: Identifiable {
        let id = UUID()
        let entity: Entity
        let onUndo: () -> Void
    }

    func showCompletionToast(for entity: Entity, onUndo: @escaping () -> Void) {
        // Cancel any existing auto-hide timer
        autoHideWorkItem?.cancel()

        activeToast = ToastItem(entity: entity, onUndo: onUndo)

        // Create new auto-hide timer
        autoHideWorkItem = DispatchWorkItem { [weak self] in
            self?.hideToast()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: autoHideWorkItem!)
    }

    func hideToast() {
        // Cancel the auto-hide timer
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil

        activeToast = nil
    }
}

// MARK: - Generic Toast Container View

struct CompletionToastContainer<Entity, Content: View>: View {
    @State private var toastManager: CompletionToastManager<Entity>
    private let config: CompletionToastConfig<Entity>
    private let content: () -> Content

    init(config: CompletionToastConfig<Entity>, @ViewBuilder content: @escaping () -> Content) {
        self.config = config
        self.content = content
        self._toastManager = State(initialValue: CompletionToastManager<Entity>())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .environment(toastManager)

            if let toast = toastManager.activeToast {
                VStack {
                    Spacer()

                    CompletionUndoToast(
                        entity: toast.entity,
                        config: config,
                        onUndo: {
                            toast.onUndo()
                            toastManager.hideToast()
                        },
                        isVisible: .constant(true)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60) // Position right above tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: toastManager.activeToast?.id)
    }
}

// MARK: - Type Aliases for Convenience

typealias TaskCompletionToastManager = CompletionToastManager<Task>
typealias HabitCompletionToastManager = CompletionToastManager<Habit>

typealias TaskCompletionToastContainer<Content: View> = CompletionToastContainer<Task, Content>
typealias HabitCompletionToastContainer<Content: View> = CompletionToastContainer<Habit, Content>
