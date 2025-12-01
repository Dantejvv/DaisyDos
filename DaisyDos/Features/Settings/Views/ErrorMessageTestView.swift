//
//  ErrorMessageTestView.swift
//  DaisyDos
//
//  Debug view for testing error messages
//

import SwiftUI

#if DEBUG
struct ErrorMessageTestView: View {
    @State private var selectedError: DaisyDosError?

    var body: some View {
        List {
            infoSection
            validationSection
            dataSection
            systemSection
            criticalSection
        }
        .navigationTitle("Test Error Messages")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            selectedError?.userMessage ?? "Error",
            isPresented: errorPresented
        ) {
            errorButtons
        } message: {
            errorMessage
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { selectedError != nil },
            set: { if !$0 { selectedError = nil } }
        )
    }

    @ViewBuilder
    private var errorButtons: some View {
        if let error = selectedError {
            ForEach(0..<error.recoveryOptions.count, id: \.self) { index in
                Button(error.recoveryOptions[index].title) {
                    _Concurrency.Task {
                        await error.recoveryOptions[index].action()
                        selectedError = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error = selectedError {
            Text(error.userReason)
        }
    }

    private var infoSection: some View {
        Section {
            Text("Tap any error below to see how it will appear to users")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var validationSection: some View {
        Section("Validation Errors (Low Priority)") {
            ErrorTestButton(title: "Tag Limit Exceeded", error: .tagLimitExceeded, selectedError: $selectedError)
            ErrorTestButton(title: "Invalid Recurrence", error: .invalidRecurrence, selectedError: $selectedError)
            ErrorTestButton(title: "Circular Reference", error: .circularReference, selectedError: $selectedError)
            ErrorTestButton(title: "Validation Failed", error: .validationFailed("title"), selectedError: $selectedError)
        }
    }

    private var dataSection: some View {
        Section("Data Errors (Medium Priority)") {
            ErrorTestButton(title: "Duplicate Entity", error: .duplicateEntity("Task"), selectedError: $selectedError)
            ErrorTestButton(title: "Entity Not Found", error: .entityNotFound("Task"), selectedError: $selectedError)
            ErrorTestButton(title: "Persistence Failed", error: .persistenceFailed("task"), selectedError: $selectedError)
            ErrorTestButton(title: "Export Failed", error: .exportFailed("Insufficient storage space"), selectedError: $selectedError)
            ErrorTestButton(title: "Import Failed", error: .importFailed("Invalid file format"), selectedError: $selectedError)
        }
    }

    private var systemSection: some View {
        Section("System Errors (High Priority)") {
            ErrorTestButton(title: "Network Unavailable", error: .networkUnavailable, selectedError: $selectedError)
            ErrorTestButton(title: "Permission Denied", error: .permissionDenied("Photos"), selectedError: $selectedError)
            ErrorTestButton(title: "Integration Failed", error: .integrationFailed("iCloud"), selectedError: $selectedError)
            ErrorTestButton(title: "Database Error", error: .databaseError("Failed to fetch tasks"), selectedError: $selectedError)
        }
    }

    private var criticalSection: some View {
        Section("Critical Errors") {
            ErrorTestButton(title: "Model Context Unavailable", error: .modelContextUnavailable, selectedError: $selectedError)
            ErrorTestButton(title: "Data Corrupted", error: .dataCorrupted("Unknown corruption detected"), selectedError: $selectedError)
            ErrorTestButton(title: "Sync Conflict", error: .syncConflict("Multiple devices modified the same task"), selectedError: $selectedError)
        }
    }
}

struct ErrorTestButton: View {
    let title: String
    let error: DaisyDosError
    @Binding var selectedError: DaisyDosError?

    var body: some View {
        Button {
            selectedError = error
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)

                    Text(error.userMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                priorityBadge
            }
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        let (icon, color) = priorityInfo

        Label(error.priority.displayName, systemImage: icon)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var priorityInfo: (String, Color) {
        switch error.priority {
        case .low:
            return ("info.circle.fill", .blue)
        case .medium:
            return ("exclamationmark.circle.fill", .orange)
        case .high:
            return ("exclamationmark.triangle.fill", .red)
        case .critical:
            return ("exclamationmark.octagon.fill", .purple)
        }
    }
}

extension ErrorPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

#Preview {
    NavigationStack {
        ErrorMessageTestView()
    }
}
#endif
