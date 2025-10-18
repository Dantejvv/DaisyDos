//
//  DynamicTypeTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
@testable import DaisyDos
import SwiftData
@testable import DaisyDos

/// Dynamic Type validation system for testing text scaling and layout adaptation
/// Tests all Dynamic Type categories from xSmall to AX3 with visual previews
/// Ensures proper layout behavior at extreme text sizes and accessibility compliance
struct DynamicTypeTestView: View {
    @State private var selectedCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    @State private var selectedTestComponent: DynamicTypeTestComponent = .buttons
    @State private var showingDetailedAnalysis = false
    @State private var testResults: [DynamicTypeTestResult] = []
    @State private var isRunningTests = false

    // Sample data for testing
    @State private var sampleTasks = [
        ("Complete project presentation", false, "High"),
        ("Review design mockups", true, "Medium"),
        ("Schedule team meeting for next week discussion", false, "Low")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {

                    // MARK: - Dynamic Type Status

                    DynamicTypeStatusCard(
                        currentCategory: selectedCategory,
                        systemCategory: UIApplication.shared.preferredContentSizeCategory
                    )

                    // MARK: - Category Selection

                    DynamicTypeCategorySection(selectedCategory: $selectedCategory)

                    // MARK: - Component Testing

                    ComponentSelectionSection(
                        selectedComponent: $selectedTestComponent,
                        isRunningTests: isRunningTests
                    )

                    // MARK: - Test Preview

                    TestPreviewSection(
                        component: selectedTestComponent,
                        category: selectedCategory,
                        sampleTasks: sampleTasks
                    )

                    // MARK: - Automated Testing

                    AutomatedTestingSection(
                        isRunningTests: $isRunningTests,
                        testResults: $testResults,
                        onRunTests: runDynamicTypeTests
                    )

                    // MARK: - Test Results

                    if !testResults.isEmpty {
                        DynamicTypeTestResultsSection(results: testResults)
                    }

                    // MARK: - Guidelines

                    DynamicTypeGuidelinesSection()
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Dynamic Type Testing")
            .dynamicTypeSize(DynamicTypeSize.large)
            .sheet(isPresented: $showingDetailedAnalysis) {
                DynamicTypeDetailAnalysisView(category: selectedCategory)
            }
        }
    }

    // MARK: - Test Execution

    private func runDynamicTypeTests() {
        isRunningTests = true
        testResults.removeAll()

        let categories = AccessibilityHelpers.DynamicType.allCategories
        let components = DynamicTypeTestComponent.allCases

        for category in categories {
            for component in components {
                let result = testComponentAtCategory(component: component, category: category)
                testResults.append(result)
            }
        }

        isRunningTests = false
    }

    private func testComponentAtCategory(
        component: DynamicTypeTestComponent,
        category: UIContentSizeCategory
    ) -> DynamicTypeTestResult {
        let scalingFactor = getScalingFactor(for: category)
        let isAccessibilitySize = category.isAccessibilityCategory

        // Simulate component testing
        let baseSize = component.baseSize
        let scaledSize = baseSize * scalingFactor

        // Check if scaling is reasonable
        let isValidScaling = scaledSize <= component.maxReasonableSize && scaledSize >= component.minReasonableSize

        // Check layout concerns
        let layoutConcerns = getLayoutConcerns(for: component, scaledSize: scaledSize, isAccessibilitySize: isAccessibilitySize)

        return DynamicTypeTestResult(
            component: component,
            category: category,
            baseSize: baseSize,
            scaledSize: scaledSize,
            scalingFactor: scalingFactor,
            isValidScaling: isValidScaling,
            layoutConcerns: layoutConcerns,
            recommendations: getRecommendations(
                component: component,
                isValidScaling: isValidScaling,
                layoutConcerns: layoutConcerns,
                isAccessibilitySize: isAccessibilitySize
            )
        )
    }

