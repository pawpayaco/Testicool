//
//  PumpController.swift
//  Testicool
//
//  High-level pump control interface with command protocol
//
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation
import Combine

/// Controls the Testicool pump via SPP Bluetooth commands
class PumpController: ObservableObject {

    // MARK: - Published Properties

    /// Whether pump is currently ON
    @Published var isPumpOn: Bool = false

    /// Current pump speed (0-255)
    @Published var pumpSpeed: Int = 180

    /// Water temperature (°C)
    @Published var waterTemperature: Double = 0.0

    /// Skin temperature (°C)
    @Published var skinTemperature: Double = 0.0

    /// Last error message
    @Published var lastError: String?

    /// Runtime in seconds
    @Published var runtimeSeconds: Int = 0

    /// Remaining time in seconds
    @Published var remainingSeconds: Int = 1800  // Default 30 min

    // MARK: - Private Properties

    private let bluetoothManager: SPPBluetoothManager
    private var cancellables = Set<AnyCancellable>()

    private var temperatureTimer: Timer?
    private var statusTimer: Timer?

    // MARK: - Initialization

    init(bluetoothManager: SPPBluetoothManager) {
        self.bluetoothManager = bluetoothManager
        setupResponseHandling()
    }

    deinit {
        stopPeriodicUpdates()
    }

    // MARK: - Setup

