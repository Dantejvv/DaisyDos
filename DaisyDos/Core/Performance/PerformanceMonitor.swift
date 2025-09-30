//
//  PerformanceMonitor.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation
import SwiftUI

/// Comprehensive performance monitoring system for DaisyDos
/// Tracks launch time, memory usage, UI response times, and provides baseline validation
/// Designed with minimal overhead (<1ms) to avoid impacting app performance
@Observable
class PerformanceMonitor {

    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    // MARK: - Performance Metrics

    /// Launch time tracking
    private(set) var appLaunchStartTime: CFAbsoluteTime = 0
    private(set) var modelContainerInitTime: CFAbsoluteTime = 0
    private(set) var firstViewRenderTime: CFAbsoluteTime = 0
    private(set) var totalLaunchTime: TimeInterval = 0

    /// Memory usage tracking
    private(set) var currentMemoryUsage: Double = 0 // MB
    private(set) var peakMemoryUsage: Double = 0 // MB
    private(set) var memoryUsageHistory: [MemorySnapshot] = []

    /// UI response time tracking
    private(set) var uiResponseTimes: [UIResponseEvent] = []
    private(set) var averageResponseTime: TimeInterval = 0

    /// Performance alerts
    private(set) var performanceAlerts: [PerformanceAlert] = []

    /// Baseline targets
    struct PerformanceTargets {
        static let maxLaunchTime: TimeInterval = 2.0
        static let maxUIResponseTime: TimeInterval = 0.1 // 100ms
        static let maxMemoryUsage: Double = 200 // MB
        static let maxMemoryGrowth: Double = 50 // MB per hour
    }

    // MARK: - Data Structures

    struct MemorySnapshot {
        let timestamp: Date
        let memoryUsage: Double // MB
        let event: String
    }

    struct UIResponseEvent {
        let timestamp: Date
        let eventType: String
        let responseTime: TimeInterval
        let meetsTartget: Bool
    }

    struct PerformanceAlert: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: AlertType
        let message: String
        let severity: Severity

        enum AlertType {
            case launchTime
            case memoryUsage
            case uiResponseTime
            case memoryLeak
        }