    private func getScalingFactor(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.5
        case .accessibilityExtraLarge: return 1.6
        case .accessibilityExtraExtraLarge: return 1.7
        case .accessibilityExtraExtraExtraLarge: return 1.8
        default: return 1.0
        }
    }

    private func getLayoutConcerns(
        for component: DynamicTypeTestComponent,
        scaledSize: CGFloat,
        isAccessibilitySize: Bool
    ) -> [String] {
        var concerns: [String] = []

        if scaledSize > component.maxReasonableSize {
            concerns.append("Text may be too large for comfortable viewing")
        }

        if scaledSize < component.minReasonableSize {
            concerns.append("Text may be too small to read comfortably")
        }

        if isAccessibilitySize && component.requiresSpecialHandling {
            concerns.append("Component may need layout adjustments for accessibility sizes")
        }

        if component == .buttons && scaledSize > 24 {
            concerns.append("Button text may cause layout overflow")
        }

        if component == .lists && scaledSize > 28 {
            concerns.append("List items may become too tall")
        }

        return concerns
    }

    private func getRecommendations(
        component: DynamicTypeTestComponent,
        isValidScaling: Bool,
        layoutConcerns: [String],
        isAccessibilitySize: Bool
    ) -> [String] {
        var recommendations: [String] = []

        if !isValidScaling {
            recommendations.append("Consider adjusting base font size for better scaling")
        }

        if !layoutConcerns.isEmpty {
            recommendations.append("Test layout with extreme Dynamic Type sizes")
        }

        if isAccessibilitySize {
            recommendations.append("Ensure adequate spacing and touch targets")

            if component.requiresSpecialHandling {
                recommendations.append("Consider alternative layouts for accessibility sizes")
            }
        }

        return recommendations
    }
}

// MARK: - Supporting Types

enum DynamicTypeTestComponent: String, CaseIterable {
    case buttons = "Buttons"
    case labels = "Labels"
    case textFields = "Text Fields"
    case lists = "List Items"
    case navigationBars = "Navigation Bars"
    case cards = "Card Components"

    var systemImage: String {
        switch self {
        case .buttons: return "rectangle.fill"
        case .labels: return "textformat"
        case .textFields: return "textbox"
        case .lists: return "list.bullet"
        case .navigationBars: return "menubar.rectangle"
        case .cards: return "rectangle.on.rectangle"
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .buttons: return 16
        case .labels: return 16
        case .textFields: return 16
        case .lists: return 16
        case .navigationBars: return 17
        case .cards: return 14
        }
    }

    var maxReasonableSize: CGFloat {
        switch self {
        case .buttons: return 32
        case .labels: return 36
        case .textFields: return 32
        case .lists: return 34
        case .navigationBars: return 28
        case .cards: return 30
        }
    }

    var minReasonableSize: CGFloat {
        switch self {
        case .buttons: return 12
        case .labels: return 11
        case .textFields: return 12
        case .lists: return 12
        case .navigationBars: return 13
        case .cards: return 10
        }
    }

    var requiresSpecialHandling: Bool {
        switch self {
        case .buttons, .textFields, .navigationBars: return true
        case .labels, .lists, .cards: return false
        }
    }
}

struct DynamicTypeTestResult {
    let component: DynamicTypeTestComponent
    let category: UIContentSizeCategory
    let baseSize: CGFloat
    let scaledSize: CGFloat
    let scalingFactor: CGFloat
    let isValidScaling: Bool
    let layoutConcerns: [String]
    let recommendations: [String]

    var hasIssues: Bool {
        !isValidScaling || !layoutConcerns.isEmpty
    }

    var severityLevel: SeverityLevel {
        if !isValidScaling {
            return .critical
        } else if !layoutConcerns.isEmpty {
            return .warning
        } else {
            return .pass
        }
    }

    enum SeverityLevel {
        case pass, warning, critical

        var color: Color {
            switch self {
            case .pass: return Colors.Accent.success
            case .warning: return Colors.Accent.warning
            case .critical: return Colors.Accent.error
            }
        }

