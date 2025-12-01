//
//  ErrorAlertModifier.swift
//  DaisyDos
//
//  Created by Claude Code on 11/29/25.
//  SwiftUI alert presentation for RecoverableError
//

import SwiftUI

// MARK: - Action Style Extension

extension RecoveryAction.ActionStyle {
    /// Maps RecoveryAction.ActionStyle to SwiftUI's ButtonRole
    var buttonRole: ButtonRole? {
        switch self {
        case .primary, .secondary:
            return nil
        case .destructive:
            return .destructive
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents an alert when a RecoverableError is set
    func errorAlert(error: Binding<(any RecoverableError)?>) -> some View {
        self.modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: (any RecoverableError)?

    func body(content: Content) -> some View {
        content.alert(
            error?.userMessage ?? "",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )
        ) {
            alertButtons
        } message: {
            alertMessageView
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        if let currentError = error {
            let actions = Array(currentError.recoveryOptions.prefix(3))

            if actions.isEmpty {
                Button("OK") { error = nil }
            } else {
                if actions.count >= 1 {
                    makeButton(action: actions[0])
                }
                if actions.count >= 2 {
                    makeButton(action: actions[1])
                }
                if actions.count >= 3 {
                    makeButton(action: actions[2])
                }
            }
        }
    }

    @ViewBuilder
    private var alertMessageView: some View {
        if let currentError = error,
           let suggestion = currentError.recoverySuggestion,
           !suggestion.isEmpty {
            Text(suggestion)
        }
    }

    private func makeButton(action: RecoveryAction) -> some View {
        Button(action.title, role: action.style.buttonRole) {
            _Concurrency.Task { await action.action() }
            error = nil
        }
    }
}

// MARK: - Preview

#Preview("Error Alert") {
    struct PreviewContainer: View {
        @State private var error: (any RecoverableError)?

        var body: some View {
            VStack(spacing: 20) {
                Button("Show Validation Error") {
                    error = DaisyDosError.validationFailed("Title is required")
                }

                Button("Show Persistence Error") {
                    error = DaisyDosError.persistenceFailed("Save failed")
                }

                Button("Show Tag Limit Error") {
                    error = DaisyDosError.tagLimitExceeded
                }

                Button("Show Info Error") {
                    error = InfoError(message: "This is an informational message", reason: "No action needed")
                }
            }
            .buttonStyle(.bordered)
            .errorAlert(error: $error)
        }
    }

    return PreviewContainer()
}
