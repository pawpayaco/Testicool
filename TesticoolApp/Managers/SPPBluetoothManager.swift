//
//  SPPBluetoothManager.swift
//  Testicool
//
//  Classic Bluetooth SPP (Serial Port Profile) Manager for KS-03/JDY-31 modules
//  Replaces CoreBluetooth BLE with ExternalAccessory framework
//
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation
import ExternalAccessory
import Combine

/// Manages Classic Bluetooth SPP connection to KS-03/JDY-31 modules
class SPPBluetoothManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Current connection status
    @Published var connectionStatus: ConnectionStatus = .disconnected

    /// List of discovered/available accessories
    @Published var discoveredDevices: [EAAccessory] = []

    /// Whether currently scanning for devices
    @Published var isScanning: Bool = false

    /// Received data buffer for debugging
    @Published var receivedLines: [String] = []

    // MARK: - Private Properties

    private var currentAccessory: EAAccessory?
    private var session: EASession?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    private var inputBuffer = Data()
    private var cancellables = Set<AnyCancellable>()

    // Protocol strings to match (these should be in Info.plist)
    private let supportedProtocols = [
        "com.ks03.bluetooth",
        "com.jdy31.bluetooth",
        "com.dsdtech.bluetooth",
        "com.serialportprofile"
    ]

    // Target device name patterns
    private let targetDevicePatterns = ["KS03", "JDY", "DSD TECH", "Testicool"]

    // MARK: - Publishers

    let lineReceived = PassthroughSubject<String, Never>()

    // MARK: - Initialization

    override init() {
        super.init()
        setupNotifications()
        checkForConnectedAccessories()
    }

    deinit {
        disconnect()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupNotifications() {
        // Listen for accessory connections/disconnections
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryConnected(_:)),
            name: .EAAccessoryDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessoryDisconnected(_:)),
            name: .EAAccessoryDidDisconnect,
            object: nil
        )

        // Register for accessory notifications
        EAAccessoryManager.shared().registerForLocalNotifications()

        print("[SPP] Notifications registered")
    }

    // MARK: - Public Methods

    /// Start scanning for accessories
    func startScanning() {
        isScanning = true
        checkForConnectedAccessories()

        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }

        print("[SPP] Started scanning for accessories")
    }

    /// Stop scanning
    func stopScanning() {
        isScanning = false
        print("[SPP] Stopped scanning")
    }

    /// Check for already connected accessories
    private func checkForConnectedAccessories() {
        let accessories = EAAccessoryManager.shared().connectedAccessories

        DispatchQueue.main.async { [weak self] in
            self?.discoveredDevices = accessories.filter { accessory in
                // Filter for our target devices
                let matchesName = self?.targetDevicePatterns.contains(where: { pattern in
                    accessory.name.contains(pattern)
                }) ?? false

                let hasProtocol = accessory.protocolStrings.contains(where: { proto in
                    self?.supportedProtocols.contains(proto) ?? false
                })

                return matchesName || hasProtocol || !accessories.isEmpty // Show all if nothing matches
            }

            print("[SPP] Found \(self?.discoveredDevices.count ?? 0) accessories")

            // Auto-connect to first matching device
            if let firstDevice = self?.discoveredDevices.first, self?.currentAccessory == nil {
                print("[SPP] Auto-connecting to: \(firstDevice.name)")
                self?.connect(to: firstDevice)
            }
        }
    }

    /// Connect to a specific accessory
    func connect(to accessory: EAAccessory) {
        stopScanning()

        guard accessory.isConnected else {
            print("[SPP] Accessory not connected to system")
            return
        }

        // Find a supported protocol
        guard let protocolString = accessory.protocolStrings.first(where: { proto in
            supportedProtocols.contains(proto)
        }) ?? accessory.protocolStrings.first else {
            print("[SPP] No supported protocol found. Available: \(accessory.protocolStrings)")
            // Try first available protocol anyway
            if let firstProto = accessory.protocolStrings.first {
                openSession(for: accessory, protocol: firstProto)
            }
            return
        }

        openSession(for: accessory, protocol: protocolString)
    }

    /// Open session with accessory
    private func openSession(for accessory: EAAccessory, protocol protocolString: String) {
        connectionStatus = .connecting
        currentAccessory = accessory

        guard let newSession = EASession(accessory: accessory, forProtocol: protocolString) else {
            print("[SPP] Failed to create session with protocol: \(protocolString)")
            connectionStatus = .disconnected
            return
        }

        session = newSession
        inputStream = newSession.inputStream
        outputStream = newSession.outputStream

        // Configure streams
        inputStream?.delegate = self
        outputStream?.delegate = self

        inputStream?.schedule(in: .current, forMode: .default)
        outputStream?.schedule(in: .current, forMode: .default)

        inputStream?.open()
        outputStream?.open()

        connectionStatus = .connected

        print("[SPP] Connected to: \(accessory.name)")
        print("[SPP] Protocol: \(protocolString)")
        print("[SPP] Manufacturer: \(accessory.manufacturer)")
        print("[SPP] Model: \(accessory.modelNumber)")

        // Send initial HELLO to verify connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendCommand("STATUS")
        }
    }

    /// Disconnect from current accessory
    func disconnect() {
        print("[SPP] Disconnecting...")

        inputStream?.close()
        outputStream?.close()

        inputStream?.remove(from: .current, forMode: .default)
        outputStream?.remove(from: .current, forMode: .default)

        inputStream = nil
        outputStream = nil
        session = nil
        currentAccessory = nil

        connectionStatus = .disconnected
        inputBuffer.removeAll()
    }

    /// Send command to device
    func sendCommand(_ command: String) {
        guard let outputStream = outputStream,
              outputStream.hasSpaceAvailable else {
            print("[SPP] Cannot send - output stream not available")
            return
        }

        let commandWithNewline = command + "\n"
        guard let data = commandWithNewline.data(using: .utf8) else {
            print("[SPP] Failed to encode command")
            return
        }

        let bytesWritten = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Int in
            guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            return outputStream.write(pointer, maxLength: buffer.count)
        }

        if bytesWritten > 0 {
            print("[SPP] Sent: \(command)")
        } else {
            print("[SPP] Failed to send: \(command)")
        }
    }

    // MARK: - Notification Handlers

    @objc private func accessoryConnected(_ notification: Notification) {
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
            return
        }

        print("[SPP] Accessory connected: \(accessory.name)")
        checkForConnectedAccessories()
    }

    @objc private func accessoryDisconnected(_ notification: Notification) {
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else {
            return
        }

        print("[SPP] Accessory disconnected: \(accessory.name)")

        if accessory.connectionID == currentAccessory?.connectionID {
            disconnect()
        }

        checkForConnectedAccessories()
    }

    // MARK: - Stream Reading

    private func readAvailableData() {
        guard let inputStream = inputStream else { return }

        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)

            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                inputBuffer.append(data)
                processInputBuffer()
            } else if bytesRead < 0 {
                print("[SPP] Error reading from stream: \(inputStream.streamError?.localizedDescription ?? "unknown")")
                break
            }
        }
    }

    private func processInputBuffer() {
        guard let string = String(data: inputBuffer, encoding: .utf8) else {
            return
        }

        let lines = string.components(separatedBy: "\n")

        // Keep the last incomplete line in buffer
        if let lastLine = lines.last, !lastLine.isEmpty {
            if let lastLineData = lastLine.data(using: .utf8) {
                inputBuffer = lastLineData
            }
        } else {
            inputBuffer.removeAll()
        }

        // Process complete lines
        for line in lines.dropLast() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            DispatchQueue.main.async { [weak self] in
                self?.receivedLines.append(trimmedLine)
                if self?.receivedLines.count ?? 0 > 100 {
                    self?.receivedLines.removeFirst()
                }

                self?.lineReceived.send(trimmedLine)
                print("[SPP] Received: \(trimmedLine)")
            }
        }
    }
}

// MARK: - StreamDelegate

extension SPPBluetoothManager: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print("[SPP] Stream opened: \(aStream == inputStream ? "input" : "output")")

        case .hasBytesAvailable:
            if aStream == inputStream {
                readAvailableData()
            }

        case .hasSpaceAvailable:
            if aStream == outputStream {
                // Ready to write
            }

        case .errorOccurred:
            print("[SPP] Stream error: \(aStream.streamError?.localizedDescription ?? "unknown")")
            if connectionStatus == .connected {
                DispatchQueue.main.async { [weak self] in
                    self?.disconnect()
                }
            }

        case .endEncountered:
            print("[SPP] Stream ended")
            DispatchQueue.main.async { [weak self] in
                self?.disconnect()
            }

        default:
            break
        }
    }
}

// Note: ConnectionStatus enum is defined in BluetoothManager.swift
// We reuse the same enum to avoid duplication
