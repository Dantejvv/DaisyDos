//
//  TouchTargetAuditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

/// Touch target audit tool with visual overlay and compliance validation
/// Provides color-coded validation, automated measurement, and compliance reporting
/// Ensures all interactive elements meet minimum 44pt touch target requirements
struct TouchTargetAuditView: View {
    @State private var auditMode: TouchTargetAuditMode = .visual
    @State private var showOverlay = false
    @State private var auditResults: [TouchTargetAuditResult] = []
    @State private var isRunningAudit = false
    @State private var selectedTargetType: TouchTargetType = .all
    @State private var complianceReport: TouchTargetComplianceReport?

    // Sample touch targets for demonstration
    @State private var sampleTargets: [TouchTargetSample] = [
        TouchTargetSample(id: "button-primary", type: .button, size: CGSize(width: 48, height: 48), label: "Primary Button"),
        TouchTargetSample(id: "button-small", type: .button, size: CGSize(width: 32, height: 32), label: "Small Button"),
        TouchTargetSample(id: "icon-button", type: .button, size: CGSize(width: 44, height: 44), label: "Icon Button"),
        TouchTargetSample(id: "text-field", type: .textField, size: CGSize(width: 200, height: 44), label: "Text Field"),
        TouchTargetSample(id: "checkbox", type: .control, size: CGSize(width: 24, height: 24), label: "Checkbox"),
        TouchTargetSample(id: "toggle", type: .control, size: CGSize(width: 51, height: 31), label: "Toggle"),
        TouchTargetSample(id: "list-item", type: .listItem, size: CGSize(width: 320, height: 50), label: "List Item"),
        TouchTargetSample(id: "tab-button", type: .navigation, size: CGSize(width: 78, height: 49), label: "Tab Button")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {

                    // MARK: - Touch Target Status

                    TouchTargetStatusCard(
                        complianceReport: complianceReport,
                        totalTargets: sampleTargets.count
                    )

                    // MARK: - Audit Mode Selection

                    AuditModeSection(
                        auditMode: $auditMode,
                        showOverlay: $showOverlay,
                        isRunningAudit: isRunningAudit
                    )

                    // MARK: - Target Type Filter

                    TargetTypeFilterSection(
                        selectedType: $selectedTargetType,
                        isRunningAudit: isRunningAudit
                    )

                    // MARK: - Audit Controls

                    AuditControlsSection(
                        isRunningAudit: $isRunningAudit,
                        onRunAudit: runTouchTargetAudit,
                        onClearResults: clearAuditResults,
                        onGenerateReport: generateComplianceReport
                    )

                    // MARK: - Sample Touch Targets

                    SampleTargetsSection(
                        targets: filteredTargets,
                        showOverlay: showOverlay
                    )

                    // MARK: - Audit Results

                    if !auditResults.isEmpty {
                        TouchTargetAuditResultsSection(results: auditResults)
                    }

                    // MARK: - Compliance Guidelines

                    TouchTargetGuidelinesSection()
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Touch Target Audit")
            .onAppear {
                generateInitialReport()
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredTargets: [TouchTargetSample] {
        if selectedTargetType == .all {
            return sampleTargets
        } else {
            return sampleTargets.filter { $0.type == selectedTargetType }
        }
    }

    // MARK: - Audit Functions

    private func runTouchTargetAudit() {
        isRunningAudit = true
        auditResults.removeAll()

        let targetsToAudit = filteredTargets

        for target in targetsToAudit {
            let result = auditTouchTarget(target)
            auditResults.append(result)
        }

        isRunningAudit = false
        generateComplianceReport()
    }

    private func auditTouchTarget(_ target: TouchTargetSample) -> TouchTargetAuditResult {
        let meetsMinimum = AccessibilityHelpers.TouchTarget.meetsMinimum(target.size)
        let meetsRecommended = target.size.width >= 48 && target.size.height >= 48
        let meetsLarge = target.size.width >= 56 && target.size.height >= 56

        let complianceLevel: TouchTargetComplianceLevel
        let issues: [String] = []
        var recommendations: [String] = []

        if meetsLarge {
            complianceLevel = .excellent
        } else if meetsRecommended {
            complianceLevel = .good
        } else if meetsMinimum {
            complianceLevel = .minimum
        } else {
            complianceLevel = .insufficient
        }

        // Generate recommendations based on compliance level and target type
        if complianceLevel == .insufficient {
            recommendations.append("Increase touch target to minimum 44×44pt")
        } else if complianceLevel == .minimum && target.type == .button {
            recommendations.append("Consider increasing to recommended 48×48pt for better usability")
        }

        if target.type == .control && !meetsMinimum {
            recommendations.append("Controls should meet minimum touch target requirements")
        }

        if target.size.width != target.size.height && target.type == .button {
            recommendations.append("Consider square touch targets for better predictability")
        }

        return TouchTargetAuditResult(
            target: target,
            complianceLevel: complianceLevel,
            meetsMinimum: meetsMinimum,
            meetsRecommended: meetsRecommended,
            issues: issues,
            recommendations: recommendations,
            measurements: TouchTargetMeasurements(
                width: target.size.width,
                height: target.size.height,
                area: target.size.width * target.size.height,
                aspectRatio: target.size.width / target.size.height
            )
        )
    }

    private func clearAuditResults() {
        auditResults.removeAll()
        complianceReport = nil
    }

    private func generateComplianceReport() {
        let totalTargets = auditResults.count
        guard totalTargets > 0 else { return }

        let excellentCount = auditResults.filter { $0.complianceLevel == .excellent }.count
        let goodCount = auditResults.filter { $0.complianceLevel == .good }.count
        let minimumCount = auditResults.filter { $0.complianceLevel == .minimum }.count
        let insufficientCount = auditResults.filter { $0.complianceLevel == .insufficient }.count

        let compliancePercentage = Double(totalTargets - insufficientCount) / Double(totalTargets) * 100
        let recommendedPercentage = Double(excellentCount + goodCount) / Double(totalTargets) * 100

        complianceReport = TouchTargetComplianceReport(
            totalTargets: totalTargets,
            compliantTargets: totalTargets - insufficientCount,
            recommendedTargets: excellentCount + goodCount,
            compliancePercentage: compliancePercentage,
            recommendedPercentage: recommendedPercentage,
            excellentCount: excellentCount,
            goodCount: goodCount,
            minimumCount: minimumCount,
            insufficientCount: insufficientCount,
            summary: generateReportSummary(
                compliancePercentage: compliancePercentage,
                recommendedPercentage: recommendedPercentage,
                insufficientCount: insufficientCount
            )
        )
    }

    private func generateInitialReport() {
        auditResults = sampleTargets.map { auditTouchTarget($0) }
        generateComplianceReport()
    }

    private func generateReportSummary(
        compliancePercentage: Double,
        recommendedPercentage: Double,
        insufficientCount: Int
    ) -> String {
        if compliancePercentage == 100 {
            if recommendedPercentage >= 80 {
                return "Excellent touch target compliance"
            } else {
                return "Good compliance with room for improvement"
            }
        } else if compliancePercentage >= 90 {
            return "Good compliance with minor issues"
        } else if insufficientCount > 3 {
            return "Multiple touch target violations need attention"
        } else {
            return "Touch target compliance needs improvement"
        }
    }
}

// MARK: - Supporting Types

enum TouchTargetAuditMode: String, CaseIterable {
    case visual = "Visual Overlay"
    case measurement = "Precise Measurement"
    case compliance = "Compliance Check"

    var description: String {
        return rawValue
    }

    var systemImage: String {
        switch self {
        case .visual:
            return "eye"
        case .measurement:
            return "ruler"
        case .compliance:
            return "checkmark.seal"
        }
    }
}

enum TouchTargetType: String, CaseIterable {
    case all = "All"
    case button = "Buttons"
    case control = "Controls"
    case textField = "Text Fields"
    case listItem = "List Items"
    case navigation = "Navigation"

    var systemImage: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .button: return "rectangle.fill"
        case .control: return "switch.2"
        case .textField: return "textbox"
        case .listItem: return "list.bullet"
        case .navigation: return "menubar.rectangle"
        }
    }
}

enum TouchTargetComplianceLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case minimum = "Minimum"
    case insufficient = "Insufficient"

