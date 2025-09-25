//
//  UIResponseTimeTracker.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import Foundation

/// Specialized utilities for tracking UI response times with minimal performance impact
/// Provides SwiftUI modifiers and utilities to measure interaction response times
struct UIResponseTimeTracker {

    // MARK: - Response Time Measurement

    /// Track response time for button taps
    static func trackButtonTap<T>(
        buttonName: String,
        action: @escaping () -> T
    ) -> () -> T {
        return {
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = action()
            PerformanceMonitor.shared.trackUIResponse(
                eventType: "Button Tap - \(buttonName)",
                startTime: startTime
            )
            return result
        }
    }

    /// Track response time for navigation transitions
    static func trackNavigation(
        from source: String,
        to destination: String,
        startTime: CFAbsoluteTime
    ) {
        PerformanceMonitor.shared.trackUIResponse(
            eventType: "Navigation - \(source) to \(destination)",
            startTime: startTime
        )
    }

    /// Track response time for list operations
    static func trackListOperation(
        operation: String,
        itemCount: Int,
        startTime: CFAbsoluteTime
    ) {
        PerformanceMonitor.shared.trackUIResponse(
            eventType: "List \(operation) - \(itemCount) items",
            startTime: startTime
        )
    }

    /// Track response time for search operations
    static func trackSearchOperation(
        query: String,
        resultCount: Int,
        startTime: CFAbsoluteTime
    ) {
        PerformanceMonitor.shared.trackUIResponse(
            eventType: "Search - '\(query)' (\(resultCount) results)",
            startTime: startTime
        )
    }

    // MARK: - Performance Utilities

    /// Measure time for any operation
    static func measureTime<T>(
        for operationName: String,
        operation: () throws -> T
    ) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        #if DEBUG
        let milliseconds = duration * 1000
        print("⏱️ UIResponseTracker: \(operationName) took \(String(format: "%.1f", milliseconds))ms")
        #endif

        return (result: result, duration: duration)
    }

    /// Check if response time meets target
    static func meetsResponseTimeTarget(_ duration: TimeInterval) -> Bool {
        return duration <= PerformanceMonitor.PerformanceTargets.maxUIResponseTime
    }

    /// Get performance rating for response time
    static func getPerformanceRating(for duration: TimeInterval) -> PerformanceRating {
        let milliseconds = duration * 1000

        switch milliseconds {
        case 0..<50:
            return .excellent
        case 50..<100:
            return .good
        case 100..<200:
            return .acceptable
        case 200..<500:
            return .slow
        default:
            return .unacceptable
        }
    }

    enum PerformanceRating: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case acceptable = "Acceptable"
        case slow = "Slow"
        case unacceptable = "Unacceptable"

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .mint
            case .acceptable: return .yellow
            case .slow: return .orange
            case .unacceptable: return .red
            }
        }

        var description: String {
            switch self {
            case .excellent: return "Under 50ms - Feels instant"
            case .good: return "50-100ms - Very responsive"
            case .acceptable: return "100-200ms - Acceptable response"
            case .slow: return "200-500ms - Noticeably slow"
            case .unacceptable: return "Over 500ms - Unacceptably slow"
            }
        }

        var threshold: TimeInterval {
            switch self {
            case .excellent: return 0.050
            case .good: return 0.100
            case .acceptable: return 0.200
            case .slow: return 0.500
            case .unacceptable: return 1.000
            }
        }
    }
}

// MARK: - SwiftUI View Modifiers

/// Performance tracking view modifiers
extension View {

    /// Track button tap response time
    func trackButtonResponse(buttonName: String) -> some View {
        modifier(ButtonResponseTracker(buttonName: buttonName))
    }

    /// Track navigation response time
    func trackNavigationResponse(from source: String, to destination: String) -> some View {
        modifier(NavigationResponseTracker(source: source, destination: destination))
    }

    /// Track list scrolling performance
    func trackListScrolling() -> some View {
        modifier(ListScrollingTracker())
    }

    /// Track view appearance time
    func trackViewAppearance(viewName: String) -> some View {
        modifier(ViewAppearanceTracker(viewName: viewName))
    }

    /// Track search performance
    func trackSearchPerformance() -> some View {
        modifier(SearchPerformanceTracker())
    }

    /// Track form submission performance
    func trackFormSubmission(formName: String) -> some View {
        modifier(FormSubmissionTracker(formName: formName))
    }
}

// MARK: - View Modifier Implementations

/// Button response time tracking modifier
struct ButtonResponseTracker: ViewModifier {
    let buttonName: String
    @State private var tapStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if tapStartTime == 0 {
                            tapStartTime = CFAbsoluteTimeGetCurrent()
                        }
                    }
                    .onEnded { _ in
                        if tapStartTime > 0 {
                            UIResponseTimeTracker.trackButtonTap(buttonName: buttonName) {}()
                            tapStartTime = 0
                        }
                    }
            )
    }
}

/// Navigation response time tracking modifier
struct NavigationResponseTracker: ViewModifier {
    let source: String
    let destination: String
    @State private var navigationStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .onAppear {
                navigationStartTime = CFAbsoluteTimeGetCurrent()
            }
            .onAppear {
                // Delay to allow view to fully render
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if navigationStartTime > 0 {
                        UIResponseTimeTracker.trackNavigation(
                            from: source,
                            to: destination,
                            startTime: navigationStartTime
                        )
                        navigationStartTime = 0
                    }
                }
            }
    }
}