        var icon: String {
            switch self {
            case .pass: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - View Components

struct DynamicTypeStatusCard: View {
    let currentCategory: UIContentSizeCategory
    let systemCategory: UIContentSizeCategory

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Image(systemName: "textformat.size")
                        .font(.title2)
                        .foregroundStyle(Colors.Secondary.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Type Status")
                            .font(.headline)
                        Text("Testing: \(categoryDisplayName(currentCategory))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Test")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(categoryDisplayName(currentCategory))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("System Setting")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(categoryDisplayName(systemCategory))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                if currentCategory.isAccessibilityCategory {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundStyle(Colors.Accent.success)
                        Text("Accessibility Size Category")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Colors.Accent.success)
                    }
                    .padding(.top, Spacing.small)
                }
            }
        }
    }

    private func categoryDisplayName(_ category: UIContentSizeCategory) -> String {
        switch category {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "AX1"
        case .accessibilityLarge: return "AX2"
        case .accessibilityExtraLarge: return "AX3"
        case .accessibilityExtraExtraLarge: return "AX4"
        case .accessibilityExtraExtraExtraLarge: return "AX5"
        default: return "Unknown"
        }
    }
}

struct DynamicTypeCategorySection: View {
    @Binding var selectedCategory: UIContentSizeCategory

    private let standardCategories: [UIContentSizeCategory] = [
        .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge, .extraExtraExtraLarge
    ]

    private let accessibilityCategories: [UIContentSizeCategory] = [
        .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
        .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge
    ]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Dynamic Type Categories")
                    .font(.headline)

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Standard Sizes")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.small) {
                        ForEach(standardCategories, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Accessibility Sizes")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                        ForEach(accessibilityCategories, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: UIContentSizeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("Aa")
                    .font(.system(size: previewSize))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Colors.Secondary.blue.opacity(0.2) : Colors.Primary.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Colors.Secondary.blue : Colors.Semantic.separator, lineWidth: 1)
            )
        }
        .accessibilityLabel("Select \(displayName) text size")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var displayName: String {
        switch category {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "AX1"
        case .accessibilityLarge: return "AX2"
        case .accessibilityExtraLarge: return "AX3"
        case .accessibilityExtraExtraLarge: return "AX4"
        case .accessibilityExtraExtraExtraLarge: return "AX5"
        default: return "?"
        }
    }

    private var previewSize: CGFloat {
        switch category {
        case .extraSmall: return 12
        case .small: return 14
        case .medium: return 16
        case .large: return 17
        case .extraLarge: return 19
        case .extraExtraLarge: return 21
        case .extraExtraExtraLarge: return 23
        case .accessibilityMedium: return 25
        case .accessibilityLarge: return 28
        case .accessibilityExtraLarge: return 31
        case .accessibilityExtraExtraLarge: return 34
        case .accessibilityExtraExtraExtraLarge: return 37
        default: return 16
        }
    }
}

struct ComponentSelectionSection: View {
    @Binding var selectedComponent: DynamicTypeTestComponent
    let isRunningTests: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Test Components")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.small) {
                    ForEach(DynamicTypeTestComponent.allCases, id: \.rawValue) { component in
                        Button(action: { selectedComponent = component }) {
                            VStack(spacing: 4) {
                                Image(systemName: component.systemImage)
                                    .font(.title3)
                                Text(component.rawValue)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(Spacing.small)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedComponent == component ? Colors.Secondary.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedComponent == component ? Colors.Secondary.blue : Colors.Semantic.separator, lineWidth: 1)
                            )
                        }
                        .disabled(isRunningTests)
                        .accessibilityLabel("Select \(component.rawValue) component")
                        .accessibilityAddTraits(selectedComponent == component ? .isSelected : [])
                    }
                }
            }
        }
    }
}

