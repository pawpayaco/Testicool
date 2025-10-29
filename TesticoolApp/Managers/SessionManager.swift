//
//  SessionManager.swift
//  Testicool
//
//  Manages cooling session timing and data logging
//
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation
import Combine

/// Manages Testicool cooling session state and timing
class SessionManager: ObservableObject {

    // MARK: - Published Properties

    /// Whether a session is currently active
    @Published var isSessionActive: Bool = false

    /// Session start time
    @Published var startTime: Date?

    /// Target session duration in seconds
    @Published var targetDuration: Int = 1800  // 30 minutes default

    /// Elapsed time in seconds
    @Published var elapsedTime: Int = 0

    /// Remaining time in seconds
    @Published var remainingTime: Int = 1800

    /// Average temperature during session
    @Published var averageTemperature: Double = 0.0

    /// Temperature samples collected
    @Published var temperatureSamples: [(Date, Double)] = []

    /// Pump speed history
    @Published var speedHistory: [(Date, Int)] = []

    // MARK: - Private Properties

    private var sessionTimer: Timer?
    private var pumpController: PumpController?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Empty init
    }

    /// Set pump controller for monitoring
    func setPumpController(_ controller: PumpController) {
        self.pumpController = controller

        // Monitor temperature changes
        controller.$skinTemperature
            .sink { [weak self] temp in
                if temp > 0 {
                    self?.recordTemperature(temp)
                }
            }
            .store(in: &cancellables)

        // Monitor speed changes
        controller.$pumpSpeed
            .sink { [weak self] speed in
                self?.recordSpeed(speed)
            }
            .store(in: &cancellables)
    }

    // MARK: - Session Control

    /// Start a new session
    func startSession(duration: Int = 1800) {
        guard !isSessionActive else { return }

        isSessionActive = true
        startTime = Date()
        targetDuration = duration
        elapsedTime = 0
        remainingTime = duration

        // Clear previous data
        temperatureSamples.removeAll()
        speedHistory.removeAll()
        averageTemperature = 0.0

        // Start timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionTime()
        }

        print("[Session] Started - Duration: \(duration)s")
    }

    /// Pause the session
    func pauseSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        print("[Session] Paused")
    }

    /// Resume the session
    func resumeSession() {
        guard isSessionActive else { return }

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionTime()
        }

        print("[Session] Resumed")
    }

    /// Stop/end the session
    func stopSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false

        print("[Session] Stopped - Elapsed: \(elapsedTime)s")
        print("[Session] Average temp: \(averageTemperature)°C")
        print("[Session] Samples collected: \(temperatureSamples.count)")
    }

    /// Reset session data
    func resetSession() {
        stopSession()
        startTime = nil
        elapsedTime = 0
        remainingTime = targetDuration
        temperatureSamples.removeAll()
        speedHistory.removeAll()
        averageTemperature = 0.0
    }

    // MARK: - Private Methods

    private func updateSessionTime() {
        elapsedTime += 1
        remainingTime = max(0, targetDuration - elapsedTime)

        // Auto-stop when time runs out
        if remainingTime == 0 {
            stopSession()
            pumpController?.turnPumpOff()
        }
    }

    private func recordTemperature(_ temp: Double) {
        guard isSessionActive else { return }

        temperatureSamples.append((Date(), temp))

        // Keep only last 1000 samples to prevent memory issues
        if temperatureSamples.count > 1000 {
            temperatureSamples.removeFirst()
        }

        // Update running average
        let sum = temperatureSamples.reduce(0.0) { $0 + $1.1 }
        averageTemperature = sum / Double(temperatureSamples.count)
    }

    private func recordSpeed(_ speed: Int) {
        guard isSessionActive else { return }

        speedHistory.append((Date(), speed))

        // Keep only last 1000 samples
        if speedHistory.count > 1000 {
            speedHistory.removeFirst()
        }
    }

    // MARK: - Computed Properties

    /// Get formatted elapsed time string
    var formattedElapsedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get formatted remaining time string
    var formattedRemainingTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get session progress (0.0 to 1.0)
    var sessionProgress: Double {
        guard targetDuration > 0 else { return 0.0 }
        return Double(elapsedTime) / Double(targetDuration)
    }

    /// Get average pump duty cycle (percentage)
    var averageDutyCycle: Int {
        guard !speedHistory.isEmpty else { return 0 }

        let sum = speedHistory.reduce(0) { $0 + $1.1 }
        let avgSpeed = Double(sum) / Double(speedHistory.count)
        return Int((avgSpeed / 255.0) * 100.0)
    }

    /// Get session summary
    var sessionSummary: String {
        var summary = "Session Summary\n"
        summary += "===============\n"
        summary += "Duration: \(formattedElapsedTime)\n"
        summary += "Average Temperature: \(String(format: "%.1f°C", averageTemperature))\n"
        summary += "Average Duty Cycle: \(averageDutyCycle)%\n"
        summary += "Samples Collected: \(temperatureSamples.count)\n"

        if let start = startTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            summary += "Start Time: \(formatter.string(from: start))\n"
        }

        return summary
    }

    /// Export session data as CSV
    func exportSessionData() -> String {
        var csv = "Timestamp,Elapsed (s),Temperature (°C),Pump Speed\n"

        let allTimestamps = Set(temperatureSamples.map { $0.0 })
            .union(speedHistory.map { $0.0 })
            .sorted()

        for timestamp in allTimestamps {
            let elapsed = timestamp.timeIntervalSince(startTime ?? timestamp)

            let temp = temperatureSamples.first { abs($0.0.timeIntervalSince(timestamp)) < 1.0 }?.1 ?? 0.0
            let speed = speedHistory.first { abs($0.0.timeIntervalSince(timestamp)) < 1.0 }?.1 ?? 0

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            csv += "\(formatter.string(from: timestamp)),\(Int(elapsed)),\(String(format: "%.1f", temp)),\(speed)\n"
        }

        return csv
    }
}