    var color: Color {
        switch self {
        case .excellent:
            return Colors.Accent.success
        case .good:
            return Color.green
        case .minimum:
            return Colors.Accent.warning
        case .insufficient:
            return Colors.Accent.error
        }
    }

    var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .good:
            return "checkmark.circle"
        case .minimum:
            return "minus.circle"
        case .insufficient:
            return "xmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .excellent:
            return "56×56pt or larger - Excellent accessibility"
        case .good:
            return "48×48pt - Recommended size"
        case .minimum:
            return "44×44pt - Minimum requirement"
        case .insufficient:
            return "Below 44×44pt - Fails accessibility requirements"
        }
    }
}

struct TouchTargetSample {
    let id: String
    let type: TouchTargetType
    let size: CGSize
    let label: String
}

struct TouchTargetAuditResult {
    let target: TouchTargetSample
    let complianceLevel: TouchTargetComplianceLevel
    let meetsMinimum: Bool
    let meetsRecommended: Bool
    let issues: [String]
    let recommendations: [String]
    let measurements: TouchTargetMeasurements
}

struct TouchTargetMeasurements {
    let width: CGFloat
    let height: CGFloat
    let area: CGFloat
    let aspectRatio: CGFloat

    var displaySize: String {
        return "\(Int(width))×\(Int(height))pt"
    }