        enum Severity {
            case info, warning, critical

            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return Color(.systemOrange)
                case .critical: return .red
                }
            }
        }
    }

    // MARK: - Initialization

    private init() {
        appLaunchStartTime = CFAbsoluteTimeGetCurrent()
        startPerformanceMonitoring()
    }

    // MARK: - Launch Time Monitoring

    /// Mark the start of app launch
    func markAppLaunchStart() {
        appLaunchStartTime = CFAbsoluteTimeGetCurrent()
        addMemorySnapshot(event: "App Launch Start")
    }

    /// Mark ModelContainer initialization complete
    func markModelContainerInitComplete() {
        modelContainerInitTime = CFAbsoluteTimeGetCurrent()
        addMemorySnapshot(event: "ModelContainer Init Complete")
    }

    /// Mark first view render complete
    func markFirstViewRenderComplete() {
        firstViewRenderTime = CFAbsoluteTimeGetCurrent()
        totalLaunchTime = firstViewRenderTime - appLaunchStartTime

        addMemorySnapshot(event: "First View Render Complete")
        validateLaunchTime()
    }

    private func validateLaunchTime() {
        if totalLaunchTime > PerformanceTargets.maxLaunchTime {
            addAlert(
                type: .launchTime,
                message: "Launch time exceeded target: \(String(format: "%.2f", totalLaunchTime))s > \(PerformanceTargets.maxLaunchTime)s",
                severity: .warning
            )
        }
    }

    // MARK: - Memory Monitoring

    /// Get current memory usage in MB
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            currentMemoryUsage = memoryUsageMB

            if memoryUsageMB > peakMemoryUsage {
                peakMemoryUsage = memoryUsageMB
            }

            validateMemoryUsage(memoryUsageMB)
            return memoryUsageMB
        }

        return 0
    }

    private func addMemorySnapshot(event: String) {
        let memoryUsage = getCurrentMemoryUsage()
        let snapshot = MemorySnapshot(
            timestamp: Date(),
            memoryUsage: memoryUsage,
            event: event
        )
        memoryUsageHistory.append(snapshot)

        // Keep only last 100 snapshots to prevent memory bloat
        if memoryUsageHistory.count > 100 {
            memoryUsageHistory.removeFirst(memoryUsageHistory.count - 100)
        }
    }

    private func validateMemoryUsage(_ usage: Double) {
        if usage > PerformanceTargets.maxMemoryUsage {
            addAlert(
                type: .memoryUsage,
                message: "Memory usage exceeded target: \(String(format: "%.1f", usage))MB > \(PerformanceTargets.maxMemoryUsage)MB",
                severity: .warning
            )
        }
    }

    // MARK: - UI Response Time Monitoring

    /// Track a UI response event
    func trackUIResponse(eventType: String, startTime: CFAbsoluteTime) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let responseTime = endTime - startTime
        let meetsTarget = responseTime <= PerformanceTargets.maxUIResponseTime

        let event = UIResponseEvent(
            timestamp: Date(),
            eventType: eventType,
            responseTime: responseTime,
            meetsTartget: meetsTarget
        )

        uiResponseTimes.append(event)

        // Keep only last 100 events
        if uiResponseTimes.count > 100 {
            uiResponseTimes.removeFirst(uiResponseTimes.count - 100)
        }

        updateAverageResponseTime()

        if !meetsTarget {
            addAlert(
                type: .uiResponseTime,
                message: "\(eventType) response time exceeded target: \(String(format: "%.0f", responseTime * 1000))ms > \(Int(PerformanceTargets.maxUIResponseTime * 1000))ms",
                severity: .warning
            )
        }
    }

    private func updateAverageResponseTime() {
        guard !uiResponseTimes.isEmpty else {
            averageResponseTime = 0
            return
        }

        let totalTime = uiResponseTimes.reduce(0) { $0 + $1.responseTime }
        averageResponseTime = uiResponseTimes.count > 0 ? totalTime / Double(uiResponseTimes.count) : 0.0
    }

    // MARK: - Performance Alerts

    private func addAlert(type: PerformanceAlert.AlertType, message: String, severity: PerformanceAlert.Severity) {
        let alert = PerformanceAlert(
            timestamp: Date(),
            type: type,
            message: message,
            severity: severity
        )

        performanceAlerts.append(alert)

        // Keep only last 50 alerts
        if performanceAlerts.count > 50 {
            performanceAlerts.removeFirst(performanceAlerts.count - 50)
        }

        #if DEBUG
        print("🎯 PerformanceMonitor: \(severity.description.uppercased()) - \(message)")
        #endif
    }

    /// Clear all performance alerts
    func clearAlerts() {
        performanceAlerts.removeAll()
    }

    // MARK: - Periodic Monitoring

    private func startPerformanceMonitoring() {
        // Update memory usage every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.addMemorySnapshot(event: "Periodic Check")
        }
    }

    // MARK: - Performance Summary

    /// Get comprehensive performance summary
    func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            launchTime: totalLaunchTime,
            launchTimeMeetsTarget: totalLaunchTime <= PerformanceTargets.maxLaunchTime,
            currentMemoryUsage: currentMemoryUsage,
            peakMemoryUsage: peakMemoryUsage,
            memoryMeetsTarget: peakMemoryUsage <= PerformanceTargets.maxMemoryUsage,
            averageUIResponseTime: averageResponseTime,
            uiResponseMeetsTarget: averageResponseTime <= PerformanceTargets.maxUIResponseTime,
            totalAlerts: performanceAlerts.count,
            criticalAlerts: performanceAlerts.filter { $0.severity == .critical }.count
        )
    }

    struct PerformanceSummary {
        let launchTime: TimeInterval
        let launchTimeMeetsTarget: Bool
        let currentMemoryUsage: Double
        let peakMemoryUsage: Double
        let memoryMeetsTarget: Bool
        let averageUIResponseTime: TimeInterval
        let uiResponseMeetsTarget: Bool
        let totalAlerts: Int
        let criticalAlerts: Int

        var overallHealthy: Bool {
            return launchTimeMeetsTarget && memoryMeetsTarget && uiResponseMeetsTarget && criticalAlerts == 0
        }
    }

    // MARK: - Data Export

    /// Export performance data as CSV for analysis
    func exportPerformanceData() -> String {
        var csv = "Timestamp,Event Type,Value,Unit,Target Met\n"

        // Launch time
        csv += "\(Date()),Launch Time,\(totalLaunchTime),seconds,\(totalLaunchTime <= PerformanceTargets.maxLaunchTime)\n"

        // Memory snapshots
        for snapshot in memoryUsageHistory.suffix(20) {
            csv += "\(snapshot.timestamp),Memory Usage - \(snapshot.event),\(snapshot.memoryUsage),MB,\(snapshot.memoryUsage <= PerformanceTargets.maxMemoryUsage)\n"
        }

        // UI response times
        for event in uiResponseTimes.suffix(20) {
            csv += "\(event.timestamp),UI Response - \(event.eventType),\(event.responseTime * 1000),ms,\(event.meetsTartget)\n"
        }

        return csv
    }

    // MARK: - Reset Methods

    /// Reset all performance data (useful for testing)
    func resetAllData() {
        memoryUsageHistory.removeAll()
        uiResponseTimes.removeAll()
        performanceAlerts.removeAll()
        currentMemoryUsage = 0
        peakMemoryUsage = 0
        averageResponseTime = 0
        totalLaunchTime = 0
    }
}

// MARK: - Extensions

extension PerformanceMonitor.PerformanceAlert.Severity {
    var description: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Track UI response time for any view interaction
    func trackResponseTime(eventType: String) -> some View {
        let startTime = CFAbsoluteTimeGetCurrent()
        return self.onTapGesture {
            PerformanceMonitor.shared.trackUIResponse(eventType: eventType, startTime: startTime)
        }
    }
}