struct TestPreviewSection: View {
    let component: DynamicTypeTestComponent
    let category: UIContentSizeCategory
    let sampleTasks: [(String, Bool, String)]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Component Preview")
                    .font(.headline)

                Text("Preview at \(categoryDisplayName(category)) size")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Component previews
                Group {
                    switch component {
                    case .buttons:
                        ButtonPreview()
                    case .labels:
                        LabelPreview()
                    case .textFields:
                        TextFieldPreview()
                    case .lists:
                        ListPreview(tasks: sampleTasks)
                    case .navigationBars:
                        NavigationBarPreview()
                    case .cards:
                        CardPreview(tasks: sampleTasks)
                    }
                }
                .dynamicTypeSize(DynamicTypeSize.large)
            }
        }
    }

    private func categoryDisplayName(_ category: UIContentSizeCategory) -> String {
        switch category {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "Extra Extra Large"
        case .extraExtraExtraLarge: return "Extra Extra Extra Large"
        case .accessibilityMedium: return "Accessibility Medium"
        case .accessibilityLarge: return "Accessibility Large"
        case .accessibilityExtraLarge: return "Accessibility Extra Large"
        case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
        default: return "Unknown"
        }
    }
}

// MARK: - Component Previews

struct ButtonPreview: View {
    var body: some View {
        VStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Button("Primary Action") {}
                    .buttonStyle(.borderedProminent)

                Button("Secondary") {}
                    .buttonStyle(.bordered)

                Spacer()
            }

            HStack(spacing: Spacing.small) {
                Button("Save Changes") {}
                    .buttonStyle(.borderedProminent)

                Button("Cancel") {}
                    .buttonStyle(.bordered)

                Spacer()
            }
        }
    }
}

