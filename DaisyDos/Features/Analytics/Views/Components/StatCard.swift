//
//  StatCard.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let accentColor: Color

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        accentColor: Color = .accentColor
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentColor)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)

                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.daisyText)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(Color.daisySurface)
        )
    }
}

#Preview("Single Card") {
    StatCard(
        title: "Current Streak",
        value: "12 days",
        subtitle: "Best: 25 days",
        icon: "flame.fill",
        accentColor: .orange
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Multiple Cards") {
    HStack(spacing: Spacing.small) {
        StatCard(
            title: "Completed",
            value: "8",
            subtitle: "Today",
            icon: "checkmark.circle.fill",
            accentColor: .green
        )

        StatCard(
            title: "Pending",
            value: "3",
            subtitle: "Remaining",
            icon: "circle",
            accentColor: .orange
        )
    }
    .padding()
    .background(Color.daisyBackground)
}
