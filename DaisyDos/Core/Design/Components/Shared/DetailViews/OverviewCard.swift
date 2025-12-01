//
//  OverviewCard.swift
//  DaisyDos
//
//  Created by Claude Code on 1/11/25.
//  Reusable overview card for detail views
//

import SwiftUI

// MARK: - Overview Card

struct OverviewCard: View {
    let title: String
    let description: AttributedString
    let isEmpty: Bool

    init(title: String, description: AttributedString) {
        self.title = title
        self.description = description
        self.isEmpty = String(description.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.daisyText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Description
            if !isEmpty {
                ScrollableDescriptionView(
                    text: description,
                    maxHeight: 200
                )
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Overview Card") {
    VStack(spacing: 20) {
        // With description
        OverviewCard(
            title: "Complete Quarterly Report",
            description: AttributedString("Prepare the comprehensive quarterly report including all metrics, analysis, and recommendations for the executive team. This is a critical deliverable for the company.")
        )

        // Without description
        OverviewCard(
            title: "Simple Task",
            description: AttributedString("")
        )
    }
    .padding()
}