    var displayArea: String {
        return "\(Int(area))pt²"
    }

    var displayAspectRatio: String {
        return String(format: "%.2f:1", aspectRatio)
    }
}

struct TouchTargetComplianceReport {
    let totalTargets: Int
    let compliantTargets: Int
    let recommendedTargets: Int
    let compliancePercentage: Double
    let recommendedPercentage: Double
    let excellentCount: Int
    let goodCount: Int
    let minimumCount: Int
    let insufficientCount: Int
    let summary: String

    var overallGrade: String {
        if compliancePercentage == 100 && recommendedPercentage >= 80 {
            return "A+"
        } else if compliancePercentage >= 95 && recommendedPercentage >= 70 {
            return "A"
        } else if compliancePercentage >= 90 {
            return "B"
        } else if compliancePercentage >= 80 {
            return "C"
        } else {
            return "F"
        }
    }

    var gradeColor: Color {
        switch overallGrade {
        case "A+", "A":
            return Colors.Accent.success
        case "B":
            return Color.green
        case "C":
            return Colors.Accent.warning
        default:
            return Colors.Accent.error
        }
    }
}

// MARK: - View Components

struct TouchTargetStatusCard: View {
    let complianceReport: TouchTargetComplianceReport?
    let totalTargets: Int

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.title2)
                        .foregroundStyle(Colors.Secondary.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Touch Target Status")
                            .font(.headline)
                        if let report = complianceReport {
                            Text(report.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Ready for audit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let report = complianceReport {
                        VStack(spacing: 4) {
                            Text(report.overallGrade)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(report.gradeColor)

                            Text("Overall")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let report = complianceReport {
                    Divider()

                    HStack(spacing: Spacing.medium) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compliance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(String(format: "%.0f", report.compliancePercentage))%")
                                .font(.headline)
                                .foregroundStyle(report.compliancePercentage >= 90 ? Colors.Accent.success : Colors.Accent.warning)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(String(format: "%.0f", report.recommendedPercentage))%")
                                .font(.headline)
                                .foregroundStyle(report.recommendedPercentage >= 70 ? Colors.Accent.success : Colors.Accent.warning)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Issues")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(report.insufficientCount)")
                                .font(.headline)
                                .foregroundStyle(report.insufficientCount == 0 ? Colors.Accent.success : Colors.Accent.error)
                        }

                        Spacer()
                    }
                }
            }
        }
    }
}

