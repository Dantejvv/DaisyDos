//
//  MemoryMonitor.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation
import SwiftUI

/// Specialized memory monitoring utilities for detailed memory analysis
/// Works in conjunction with PerformanceMonitor for comprehensive tracking
struct MemoryMonitor {

    // MARK: - Memory Analysis

    /// Get detailed memory information including different types of memory usage
    static func getDetailedMemoryInfo() -> MemoryInfo {
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

        guard kerr == KERN_SUCCESS else {
            return MemoryInfo(
                residentSize: 0,
                virtualSize: 0,
                residentSizeMB: 0,
                virtualSizeMB: 0,
                timestamp: Date()
            )
        }

        let residentSizeMB = Double(info.resident_size) / 1024.0 / 1024.0
        let virtualSizeMB = Double(info.virtual_size) / 1024.0 / 1024.0

        return MemoryInfo(
            residentSize: info.resident_size,
            virtualSize: info.virtual_size,
            residentSizeMB: residentSizeMB,
            virtualSizeMB: virtualSizeMB,
            timestamp: Date()
        )
    }

    /// Monitor memory usage during a specific operation
    static func monitorDuringOperation<T>(
        operationName: String,
        operation: () throws -> T
    ) rethrows -> (result: T, memoryDelta: Double, peakUsage: Double) {
        let startMemory = getDetailedMemoryInfo().residentSizeMB
        var peakUsage = startMemory

        // Monitor memory usage during operation (simplified for demonstration)
        let result = try operation()

        let endMemory = getDetailedMemoryInfo().residentSizeMB
        peakUsage = max(peakUsage, endMemory)

        let memoryDelta = endMemory - startMemory

        // Report to PerformanceMonitor
        if abs(memoryDelta) > 5.0 { // Report significant memory changes (5MB+)
            let message = "Memory change during \(operationName): \(String(format: "%.1f", memoryDelta))MB"
            print("🧠 MemoryMonitor: \(message)")
        }

        return (result: result, memoryDelta: memoryDelta, peakUsage: peakUsage)
    }

    /// Check for potential memory leaks by monitoring growth patterns
    static func detectMemoryLeaks(in history: [PerformanceMonitor.MemorySnapshot]) -> [MemoryLeakWarning] {
        guard history.count >= 10 else { return [] }

        var warnings: [MemoryLeakWarning] = []

        // Check for consistent memory growth over time
        let recentSnapshots = Array(history.suffix(10))
        let oldestUsage = recentSnapshots.first?.memoryUsage ?? 0
        let newestUsage = recentSnapshots.last?.memoryUsage ?? 0
        let growth = newestUsage - oldestUsage

        if growth > 20.0 { // 20MB growth over recent history
            warnings.append(MemoryLeakWarning(
                type: .consistentGrowth,
                severity: growth > 50.0 ? .high : .medium,
                message: "Memory usage has grown by \(String(format: "%.1f", growth))MB recently",
                recommendation: "Monitor for potential memory leaks in recent operations"
            ))
        }

        // Check for sudden memory spikes
        for i in 1..<recentSnapshots.count {
            let previous = recentSnapshots[i-1].memoryUsage
            let current = recentSnapshots[i].memoryUsage
            let spike = current - previous

            if spike > 30.0 { // 30MB sudden increase
                warnings.append(MemoryLeakWarning(
                    type: .memorySpike,
                    severity: spike > 100.0 ? .high : .medium,
                    message: "Memory spike detected: +\(String(format: "%.1f", spike))MB during '\(recentSnapshots[i].event)'",
                    recommendation: "Investigate the operation that caused this memory increase"
                ))
            }
        }

        return warnings
    }

    // MARK: - Memory Optimization Suggestions

    /// Analyze memory usage patterns and provide optimization suggestions
    static func getOptimizationSuggestions(for memoryInfo: MemoryInfo) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []

        if memoryInfo.residentSizeMB > 150.0 {
            suggestions.append(OptimizationSuggestion(
                category: .memoryUsage,
                priority: .high,
                title: "High Memory Usage Detected",
                description: "App is using \(String(format: "%.1f", memoryInfo.residentSizeMB))MB of memory",
                recommendation: "Consider implementing image caching limits or reducing the number of cached objects"
            ))
        }

        if memoryInfo.virtualSizeMB > 1000.0 {
            suggestions.append(OptimizationSuggestion(
                category: .virtualMemory,
                priority: .medium,
                title: "High Virtual Memory Usage",
                description: "Virtual memory usage is \(String(format: "%.1f", memoryInfo.virtualSizeMB))MB",
                recommendation: "Review memory mapping operations and large data structures"
            ))
        }