/// List scrolling performance tracker
struct ListScrollingTracker: ViewModifier {
    @State private var lastScrollTime: CFAbsoluteTime = 0
    @State private var scrollStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        if scrollStartTime == 0 {
                            scrollStartTime = CFAbsoluteTimeGetCurrent()
                        }
                        lastScrollTime = CFAbsoluteTimeGetCurrent()
                    }
                    .onEnded { _ in
                        // Track scroll response after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            if scrollStartTime > 0 {
                                PerformanceMonitor.shared.trackUIResponse(
                                    eventType: "List Scrolling",
                                    startTime: scrollStartTime
                                )
                                scrollStartTime = 0
                            }
                        }
                    }
            )
    }
}

/// View appearance tracking modifier
struct ViewAppearanceTracker: ViewModifier {
    let viewName: String
    @State private var appearanceStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .onAppear {
                appearanceStartTime = CFAbsoluteTimeGetCurrent()
            }
            .onAppear {
                // Allow view to fully render
                DispatchQueue.main.async {
                    if appearanceStartTime > 0 {
                        PerformanceMonitor.shared.trackUIResponse(
                            eventType: "View Appearance - \(viewName)",
                            startTime: appearanceStartTime
                        )
                        appearanceStartTime = 0
                    }
                }
            }
    }
}

/// Search performance tracking modifier
struct SearchPerformanceTracker: ViewModifier {
    @State private var searchStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .onChange(of: true) { _ in
                // This would be connected to actual search text changes
                // For now, it's a placeholder structure
                searchStartTime = CFAbsoluteTimeGetCurrent()
            }
    }
}

/// Form submission tracking modifier
struct FormSubmissionTracker: ViewModifier {
    let formName: String
    @State private var submissionStartTime: CFAbsoluteTime = 0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        submissionStartTime = CFAbsoluteTimeGetCurrent()

                        // Track form submission after brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if submissionStartTime > 0 {
                                PerformanceMonitor.shared.trackUIResponse(
                                    eventType: "Form Submission - \(formName)",
                                    startTime: submissionStartTime
                                )
                                submissionStartTime = 0
                            }
                        }
                    }
            )
    }
}

// MARK: - Response Time Analysis

extension UIResponseTimeTracker {

    /// Analyze response time patterns
    static func analyzeResponseTimePatterns(
        _ events: [PerformanceMonitor.UIResponseEvent]
    ) -> ResponseTimeAnalysis {
        guard !events.isEmpty else {
            return ResponseTimeAnalysis.empty()
        }

        let responseTimes = events.map { $0.responseTime }
        let averageTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        let maxTime = responseTimes.max() ?? 0
        let minTime = responseTimes.min() ?? 0

        let meetsTargetCount = events.filter { $0.meetsTartget }.count
        let targetComplianceRate = Double(meetsTargetCount) / Double(events.count)

        let slowEvents = events.filter { $0.responseTime > 0.2 } // Over 200ms
        let criticalEvents = events.filter { $0.responseTime > 0.5 } // Over 500ms

        return ResponseTimeAnalysis(
            totalEvents: events.count,
            averageResponseTime: averageTime,
            minimumResponseTime: minTime,
            maximumResponseTime: maxTime,
            targetComplianceRate: targetComplianceRate,
            slowEventsCount: slowEvents.count,
            criticalEventsCount: criticalEvents.count,
            overallRating: getPerformanceRating(for: averageTime),
            recommendations: generateRecommendations(for: events)
        )
    }

    private static func generateRecommendations(
        for events: [PerformanceMonitor.UIResponseEvent]
    ) -> [String] {
        var recommendations: [String] = []

        let averageTime = events.map { $0.responseTime }.reduce(0, +) / Double(events.count)
        let slowEvents = events.filter { $0.responseTime > 0.2 }

        if averageTime > 0.1 {
            recommendations.append("Average response time is above target. Consider optimizing UI operations.")
        }

        if slowEvents.count > events.count / 4 {
            recommendations.append("25% of interactions are slow. Review expensive operations in UI thread.")
        }

        let navigationEvents = events.filter { $0.eventType.contains("Navigation") }
        let slowNavigations = navigationEvents.filter { $0.responseTime > 0.3 }
        if slowNavigations.count > 0 {
            recommendations.append("Navigation transitions are slow. Consider preloading data or optimizing view construction.")
        }

        if events.filter({ $0.responseTime > 0.5 }).count > 0 {
            recommendations.append("Some interactions take over 500ms. These should be investigated immediately.")
        }

        return recommendations
    }

    struct ResponseTimeAnalysis {
        let totalEvents: Int
        let averageResponseTime: TimeInterval
        let minimumResponseTime: TimeInterval
        let maximumResponseTime: TimeInterval
        let targetComplianceRate: Double
        let slowEventsCount: Int
        let criticalEventsCount: Int
        let overallRating: PerformanceRating
        let recommendations: [String]

        var isHealthy: Bool {
            return targetComplianceRate > 0.9 && criticalEventsCount == 0
        }

        static func empty() -> ResponseTimeAnalysis {
            return ResponseTimeAnalysis(
                totalEvents: 0,
                averageResponseTime: 0,
                minimumResponseTime: 0,
                maximumResponseTime: 0,
                targetComplianceRate: 1.0,
                slowEventsCount: 0,
                criticalEventsCount: 0,
                overallRating: .excellent,
                recommendations: []
            )
        }
    }
}