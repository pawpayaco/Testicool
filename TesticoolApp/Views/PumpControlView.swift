//
//  PumpControlView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI
import Combine

struct PumpControlView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header with disconnect button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)

                        if let lastUpdate = bluetoothManager.deviceState.lastUpdateTime {
                            Text("Last update: \(lastUpdate, style: .relative) ago")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: {
                        bluetoothManager.disconnect()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Disconnect")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Error banner (if any)
                if let error = bluetoothManager.deviceState.errorMessage {
                    ErrorBanner(message: error) {
                        bluetoothManager.deviceState.clearError()
                    }
                    .padding(.horizontal, 20)
                }

                // Main ON/OFF Control
                PumpControlCard()
                    .padding(.horizontal, 20)

                // Speed Control
                SpeedControlCard()
                    .padding(.horizontal, 20)

                // Status Display
                StatusView()
                    .padding(.horizontal, 20)

                // Water Temperature Display
                WaterTemperatureCard()
                    .padding(.horizontal, 20)

                // Skin Temperature Display
                SkinTemperatureCard()
                    .padding(.horizontal, 20)

                Spacer(minLength: 30)
            }
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Pump Control Card

struct PumpControlCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isPumpOn: Bool = false
    @State private var refreshTrigger = UUID()

    var body: some View {
        VStack(spacing: 20) {
            // Pump state text - FORCE REFRESH
            Text(isPumpOn ? "Pump Running" : "Pump Off")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isPumpOn ? .green : .secondary)
                .id(refreshTrigger)

            // Big ON/OFF button
            Button(action: {
                if bluetoothManager.deviceState.isPumpOn {
                    bluetoothManager.turnPumpOff()
                } else {
                    bluetoothManager.turnPumpOn()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isPumpOn ? Color.red : Color.green)
                        .frame(width: 150, height: 150)
                        .shadow(
                            color: (isPumpOn ? Color.red : Color.green).opacity(0.4),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                    VStack(spacing: 8) {
                        Image(systemName: isPumpOn ? "stop.fill" : "power")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)

                        Text(isPumpOn ? "TURN OFF" : "TURN ON")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(bluetoothManager.deviceState.safetyShutoff)
            .id(refreshTrigger)

            // Control source indicator
            if bluetoothManager.deviceState.lastControlSource == .manual {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                    Text("Controlled via Manual Button")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            isPumpOn = bluetoothManager.deviceState.isPumpOn
        }
        .onChange(of: bluetoothManager.deviceState.isPumpOn) { newValue in
            print("[PumpControlCard] isPumpOn changed: \(isPumpOn) -> \(newValue)")
            isPumpOn = newValue
            refreshTrigger = UUID()
        }
        .onChange(of: bluetoothManager.deviceState.refreshID) { _ in
            isPumpOn = bluetoothManager.deviceState.isPumpOn
            refreshTrigger = UUID()
        }
    }
}

// MARK: - Speed Control Card

struct SpeedControlCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var tempSpeed: Double = 180
    @State private var isEditing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "speedometer")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("Pump Speed")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(Int((tempSpeed / 255.0) * 100.0))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
            }

            // Speed slider
            VStack(spacing: 10) {
                Slider(
                    value: $tempSpeed,
                    in: 0...255,
                    step: 1,
                    onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            bluetoothManager.setPumpSpeed(Int(tempSpeed))
                        }
                    }
                )
                .accentColor(.blue)
                .disabled(!bluetoothManager.deviceState.isPumpOn)

                HStack {
                    Text("0%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("50%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("100%")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            if !bluetoothManager.deviceState.isPumpOn {
                Text("Turn pump on to adjust speed")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            tempSpeed = Double(bluetoothManager.deviceState.pumpSpeed)
        }
        .onChange(of: bluetoothManager.deviceState.pumpSpeed) { newSpeed in
            if !isEditing {
                tempSpeed = Double(newSpeed)
            }
        }
    }
}

// MARK: - Water Temperature Card

struct WaterTemperatureCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var displayTemp: Double = 0.0

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("Water Temperature")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text(String(format: "%.1f°C", displayTemp))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(temperatureColor)
            }

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Range")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("0-15°C")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(temperatureColor)
                        .frame(width: 8, height: 8)

                    Text(temperatureStatus)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(temperatureColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onReceive(timer) { _ in
            displayTemp = bluetoothManager.deviceState.waterTemperature
        }
        .onAppear {
            displayTemp = bluetoothManager.deviceState.waterTemperature
        }
    }

    private var temperatureColor: Color {
        if displayTemp == 0 {
            return .gray
        } else if displayTemp > 0 && displayTemp <= 15 {
            return .blue
        } else if displayTemp > 15 && displayTemp <= 25 {
            return .orange
        } else {
            return .red
        }
    }

    private var temperatureStatus: String {
        if displayTemp == 0 {
            return "No Data"
        } else if displayTemp > 0 && displayTemp <= 15 {
            return "Optimal"
        } else if displayTemp > 15 && displayTemp <= 25 {
            return "Warming Up"
        } else {
            return "Too Warm"
        }
    }
}

// MARK: - Skin Temperature Card

struct SkinTemperatureCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var displayTemp: Double = 0.0

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text("Skin Temperature")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text(String(format: "%.1f°C", displayTemp))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(temperatureColor)
            }

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Range")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("34-35°C")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(temperatureColor)
                        .frame(width: 8, height: 8)

                    Text(temperatureStatus)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(temperatureColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onReceive(timer) { _ in
            displayTemp = bluetoothManager.deviceState.skinTemperature
        }
        .onAppear {
            displayTemp = bluetoothManager.deviceState.skinTemperature
        }
    }

    private var temperatureColor: Color {
        if displayTemp == 0 {
            return .gray
        } else if displayTemp >= 34 && displayTemp <= 35 {
            return .green
        } else if displayTemp > 35 && displayTemp < 40 {
            return .orange
        } else if displayTemp >= 40 {
            return .red
        } else {
            return .blue
        }
    }

    private var temperatureStatus: String {
        if displayTemp == 0 {
            return "No Data"
        } else if displayTemp >= 34 && displayTemp <= 35 {
            return "Optimal"
        } else if displayTemp > 35 && displayTemp < 40 {
            return "Warm"
        } else if displayTemp >= 40 {
            return "Too Hot!"
        } else {
            return "Cool"
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PumpControlView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PumpControlView()
                .environmentObject(BluetoothManager())
        }
    }
}