        return suggestions
    }

    // MARK: - Data Structures

    struct MemoryInfo {
        let residentSize: UInt64  // Physical memory used (bytes)
        let virtualSize: UInt64   // Virtual memory used (bytes)
        let residentSizeMB: Double // Physical memory used (MB)
        let virtualSizeMB: Double  // Virtual memory used (MB)
        let timestamp: Date

        var isHealthy: Bool {
            return residentSizeMB < 100.0 && virtualSizeMB < 500.0
        }

        var statusDescription: String {
            if residentSizeMB > 200.0 {
                return "Critical"
            } else if residentSizeMB > 100.0 {
                return "Warning"
            } else {
                return "Good"
            }
        }

        var statusColor: Color {
            switch statusDescription {
            case "Critical": return .red
            case "Warning": return Color(.systemOrange)
            default: return Color(.systemGreen)
            }
        }
    }

    struct MemoryLeakWarning: Identifiable {
        let id = UUID()
        let type: LeakType
        let severity: Severity
        let message: String
        let recommendation: String

        enum LeakType {
            case consistentGrowth
            case memorySpike
            case unusualPattern
        }

        enum Severity {
            case low, medium, high

            var color: Color {
                switch self {
                case .low: return .yellow
                case .medium: return Color(.systemOrange)
                case .high: return .red
                }
            }
        }
    }

    struct OptimizationSuggestion: Identifiable {
        let id = UUID()
        let category: Category
        let priority: Priority
        let title: String
        let description: String
        let recommendation: String

        enum Category {
            case memoryUsage
            case virtualMemory
            case cachingStrategy
            case dataStructures
        }

        enum Priority {
            case low, medium, high

            var color: Color {
                switch self {
                case .low: return .blue
                case .medium: return Color(.systemOrange)
                case .high: return .red
                }
            }
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Monitor memory usage during view lifecycle
    func monitorMemoryUsage(event: String) -> some View {
        self
            .onAppear {
                let memoryInfo = MemoryMonitor.getDetailedMemoryInfo()
                PerformanceMonitor.shared.getCurrentMemoryUsage()

                #if DEBUG
                print("🧠 Memory Monitor - \(event) appeared: \(String(format: "%.1f", memoryInfo.residentSizeMB))MB")
                #endif
            }
            .onDisappear {
                let memoryInfo = MemoryMonitor.getDetailedMemoryInfo()

                #if DEBUG
                print("🧠 Memory Monitor - \(event) disappeared: \(String(format: "%.1f", memoryInfo.residentSizeMB))MB")
                #endif
            }
    }

    /// Monitor memory usage for expensive operations
    func monitorExpensiveOperation<T>(
        operationName: String,
        operation: @escaping () -> T
    ) -> some View {
        self.onAppear {
            let _ = MemoryMonitor.monitorDuringOperation(operationName: operationName) {
                return operation()
            }
        }
    }
}

// MARK: - Memory Utilities

extension MemoryMonitor {

    /// Format bytes to human-readable string
    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Calculate memory efficiency score (0-100)
    static func calculateEfficiencyScore(for info: MemoryInfo) -> Int {
        let baseScore = 100
        var deductions = 0

        // Deduct points for high memory usage
        if info.residentSizeMB > 50 {
            deductions += Int((info.residentSizeMB - 50) / 2) // 1 point per 2MB over 50MB
        }

        // Deduct points for high virtual memory
        if info.virtualSizeMB > 200 {
            deductions += Int((info.virtualSizeMB - 200) / 10) // 1 point per 10MB over 200MB
        }

        return max(0, baseScore - deductions)
    }

    /// Get memory pressure level
    static func getMemoryPressureLevel(for info: MemoryInfo) -> MemoryPressureLevel {
        if info.residentSizeMB > 200 {
            return .critical
        } else if info.residentSizeMB > 100 {
            return .high
        } else if info.residentSizeMB > 50 {
            return .moderate
        } else {
            return .normal
        }
    }

    enum MemoryPressureLevel: String, CaseIterable {
        case normal = "Normal"
        case moderate = "Moderate"
        case high = "High"
        case critical = "Critical"

        var color: Color {
            switch self {
            case .normal: return Color(.systemGreen)
            case .moderate: return .yellow
            case .high: return Color(.systemOrange)
            case .critical: return .red
            }
        }

        var description: String {
            switch self {
            case .normal: return "Memory usage is within normal limits"
            case .moderate: return "Memory usage is elevated but acceptable"
            case .high: return "Memory usage is high and should be monitored"
            case .critical: return "Memory usage is critically high and needs attention"
            }
        }
    }
}