//
//  DeviceState.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation

/// Represents the current state of the Testicool device
class DeviceState: ObservableObject {
    // MARK: - Published Properties

    /// Whether the pump is currently running
    @Published var isPumpOn: Bool = false

    /// Current pump speed (0-255 PWM value)
    @Published var pumpSpeed: Int = 180 // Default speed from firmware

    /// Current water temperature in Celsius
    @Published var waterTemperature: Double = 0.0

    /// Current skin temperature in Celsius
    @Published var skinTemperature: Double = 0.0

    /// Runtime in seconds
    @Published var runtimeSeconds: Int = 0

    /// Remaining time in seconds (max 30 minutes = 1800 seconds)
    @Published var remainingSeconds: Int = 1800

    /// Last status update timestamp
    @Published var lastUpdateTime: Date?

    /// Current error message (if any)
    @Published var errorMessage: String?

    /// Whether a safety shutoff has occurred
    @Published var safetyShutoff: Bool = false

    /// Last control source (manual button or app)
    @Published var lastControlSource: ControlSource = .app

    // MARK: - Computed Properties

    /// Pump speed as percentage (0-100%)
    var speedPercentage: Int {
        Int((Double(pumpSpeed) / 255.0) * 100.0)
    }

    /// Formatted runtime string (e.g., "5m 23s")
    var formattedRuntime: String {
        let minutes = runtimeSeconds / 60
        let seconds = runtimeSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    /// Formatted remaining time string
    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    /// Formatted water temperature string
    var formattedWaterTemperature: String {
        String(format: "%.1f°C", waterTemperature)
    }

    /// Formatted skin temperature string
    var formattedSkinTemperature: String {
        String(format: "%.1f°C", skinTemperature)
    }

    /// Progress towards max runtime (0.0 to 1.0)
    var runtimeProgress: Double {
        let maxSeconds = 1800.0 // 30 minutes
        return min(Double(runtimeSeconds) / maxSeconds, 1.0)
    }

    // MARK: - Methods

    /// Reset device state to defaults
    func reset() {
        isPumpOn = false
        pumpSpeed = 180
        waterTemperature = 0.0
        skinTemperature = 0.0
        runtimeSeconds = 0
        remainingSeconds = 1800
        lastUpdateTime = nil
        errorMessage = nil
        safetyShutoff = false
    }

    /// Update state from parsed status data
    func updateFromStatus(_ status: ParsedStatus) {
        isPumpOn = status.state == .on
        pumpSpeed = status.speed
        runtimeSeconds = status.runtimeMinutes * 60
        remainingSeconds = status.remainingMinutes * 60

        if let waterTemp = status.waterTemperature {
            waterTemperature = waterTemp
        }

        if let skinTemp = status.skinTemperature {
            skinTemperature = skinTemp
        }

        lastUpdateTime = Date()
    }

    /// Set error state
    func setError(_ message: String) {
        errorMessage = message
        if message.contains("SAFETY_SHUTOFF") {
            safetyShutoff = true
            isPumpOn = false
        }
        if message.contains("OVERHEAT") {
            safetyShutoff = true
            isPumpOn = false
        }
    }

    /// Clear error state
    func clearError() {
        errorMessage = nil
        safetyShutoff = false
    }
}

// MARK: - Supporting Types

/// Control source for the device
enum ControlSource {
    case app
    case manual
}

/// Parsed pump state
enum PumpState: String {
    case on = "ON"
    case off = "OFF"
}

/// Parsed status data from device
struct ParsedStatus {
    let state: PumpState
    let speed: Int // 0-255
    let runtimeMinutes: Int
    let remainingMinutes: Int
    let waterTemperature: Double?
    let skinTemperature: Double?
}