    private func setupResponseHandling() {
        bluetoothManager.lineReceived
            .sink { [weak self] line in
                self?.parseResponse(line)
            }
            .store(in: &cancellables)

        // Monitor connection status
        bluetoothManager.$connectionStatus
            .sink { [weak self] status in
                if status == .connected {
                    self?.startPeriodicUpdates()
                } else {
                    self?.stopPeriodicUpdates()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Turn pump ON
    func turnPumpOn() {
        bluetoothManager.sendCommand("ON")
        isPumpOn = true  // Optimistic update
    }

    /// Turn pump OFF
    func turnPumpOff() {
        bluetoothManager.sendCommand("OFF")
        isPumpOn = false  // Optimistic update
    }

    /// Set pump speed (0-255)
    func setSpeed(_ speed: Int) {
        let clampedSpeed = max(0, min(255, speed))
        bluetoothManager.sendCommand("SPEED:\(clampedSpeed)")
        pumpSpeed = clampedSpeed  // Optimistic update
    }

    /// Request temperature reading
    func requestTemperature() {
        bluetoothManager.sendCommand("TEMP")
    }

    /// Request status update
    func requestStatus() {
        bluetoothManager.sendCommand("STATUS")
    }

    // MARK: - Periodic Updates

    private func startPeriodicUpdates() {
        stopPeriodicUpdates()

        // Request temperature every 1 second
        temperatureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.requestTemperature()
        }

        // Request status every 5 seconds
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.requestStatus()
        }

        // Request initial updates
        requestTemperature()
        requestStatus()

        print("[PumpController] Started periodic updates")
    }

    private func stopPeriodicUpdates() {
        temperatureTimer?.invalidate()
        statusTimer?.invalidate()
        temperatureTimer = nil
        statusTimer = nil

        print("[PumpController] Stopped periodic updates")
    }

    // MARK: - Response Parsing

    private func parseResponse(_ response: String) {
        // OK response
        if response == "OK" {
            print("[PumpController] Command acknowledged")
            return
        }

        // ERROR response
        if response.hasPrefix("ERROR:") {
            let errorMessage = response.replacingOccurrences(of: "ERROR:", with: "")
            DispatchQueue.main.async { [weak self] in
                self?.lastError = errorMessage
            }
            print("[PumpController] Error: \(errorMessage)")
            return
        }

        // PUMP state change
        if response.hasPrefix("PUMP:") {
            if response.contains("ON") {
                DispatchQueue.main.async { [weak self] in
                    self?.isPumpOn = true
                }
            } else if response.contains("OFF") {
                DispatchQueue.main.async { [weak self] in
                    self?.isPumpOn = false
                }
            }
            return
        }

        // MANUAL control
        if response.hasPrefix("MANUAL:") {
            if response.contains("ON") {
                DispatchQueue.main.async { [weak self] in
                    self?.isPumpOn = true
                }
            } else if response.contains("OFF") {
                DispatchQueue.main.async { [weak self] in
                    self?.isPumpOn = false
                }
            }
            return
        }

        // TEMP response - dual format: TEMP:{Water:10.0C,Skin:34.5C}
        if response.hasPrefix("TEMP:") {
            parseTemperatureResponse(response)
            return
        }

        // STATUS response - STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,WaterTemp:10.0C,SkinTemp:34.5C}
        if response.hasPrefix("STATUS:") {
            parseStatusResponse(response)
            return
        }

        // HELLO message
        if response.hasPrefix("HELLO:") {
            print("[PumpController] Device ready: \(response)")
            return
        }

        print("[PumpController] Unknown response: \(response)")
    }

    private func parseTemperatureResponse(_ response: String) {
        // Format: TEMP:{Water:10.0C,Skin:34.5C}
        let cleaned = response
            .replacingOccurrences(of: "TEMP:", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")

        let pairs = cleaned.split(separator: ",")

        for pair in pairs {
            let keyValue = pair.split(separator: ":")
            guard keyValue.count == 2 else { continue }

            let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
            let value = String(keyValue[1])
                .replacingOccurrences(of: "C", with: "")
                .trimmingCharacters(in: .whitespaces)

            if let temp = Double(value) {
                DispatchQueue.main.async { [weak self] in
                    if key == "Water" {
                        self?.waterTemperature = temp
                    } else if key == "Skin" {
                        self?.skinTemperature = temp
                    }
                }
            }
        }
    }

    private func parseStatusResponse(_ response: String) {
        // Format: STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,WaterTemp:10.0C,SkinTemp:34.5C}
        let cleaned = response
            .replacingOccurrences(of: "STATUS:", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")

        let pairs = cleaned.split(separator: ",")

        for pair in pairs {
            let keyValue = pair.split(separator: ":")
            guard keyValue.count == 2 else { continue }

            let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
            let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)

            DispatchQueue.main.async { [weak self] in
                switch key {
                case "State":
                    self?.isPumpOn = (value == "ON")

                case "Speed":
                    // Convert percentage to 0-255
                    let percentString = value.replacingOccurrences(of: "%", with: "")
                    if let percent = Int(percentString) {
                        self?.pumpSpeed = Int((Double(percent) / 100.0) * 255.0)
                    }

                case "Runtime":
                    // Parse "5m" -> 300 seconds
                    let timeString = value.replacingOccurrences(of: "m", with: "")
                    if let minutes = Int(timeString) {
                        self?.runtimeSeconds = minutes * 60
                    }

                case "Remaining":
                    // Parse "25m" -> 1500 seconds
                    let timeString = value.replacingOccurrences(of: "m", with: "")
                    if let minutes = Int(timeString) {
                        self?.remainingSeconds = minutes * 60
                    }

                case "WaterTemp":
                    let tempString = value.replacingOccurrences(of: "C", with: "")
                    if let temp = Double(tempString) {
                        self?.waterTemperature = temp
                    }

                case "SkinTemp":
                    let tempString = value.replacingOccurrences(of: "C", with: "")
                    if let temp = Double(tempString) {
                        self?.skinTemperature = temp
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Get formatted water temperature string
    var formattedWaterTemperature: String {
        String(format: "%.1f°C", waterTemperature)
    }

    /// Get formatted skin temperature string
    var formattedSkinTemperature: String {
        String(format: "%.1f°C", skinTemperature)
    }

    /// Get formatted runtime string
    var formattedRuntime: String {
        let minutes = runtimeSeconds / 60
        let seconds = runtimeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get formatted remaining time string
    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Get pump speed as percentage (0-100)
    var pumpSpeedPercentage: Int {
        Int((Double(pumpSpeed) / 255.0) * 100.0)
    }
}
