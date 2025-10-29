//
//  BulkActionToolbar.swift
//  DaisyDos
//
//  Created by Claude Code on 10/28/25.
//  Generic bulk action toolbar for multi-select operations
//

import SwiftUI

/// A generic toolbar for displaying bulk actions when items are selected
struct BulkActionToolbar<Actions: View>: View {
    let selectedCount: Int
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack {
            Text("\(selectedCount) selected")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Spacer()

            HStack(spacing: 20) {
                actions()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

// MARK: - Preview

#Preview("Bulk Action Toolbar - Tasks") {
    VStack {
        Spacer()

        BulkActionToolbar(selectedCount: 5) {
            Button(action: {}) {
                Label("Toggle Complete", systemImage: "checkmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisySuccess)

            Button(action: {}) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyError)
        }
    }
    .background(Color.daisyBackground)
}

#Preview("Bulk Action Toolbar - Habits") {
    VStack {
        Spacer()

        BulkActionToolbar(selectedCount: 3) {
            Button(action: {}) {
                Label("Complete", systemImage: "checkmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisySuccess)

            Button(action: {}) {
                Label("Skip", systemImage: "forward.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyWarning)

            Button(action: {}) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyError)
        }
    }
    .background(Color.daisyBackground)
}

#Preview("Bulk Action Toolbar - Tags") {
    VStack {
        Spacer()

        BulkActionToolbar(selectedCount: 8) {
            Button(action: {}) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyError)
        }
    }
    .background(Color.daisyBackground)
}
