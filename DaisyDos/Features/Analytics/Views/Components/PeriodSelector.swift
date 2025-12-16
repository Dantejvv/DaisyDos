//
//  PeriodSelector.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import SwiftUI

struct PeriodSelector: View {
    @Binding var selectedPeriod: AnalyticsPeriod

    var body: some View {
        HStack(spacing: Spacing.extraSmall) {
            ForEach(AnalyticsPeriod.allCases) { period in
                Button(action: {
                    selectedPeriod = period
                }) {
                    Text(period.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(selectedPeriod == period ? .white : .daisyText)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.extraSmall)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color.accentColor : Color.daisySurface)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.small)
    }
}

#Preview {
    @Previewable @State var period = AnalyticsPeriod.sevenDays

    PeriodSelector(selectedPeriod: $period)
        .padding()
        .background(Color.daisyBackground)
}
