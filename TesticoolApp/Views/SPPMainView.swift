//
//  SPPMainView.swift
//  Testicool
//
//  Main view for SPP Bluetooth control interface
//
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI
import ExternalAccessory

struct SPPMainView: View {
    @StateObject private var bluetoothManager = SPPBluetoothManager()
    @StateObject private var pumpController: PumpController
    @StateObject private var sessionManager = SessionManager()

    @State private var showDeviceList = false
    @State private var showDebugConsole = false
    @State private var showSessionSummary = false

    init() {
        let btManager = SPPBluetoothManager()
        _bluetoothManager = StateObject(wrappedValue: btManager)

        let pump = PumpController(bluetoothManager: btManager)
        _pumpController = StateObject(wrappedValue: pump)
    }

    var body: some View {
        NavigationView {
            Group {
                if bluetoothManager.connectionStatus == .connected {
                    connectedView
                } else {
                    disconnectedView
                }
            }
            .navigationTitle("Testicool SPP")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showDebugConsole = true }) {
                            Label("Debug Console", systemImage: "terminal")
                        }

                        if sessionManager.isSessionActive {
                            Button(action: { showSessionSummary = true }) {
                                Label("Session Summary", systemImage: "chart.bar")
                            }
                        }

                        Divider()

                        if bluetoothManager.connectionStatus == .connected {
                            Button(role: .destructive, action: {
                                bluetoothManager.disconnect()
                            }) {
                                Label("Disconnect", systemImage: "wifi.slash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showDeviceList) {
                SPPDeviceListView(bluetoothManager: bluetoothManager, isPresented: $showDeviceList)
            }
            .sheet(isPresented: $showDebugConsole) {
                DebugConsoleView(bluetoothManager: bluetoothManager, pumpController: pumpController)
            }
            .sheet(isPresented: $showSessionSummary) {
                SessionSummaryView(sessionManager: sessionManager)
            }
        }
        .onAppear {
            sessionManager.setPumpController(pumpController)
            bluetoothManager.startScanning()
        }
    }

    // MARK: - Connected View

    private var connectedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Status
                connectionStatusCard

                // Temperature Display
                temperatureCard

                // Pump Control
                pumpControlCard

                // Session Control
                sessionControlCard

                // Session Stats
                if sessionManager.isSessionActive {
                    sessionStatsCard
                }
            }
            .padding()
        }
    }

    // MARK: - Disconnected View

    private var disconnectedView: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "snowflake")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Testicool")
                .font(.system(size: 36, weight: .bold))

            Text("Classic Bluetooth SPP")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 15) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)

                Text(bluetoothManager.connectionStatus.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                bluetoothManager.startScanning()
                showDeviceList = true
            }) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Connect to Device")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Card Views

    private var connectionStatusCard: some View {
        HStack {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)

            Text("Connected")
                .font(.system(size: 14, weight: .medium))

            Spacer()

            if let accessory = bluetoothManager.discoveredDevices.first {
                Text(accessory.name)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    private var temperatureCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Temperature")
                .font(.system(size: 18, weight: .semibold))

            HStack(spacing: 20) {
                // Water Temperature
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Water")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Text(pumpController.formattedWaterTemperature)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }

                Spacer()

                // Skin Temperature
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.orange)
                        Text("Skin")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Text(pumpController.formattedSkinTemperature)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    private var pumpControlCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Pump Control")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { pumpController.isPumpOn },
                    set: { newValue in
                        if newValue {
                            pumpController.turnPumpOn()
                        } else {
                            pumpController.turnPumpOff()
                        }
                    }
                ))
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speed")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(pumpController.pumpSpeedPercentage)%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Slider(
                    value: Binding(
                        get: { Double(pumpController.pumpSpeed) },
                        set: { pumpController.setSpeed(Int($0)) }
                    ),
                    in: 0...255,
                    step: 1
                )
                .disabled(!pumpController.isPumpOn)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    private var sessionControlCard: some View {
        VStack(spacing: 15) {
            if sessionManager.isSessionActive {
                // Active session controls
                HStack(spacing: 15) {
                    Button(action: {
                        sessionManager.pauseSession()
                    }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        sessionManager.stopSession()
                        pumpController.turnPumpOff()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                // Start session button
                Button(action: {
                    sessionManager.startSession()
                    pumpController.turnPumpOn()
                }) {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }

    private var sessionStatsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Session Progress")
                .font(.system(size: 18, weight: .semibold))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * sessionManager.sessionProgress, height: 8)
                }
            }
            .frame(height: 8)

            // Time stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Elapsed")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(sessionManager.formattedElapsedTime)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(sessionManager.formattedRemainingTime)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                }
            }

            Divider()

            // Averages
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Temperature")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f°C", sessionManager.averageTemperature))
                        .font(.system(size: 16, weight: .semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Duty Cycle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("\(sessionManager.averageDutyCycle)%")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
}

// MARK: - Device List View

struct SPPDeviceListView: View {
    @ObservedObject var bluetoothManager: SPPBluetoothManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                if bluetoothManager.discoveredDevices.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No devices found")
                            .font(.system(size: 18, weight: .medium))

                        Text("Make sure your Testicool device is paired in iOS Settings → Bluetooth")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(bluetoothManager.discoveredDevices, id: \.connectionID) { accessory in
                        Button(action: {
                            bluetoothManager.connect(to: accessory)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(accessory.name)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(accessory.manufacturer)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Available Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        bluetoothManager.stopScanning()
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if bluetoothManager.isScanning {
                        ProgressView()
                    } else {
                        Button(action: {
                            bluetoothManager.startScanning()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Debug Console View

struct DebugConsoleView: View {
    @ObservedObject var bluetoothManager: SPPBluetoothManager
    @ObservedObject var pumpController: PumpController

    @State private var commandText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Received lines log
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(bluetoothManager.receivedLines.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.green)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .background(Color.black)
                    .onChange(of: bluetoothManager.receivedLines.count) { _ in
                        if let lastIndex = bluetoothManager.receivedLines.indices.last {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Command input
                HStack {
                    TextField("Enter command", text: $commandText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.allCharacters)
                        .onSubmit {
                            sendCommand()
                        }

                    Button("Send") {
                        sendCommand()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                // Quick command buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickCommandButton("ON")
                        quickCommandButton("OFF")
                        quickCommandButton("STATUS")
                        quickCommandButton("TEMP")
                        quickCommandButton("SPEED:128")
                        quickCommandButton("SPEED:255")
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func quickCommandButton(_ command: String) -> some View {
        Button(command) {
            bluetoothManager.sendCommand(command)
        }
        .buttonStyle(.bordered)
        .font(.system(size: 12, design: .monospaced))
    }

    private func sendCommand() {
        guard !commandText.isEmpty else { return }
        bluetoothManager.sendCommand(commandText)
        commandText = ""
    }
}

// MARK: - Session Summary View

struct SessionSummaryView: View {
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(sessionManager.sessionSummary)
                        .font(.system(size: 14, design: .monospaced))
                        .padding()

                    Button(action: exportData) {
                        Label("Export Session Data", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportData() {
        let csv = sessionManager.exportSessionData()
        let activityController = UIActivityViewController(
            activityItems: [csv],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityController, animated: true)
        }
    }
}

// MARK: - Preview

struct SPPMainView_Previews: PreviewProvider {
    static var previews: some View {
        SPPMainView()
    }
}
