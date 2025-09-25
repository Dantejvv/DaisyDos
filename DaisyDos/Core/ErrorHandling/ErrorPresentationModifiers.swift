//
//  ErrorPresentationModifiers.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/24/25.
//

import SwiftUI

// MARK: - Error State Management

/// Observable class to manage error presentation state
@Observable
class ErrorPresentationManager {
    var currentError: (any RecoverableError)?
    var presentationStyle: ErrorPresentationStyle = .alert
    var isPresenting = false

    func present(_ error: RecoverableError, style: ErrorPresentationStyle = .alert) {
        currentError = error
        presentationStyle = style
        isPresenting = true
    }

    func dismiss() {
        isPresenting = false
        currentError = nil
    }
}

/// Error presentation styles
enum ErrorPresentationStyle {
    case alert      // Modal alert dialog
    case banner     // Top banner notification
    case overlay    // Inline error overlay
    case toast      // Bottom toast notification
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: (any RecoverableError)?
    let style: ErrorPresentationStyle

    func body(content: Content) -> some View {
        content
            .alert(
                error?.userMessage ?? "Error",
                isPresented: Binding<Bool>(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                if let currentError = error {
                    ForEach(Array(currentError.recoveryOptions.enumerated()), id: \.offset) { index, action in
                        Button(action.title, role: buttonRole(for: action.style)) {
                            _Concurrency.Task {
                                await action.action()
                            }
                            error = nil
                        }
                    }
                }
            } message: {
                if let currentError = error {
                    Text(currentError.userReason)
                }
            }
    }

    private func buttonRole(for style: RecoveryAction.ActionStyle) -> ButtonRole? {
        switch style {
        case .primary: return nil
        case .secondary: return .cancel
        case .destructive: return .destructive
        }
    }
}

// MARK: - Error Banner Modifier

struct ErrorBannerModifier: ViewModifier {
    @Binding var error: (any RecoverableError)?
    let autoDismiss: Bool

    @State private var isVisible = false
    @State private var currentErrorMessage = ""

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let error = error, isVisible {
                ErrorBannerView(
                    error: error,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.error = nil
                        }
                    },
                    onAction: { action in
                        _Concurrency.Task {
                            await action.action()
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.error = nil
                        }
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .onChange(of: error?.userMessage ?? "") { _, newMessage in
            currentErrorMessage = newMessage

            if !newMessage.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = true
                }

                // Auto-dismiss for low priority errors
                if autoDismiss, let error = error, error.priority == .low {
                    DispatchQueue.main.asyncAfter(deadline: .now() + error.priority.displayDuration) {
                        if self.currentErrorMessage == newMessage {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.error = nil
                            }
                        }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: RecoverableError
    let onDismiss: () -> Void
    let onAction: (RecoveryAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Error priority icon
                Image(systemName: iconForPriority(error.priority))
                    .foregroundColor(colorForPriority(error.priority))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.userMessage)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !error.userReason.isEmpty && error.userReason != error.userMessage {
                        Text(error.userReason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Primary action button
                if let primaryAction = error.recoveryOptions.first(where: { $0.style == .primary }) {
                    Button(primaryAction.title) {
                        onAction(primaryAction)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorForPriority(error.priority))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorForPriority(error.priority).opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Additional actions
            if error.recoveryOptions.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(error.recoveryOptions.dropFirst().enumerated()), id: \.offset) { _, action in
                            Button(action.title) {
                                onAction(action)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(error.userMessage)
        .accessibilityHint(error.userReason)
    }

    private func iconForPriority(_ priority: ErrorPriority) -> String {
        switch priority {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private func colorForPriority(_ priority: ErrorPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}

// MARK: - Error Overlay Modifier

struct ErrorOverlayModifier: ViewModifier {
    @Binding var error: (any RecoverableError)?

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let error = error {
                        ErrorOverlayView(error: error) {
                            self.error = nil
                        }
                    }
                }
            )
    }
}

struct ErrorOverlayView: View {
    let error: RecoverableError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text(error.userMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if !error.userReason.isEmpty && error.userReason != error.userMessage {
                    Text(error.userReason)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 8) {
                ForEach(Array(error.recoveryOptions.enumerated()), id: \.offset) { index, action in
                    Button(action.title) {
                        _Concurrency.Task {
                            await action.action()
                        }
                        onDismiss()
                    }
                    .buttonStyle(ErrorActionButtonStyle(style: action.style))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.separator, lineWidth: 1)
                )
        )
        .padding(32)
    }
}

struct ErrorActionButtonStyle: ButtonStyle {
    let style: RecoveryAction.ActionStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .accentColor
        case .secondary: return .secondary.opacity(0.1)
        case .destructive: return .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Present errors as modal alerts
    func errorAlert(_ error: Binding<(any RecoverableError)?>) -> some View {
        modifier(ErrorAlertModifier(error: error, style: .alert))
    }

    /// Present errors as top banners
    func errorBanner(_ error: Binding<(any RecoverableError)?>, autoDismiss: Bool = true) -> some View {
        modifier(ErrorBannerModifier(error: error, autoDismiss: autoDismiss))
    }

    /// Present errors as overlay content
    func errorOverlay(_ error: Binding<(any RecoverableError)?>) -> some View {
        modifier(ErrorOverlayModifier(error: error))
    }

    /// Convenience method to handle Result<T, RecoverableError> values
    func handleResult<T>(
        _ result: Result<T, AnyRecoverableError>,
        errorBinding: Binding<(any RecoverableError)?>,
        onSuccess: @escaping (T) -> Void = { _ in }
    ) -> some View {
        self.task {
            switch result {
            case .success(let value):
                onSuccess(value)
            case .failure(let error):
                await MainActor.run {
                    errorBinding.wrappedValue = error.wrapped
                }
            }
        }
    }

    /// Present errors using an ErrorPresentationManager
    func errorPresentation(_ manager: ErrorPresentationManager) -> some View {
        self
            .errorAlert(.constant(manager.presentationStyle == .alert ? manager.currentError : nil))
            .errorBanner(.constant(manager.presentationStyle == .banner ? manager.currentError : nil))
            .errorOverlay(.constant(manager.presentationStyle == .overlay ? manager.currentError : nil))
    }
}