struct AuditModeSection: View {
    @Binding var auditMode: TouchTargetAuditMode
    @Binding var showOverlay: Bool
    let isRunningAudit: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Audit Mode")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                    ForEach(TouchTargetAuditMode.allCases, id: \.rawValue) { mode in
                        Button(action: { auditMode = mode }) {
                            VStack(spacing: 4) {
                                Image(systemName: mode.systemImage)
                                    .font(.title3)
                                Text(mode.description)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(Spacing.small)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(auditMode == mode ? Colors.Secondary.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(auditMode == mode ? Colors.Secondary.blue : Colors.Semantic.separator, lineWidth: 1)
                            )
                        }
                        .disabled(isRunningAudit)
                        .accessibilityLabel("Select \(mode.description) audit mode")
                        .accessibilityAddTraits(auditMode == mode ? .isSelected : [])
                    }
                }

                if auditMode == .visual {
                    Toggle("Show Visual Overlay", isOn: $showOverlay)
                        .font(.subheadline)
                        .padding(.top, Spacing.small)
                }
            }
        }
    }
}

struct TargetTypeFilterSection: View {
    @Binding var selectedType: TouchTargetType
    let isRunningAudit: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Target Type Filter")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                    ForEach(TouchTargetType.allCases, id: \.rawValue) { type in
                        Button(action: { selectedType = type }) {
                            VStack(spacing: 4) {
                                Image(systemName: type.systemImage)
                                    .font(.title3)
                                Text(type.rawValue)
                                    .font(.caption)
                            }
                            .padding(Spacing.small)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedType == type ? Colors.Secondary.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedType == type ? Colors.Secondary.blue : Colors.Semantic.separator, lineWidth: 1)
                            )
                        }
                        .disabled(isRunningAudit)
                        .accessibilityLabel("Filter by \(type.rawValue)")
                        .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                    }
                }
            }
        }
    }
}

struct AuditControlsSection: View {
    @Binding var isRunningAudit: Bool
    let onRunAudit: () -> Void
    let onClearResults: () -> Void
    let onGenerateReport: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Audit Controls")
                    .font(.headline)

                if isRunningAudit {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Auditing touch targets...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: Spacing.small) {
                        DaisyButton(
                            title: "Run Audit",
                            style: .primary,
                            size: .medium,
                            icon: "play.fill",
                            action: onRunAudit
                        )

                        DaisyButton(
                            title: "Clear Results",
                            style: .secondary,
                            size: .medium,
                            icon: "trash",
                            action: onClearResults
                        )

                        DaisyButton(
                            title: "Export Report",
                            style: .tertiary,
                            size: .medium,
                            icon: "square.and.arrow.up",
                            action: onGenerateReport
                        )

                        Spacer()
                    }
                }
            }
        }
    }
}

struct SampleTargetsSection: View {
    let targets: [TouchTargetSample]
    let showOverlay: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Sample Touch Targets")
                    .font(.headline)

                Text("Interactive elements to demonstrate touch target validation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.medium) {
                    ForEach(targets.prefix(8), id: \.id) { target in
                        SampleTouchTargetView(target: target, showOverlay: showOverlay)
                    }
                }
            }
        }
    }
}

struct SampleTouchTargetView: View {
    let target: TouchTargetSample
    let showOverlay: Bool

