//
//  NetworkMonitor.swift
//  DaisyDos
//
//  Created by Claude Code on 12/08/25.
//

import Foundation
import Network

@Observable
class NetworkMonitor {

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.daisydos.networkmonitor")

    /// Current network connectivity status
    var isConnected: Bool = true

    /// Current connection type
    var connectionType: ConnectionType = .unknown

    /// Network path status
    var pathStatus: NWPath.Status = .requiresConnection

    // MARK: - Connection Type

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown

        var displayText: String {
            switch self {
            case .wifi:
                return "Wi-Fi"
            case .cellular:
                return "Cellular"
            case .wired:
                return "Wired"
            case .unknown:
                return "Unknown"
            }
        }
    }

    // MARK: - Initialization

    init() {
        startMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.pathStatus = path.status
                self?.isConnected = path.status == .satisfied

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wired
                } else {
                    self?.connectionType = .unknown
                }

                #if DEBUG
                let status = path.status == .satisfied ? "Connected" : "Disconnected"
                let type = self?.connectionType.displayText ?? "Unknown"
                print("📡 Network status: \(status) via \(type)")
                #endif
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Convenience Methods

    /// Whether the device is online and can sync
    var canSync: Bool {
        return isConnected
    }

    /// Network status description for UI
    var statusDescription: String {
        if isConnected {
            return "Online (\(connectionType.displayText))"
        } else {
            return "Offline"
        }
    }

    deinit {
        stopMonitoring()
    }
}
