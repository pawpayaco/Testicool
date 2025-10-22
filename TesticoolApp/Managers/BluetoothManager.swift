//
//  BluetoothManager.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation
import CoreBluetooth
import Combine

/// Manages Bluetooth connectivity and communication with the Testicool device
class BluetoothManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Current connection status
    @Published var connectionStatus: ConnectionStatus = .disconnected

    /// List of discovered devices
    @Published var discoveredDevices: [DiscoveredDevice] = []

    /// Current device state
    @Published var deviceState = DeviceState()

    /// Whether scanning is in progress
    @Published var isScanning: Bool = false

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?

    // HM-10 BLE Module UUIDs (common default UUIDs)
    // Note: These are the standard HM-10 UUIDs. If your module uses different UUIDs,
    // update these values accordingly.
    private let serviceUUID = CBUUID(string: "FFE0")
    private let txCharacteristicUUID = CBUUID(string: "FFE1") // Device TX (our RX)
    private let rxCharacteristicUUID = CBUUID(string: "FFE1") // Device RX (our TX)

    // Target device name
    private let targetDeviceName = "Testicool_Prototype"

    // Status polling timer
    private var statusTimer: Timer?
    private let statusPollingInterval: TimeInterval = 5.0

    // Received data buffer
    private var receiveBuffer = ""

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Methods

    /// Start scanning for Testicool devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("[BT] Cannot scan - Bluetooth not powered on")
            return
        }

        discoveredDevices.removeAll()
        isScanning = true

        // Scan for devices advertising the HM-10 service
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        print("[BT] Started scanning for devices...")

        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }

    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        print("[BT] Stopped scanning")
    }

    /// Connect to a specific device
    func connect(to device: DiscoveredDevice) {
        stopScanning()
        connectionStatus = .connecting

        print("[BT] Connecting to \(device.name)...")
        centralManager.connect(device.peripheral, options: nil)
    }

    /// Disconnect from the current device
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }

        print("[BT] Disconnecting...")
        stopStatusPolling()
        centralManager.cancelPeripheralConnection(peripheral)
        connectionStatus = .disconnected
        deviceState.reset()
    }

    /// Send a command to the device
    func sendCommand(_ command: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = txCharacteristic,
              peripheral.state == .connected else {
            print("[BT] Cannot send command - not connected")
            return
        }

        // Add newline terminator as per firmware protocol
        let commandWithNewline = command + "\n"

        guard let data = commandWithNewline.data(using: .utf8) else {
            print("[BT] Failed to encode command")
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("[BT] Sent command: \(command)")
    }

    /// Turn pump ON
    func turnPumpOn() {
        sendCommand("ON")
        deviceState.lastControlSource = .app
    }

    /// Turn pump OFF
    func turnPumpOff() {
        sendCommand("OFF")
        deviceState.lastControlSource = .app
    }

    /// Set pump speed (0-255)
    func setPumpSpeed(_ speed: Int) {
        let clampedSpeed = max(0, min(255, speed))
        sendCommand("SPEED:\(clampedSpeed)")
    }

    /// Request status update
    func requestStatus() {
        sendCommand("STATUS")
    }

    /// Request temperature reading
    func requestTemperature() {
        sendCommand("TEMP")
    }

    // MARK: - Private Methods

    private func startStatusPolling() {
        stopStatusPolling()

        statusTimer = Timer.scheduledTimer(withTimeInterval: statusPollingInterval, repeats: true) { [weak self] _ in
            self?.requestStatus()
        }

        // Request initial status immediately
        requestStatus()
        print("[BT] Started status polling (every \(statusPollingInterval)s)")
    }

    private func stopStatusPolling() {
        statusTimer?.invalidate()
        statusTimer = nil
        print("[BT] Stopped status polling")
    }

    private func processReceivedData(_ data: String) {
        // Add to buffer
        receiveBuffer += data

        // Process complete lines (terminated by newline)
        let lines = receiveBuffer.components(separatedBy: "\n")

        // Keep the last incomplete line in the buffer
        receiveBuffer = lines.last ?? ""

        // Process complete lines
        for line in lines.dropLast() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            print("[BT] Received: \(trimmedLine)")
            parseResponse(trimmedLine)
        }
    }

    private func parseResponse(_ response: String) {
        if response.hasPrefix("STATUS:") {
            // Parse status update
            if let status = StatusParser.parseStatus(response) {
                DispatchQueue.main.async {
                    self.deviceState.updateFromStatus(status)
                }
            }
        } else if response.hasPrefix("TEMP:") {
            // Parse temperature (dual format)
            if let temps = StatusParser.parseTemperature(response) {
                DispatchQueue.main.async {
                    if let waterTemp = temps.water {
                        self.deviceState.waterTemperature = waterTemp
                    }
                    if let skinTemp = temps.skin {
                        self.deviceState.skinTemperature = skinTemp
                    }
                }
            }
        } else if response.hasPrefix("PUMP:") {
            // Parse pump state change
            if let state = StatusParser.parsePumpState(response) {
                DispatchQueue.main.async {
                    self.deviceState.isPumpOn = (state == .on)
                }
            }
        } else if response.hasPrefix("MANUAL:") {
            // Manual button was pressed
            if let state = StatusParser.parseManualControl(response) {
                DispatchQueue.main.async {
                    self.deviceState.isPumpOn = (state == .on)
                    self.deviceState.lastControlSource = .manual
                }
            }
        } else if response.hasPrefix("ERROR:") {
            // Parse error
            let errorMessage = StatusParser.parseError(response)
            DispatchQueue.main.async {
                self.deviceState.setError(errorMessage)
            }
        } else if response == "OK" {
            // Command acknowledged
            print("[BT] Command acknowledged")
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("[BT] Bluetooth powered on and ready")
        case .poweredOff:
            print("[BT] Bluetooth is powered off")
            connectionStatus = .disconnected
        case .unsupported:
            print("[BT] Bluetooth not supported on this device")
        case .unauthorized:
            print("[BT] Bluetooth not authorized")
        case .resetting:
            print("[BT] Bluetooth is resetting")
        case .unknown:
            print("[BT] Bluetooth state unknown")
        @unknown default:
            print("[BT] Unknown Bluetooth state")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], rssi RSSI: NSNumber) {

        let deviceName = peripheral.name ?? "Unknown Device"
        print("[BT] Discovered: \(deviceName) (RSSI: \(RSSI))")

        // Create discovered device
        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: deviceName,
            rssi: RSSI.intValue,
            peripheral: peripheral
        )

        // Add to list if not already present
        if !discoveredDevices.contains(where: { $0.id == device.id }) {
            discoveredDevices.append(device)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[BT] Connected to \(peripheral.name ?? "device")")

        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectionStatus = .connected

        // Discover services
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BT] Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        connectionStatus = .disconnected
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[BT] Disconnected: \(error?.localizedDescription ?? "user initiated")")
        connectionStatus = .disconnected
        connectedPeripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
        stopStatusPolling()
        deviceState.reset()
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("[BT] Error discovering services: \(error!.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            print("[BT] Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics([txCharacteristicUUID, rxCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("[BT] Error discovering characteristics: \(error!.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("[BT] Discovered characteristic: \(characteristic.uuid)")

            if characteristic.uuid == txCharacteristicUUID {
                // This is the device's TX (our RX) - enable notifications
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("[BT] Enabled notifications for TX characteristic")
            }

            if characteristic.uuid == rxCharacteristicUUID {
                // This is the device's RX (our TX) - we write to this
                rxCharacteristic = characteristic
                print("[BT] Found RX characteristic for writing")
            }
        }

        // If we have both characteristics, we're ready to communicate
        if txCharacteristic != nil && rxCharacteristic != nil {
            print("[BT] Communication ready - starting status polling")
            startStatusPolling()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("[BT] Error reading characteristic: \(error!.localizedDescription)")
            return
        }

        guard let data = characteristic.value,
              let string = String(data: data, encoding: .utf8) else {
            return
        }

        processReceivedData(string)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[BT] Error writing characteristic: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

/// Connection status enumeration
enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
}

/// Represents a discovered Bluetooth device
struct DiscoveredDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral

    var signalStrength: String {
        if rssi > -50 { return "Excellent" }
        else if rssi > -70 { return "Good" }
        else if rssi > -85 { return "Fair" }
        else { return "Weak" }
    }
}