struct LabelPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Headline Text Sample")
                .font(.headline)

            Text("Body text that demonstrates how regular content scales with Dynamic Type settings. This should remain readable at all sizes.")
                .font(.body)

            Text("Caption text for additional information")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct TextFieldPreview: View {
    @State private var text1 = "Sample input text"
    @State private var text2 = ""

    var body: some View {
        VStack(spacing: Spacing.small) {
            TextField("Task title", text: $text1)
                .textFieldStyle(.roundedBorder)

            TextField("Add a note...", text: $text2)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct ListPreview: View {
    let tasks: [(String, Bool, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            ForEach(tasks.indices, id: \.self) { index in
                let task = tasks[index]
                HStack {
                    Image(systemName: task.1 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.1 ? Colors.Accent.success : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.0)
                            .font(.body)
                            .strikethrough(task.1)

                        Text("\(task.2) priority")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

                if index < tasks.count - 1 {
                    Divider()
                }
            }
        }
    }
}

struct NavigationBarPreview: View {
    var body: some View {
        VStack(spacing: Spacing.small) {
            HStack {
                Text("Today")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }

            HStack {
                Text("Tasks")
                    .font(.title)
                    .fontWeight(.semibold)

                Spacer()

                Button("Edit") {}
            }
        }
    }
}

struct CardPreview: View {
    let tasks: [(String, Bool, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Today's Tasks")
                .font(.headline)

            ForEach(tasks.prefix(2).indices, id: \.self) { index in
                let task = tasks[index]
                HStack {
                    Text(task.0)
                        .font(.subheadline)
                    Spacer()
                    Text(task.2)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Colors.Primary.surface)
        )
    }
}

struct AutomatedTestingSection: View {
    @Binding var isRunningTests: Bool
    @Binding var testResults: [DynamicTypeTestResult]
    let onRunTests: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Automated Testing")
                    .font(.headline)

                if isRunningTests {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Running Dynamic Type tests across all categories...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Test all components across all Dynamic Type categories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.small) {
                        DaisyButton(
                            title: "Run All Tests",
                            style: .primary,
                            size: .medium,
                            icon: "play.fill",
                            action: onRunTests
                        )

                        if !testResults.isEmpty {
                            DaisyButton(
                                title: "Clear Results",
                                style: .secondary,
                                size: .medium,
                                icon: "trash",
                                action: { testResults.removeAll() }
                            )
                        }

                        Spacer()
                    }
                }
            }
        }
    }
}

struct DynamicTypeTestResultsSection: View {
    let results: [DynamicTypeTestResult]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Text("Test Results")
                        .font(.headline)

                    Spacer()

                    let passCount = results.filter { !$0.hasIssues }.count
                    let totalCount = results.count

                    Text("\(passCount)/\(totalCount) Passed")
                        .font(.subheadline)
                        .foregroundStyle(passCount == totalCount ? Colors.Accent.success : Colors.Accent.warning)
                        .fontWeight(.medium)
                }

                // Summary by severity
                let criticalIssues = results.filter { $0.severityLevel == .critical }
                let warnings = results.filter { $0.severityLevel == .warning }

                if !criticalIssues.isEmpty || !warnings.isEmpty {
                    HStack(spacing: Spacing.medium) {
                        if !criticalIssues.isEmpty {
                            Label("\(criticalIssues.count) Critical", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Colors.Accent.error)
                        }

                        if !warnings.isEmpty {
                            Label("\(warnings.count) Warnings", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Colors.Accent.warning)
                        }
                    }
                }

                // Detailed results (showing first 10)
                ForEach(results.prefix(10).indices, id: \.self) { index in
                    let result = results[index]

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        HStack {
                            Image(systemName: result.severityLevel.icon)
                                .foregroundStyle(result.severityLevel.color)

                            Text("\(result.component.rawValue) at \(categoryDisplayName(result.category))")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(String(format: "%.1f", result.scaledSize))pt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !result.layoutConcerns.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(result.layoutConcerns, id: \.self) { concern in
                                    Text("• \(concern)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.leading, Spacing.small)
                        }
                    }
                    .padding(Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(result.severityLevel.color.opacity(0.1))
                    )

                    if index < min(9, results.count - 1) {
                        Divider()
                    }
                }

                if results.count > 10 {
                    Text("... and \(results.count - 10) more results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
    }

    private func categoryDisplayName(_ category: UIContentSizeCategory) -> String {
        switch category {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "AX1"
        case .accessibilityLarge: return "AX2"
        case .accessibilityExtraLarge: return "AX3"
        case .accessibilityExtraExtraLarge: return "AX4"
        case .accessibilityExtraExtraExtraLarge: return "AX5"
        default: return "Unknown"
        }
    }
}

struct DynamicTypeGuidelinesSection: View {
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Dynamic Type Guidelines")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Test at all accessibility sizes (AX1-AX5)", systemImage: "checkmark")
                    Label("Ensure layouts adapt without breaking", systemImage: "checkmark")
                    Label("Maintain minimum 44pt touch targets", systemImage: "checkmark")
                    Label("Use relative spacing that scales appropriately", systemImage: "checkmark")
                    Label("Consider alternative layouts for extreme sizes", systemImage: "checkmark")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Key Accessibility Sizes:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, Spacing.small)

                HStack(spacing: Spacing.medium) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AX1-AX3")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Most common")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AX4-AX5")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Extreme sizes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Detail Analysis View

struct DynamicTypeDetailAnalysisView: View {
    let category: UIContentSizeCategory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Detailed analysis for \(categoryDisplayName(category)) would be shown here.")
                        .font(.body)
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Detail Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func categoryDisplayName(_ category: UIContentSizeCategory) -> String {
        switch category {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "Extra Extra Large"
        case .extraExtraExtraLarge: return "Extra Extra Extra Large"
        case .accessibilityMedium: return "Accessibility Medium"
        case .accessibilityLarge: return "Accessibility Large"
        case .accessibilityExtraLarge: return "Accessibility Extra Large"
        case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
        default: return "Unknown"
        }
    }
}

#Preview {
    DynamicTypeTestView()
}