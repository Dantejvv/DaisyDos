//
//  MetadataIndicators.swift
//  DaisyDos
//
//  Created by Claude Code on 1/11/25.
//  Reusable metadata indicators for row views
//

import SwiftUI

// MARK: - Subtask Progress Indicator

struct SubtaskProgressIndicator: View {
    let progressText: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "checklist")
                .font(.body)
                .foregroundColor(.daisyTextSecondary)
            Text(progressText)
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }
}

// MARK: - Attachment Badge Indicator

struct AttachmentBadgeIndicator: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "paperclip")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
        }
    }
}

// MARK: - Metadata Separator

struct MetadataSeparator: View {
    var body: some View {
        Text("•")
            .font(.caption2)
            .foregroundColor(.daisyTextSecondary)
    }
}

// MARK: - Preview

#Preview("Metadata Indicators") {
    VStack(spacing: 16) {
        HStack {
            SubtaskProgressIndicator(progressText: "2/5")
            MetadataSeparator()
            AttachmentBadgeIndicator(count: 3)
            MetadataSeparator()
            Image(systemName: "bell.fill")
                .font(.caption2)
                .foregroundColor(.daisyWarning)
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 8))

        HStack {
            SubtaskProgressIndicator(progressText: "0/3")
            MetadataSeparator()
            AttachmentBadgeIndicator(count: 1)
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