    private var complianceLevel: TouchTargetComplianceLevel {
        let meetsMinimum = AccessibilityHelpers.TouchTarget.meetsMinimum(target.size)
        let meetsRecommended = target.size.width >= 48 && target.size.height >= 48
        let meetsLarge = target.size.width >= 56 && target.size.height >= 56

        if meetsLarge {
            return .excellent
        } else if meetsRecommended {
            return .good
        } else if meetsMinimum {
            return .minimum
        } else {
            return .insufficient
        }
    }

    var body: some View {
        VStack(spacing: Spacing.small) {
            ZStack {
                // Base touch target
                Button(action: {}) {
                    Group {
                        switch target.type {
                        case .button, .all:
                            Text("Button")
                                .font(.subheadline)
                        case .control:
                            Image(systemName: "checkmark.square")
                                .font(.title2)
                        case .textField:
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Colors.Primary.surface)
                                .overlay(
                                    Text("Text")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                )
                        case .listItem:
                            HStack {
                                Text("List Item")
                                    .font(.subheadline)
                                Spacer()
                            }
                        case .navigation:
                            Image(systemName: "house")
                                .font(.title2)
                        }
                    }
                }
                .frame(width: target.size.width, height: target.size.height)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Colors.Secondary.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Colors.Semantic.separator, lineWidth: 1)
                )

                // Overlay for compliance visualization
                if showOverlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(complianceLevel.color, lineWidth: 2)
                        .frame(width: target.size.width, height: target.size.height)

                    // Size indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(Int(target.size.width))×\(Int(target.size.height))")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(complianceLevel.color)
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: target.size.width, height: target.size.height)
                }
            }

            // Target information
            VStack(spacing: 2) {
                Text(target.label)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(Int(target.size.width))×\(Int(target.size.height))pt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if showOverlay {
                    HStack {
                        Image(systemName: complianceLevel.icon)
                            .font(.caption2)
                        Text(complianceLevel.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(complianceLevel.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TouchTargetAuditResultsSection: View {
    let results: [TouchTargetAuditResult]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Audit Results")
                    .font(.headline)

                // Results by compliance level
                let groupedResults = Dictionary(grouping: results) { $0.complianceLevel }

                ForEach(TouchTargetComplianceLevel.allCases, id: \.rawValue) { level in
                    if let levelResults = groupedResults[level], !levelResults.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundStyle(level.color)
                                Text("\(level.rawValue) (\(levelResults.count))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }

                            ForEach(levelResults.prefix(3), id: \.target.id) { result in
                                HStack {
                                    Text(result.target.label)
                                        .font(.caption)
                                    Spacer()
                                    Text(result.measurements.displaySize)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, Spacing.medium)
                            }

                            if levelResults.count > 3 {
                                Text("... and \(levelResults.count - 3) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .padding(.leading, Spacing.medium)
                            }
                        }
                        .padding(Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(level.color.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
}

struct TouchTargetGuidelinesSection: View {
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Touch Target Guidelines")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    GuidelineRow(
                        level: .insufficient,
                        description: "Below 44×44pt - Fails accessibility requirements"
                    )
                    GuidelineRow(
                        level: .minimum,
                        description: "44×44pt - Minimum iOS requirement"
                    )
                    GuidelineRow(
                        level: .good,
                        description: "48×48pt - Recommended for primary actions"
                    )
                    GuidelineRow(
                        level: .excellent,
                        description: "56×56pt+ - Excellent accessibility"
                    )
                }

                Text("Best Practices:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.small)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Maintain adequate spacing between targets", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                    Label("Consider larger sizes for users with motor difficulties", systemImage: "accessibility")
                    Label("Test with real users and devices", systemImage: "hand.tap")
                    Label("Ensure targets scale with Dynamic Type", systemImage: "textformat.size")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct GuidelineRow: View {
    let level: TouchTargetComplianceLevel
    let description: String

    var body: some View {
        HStack {
            Image(systemName: level.icon)
                .foregroundStyle(level.color)
                .frame(width: 16)

            Text(description)
                .font(.caption)

            Spacer()
        }
    }
}

#Preview {
    TouchTargetAuditView()
}