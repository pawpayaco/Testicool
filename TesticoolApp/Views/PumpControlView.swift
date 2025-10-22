//
//  PumpControlView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI

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

    var body: some View {
        VStack(spacing: 20) {
            // Pump state text
            Text(bluetoothManager.deviceState.isPumpOn ? "Pump Running" : "Pump Off")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(bluetoothManager.deviceState.isPumpOn ? .green : .secondary)

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
                        .fill(
                            bluetoothManager.deviceState.isPumpOn ?
                                Color.red : Color.green
                        )
                        .frame(width: 150, height: 150)
                        .shadow(
                            color: (bluetoothManager.deviceState.isPumpOn ? Color.red : Color.green).opacity(0.4),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                    VStack(spacing: 8) {
                        Image(systemName: bluetoothManager.deviceState.isPumpOn ? "stop.fill" : "power")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)

                        Text(bluetoothManager.deviceState.isPumpOn ? "TURN OFF" : "TURN ON")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(bluetoothManager.deviceState.safetyShutoff)

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
    }
}

// MARK: - Speed Control Card

struct SpeedControlCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var tempSpeed: Double = 180

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "speedometer")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("Pump Speed")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(bluetoothManager.deviceState.speedPercentage)%")
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
                        if !editing {
                            // Send command when user releases slider
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
            tempSpeed = Double(newSpeed)
        }
    }
}

// MARK: - Water Temperature Card

struct WaterTemperatureCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("Water Temperature")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text(bluetoothManager.deviceState.formattedWaterTemperature)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(temperatureColor)
            }

            // Temperature range indicator
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

                // Temperature status indicator
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
    }

    private var temperatureColor: Color {
        let temp = bluetoothManager.deviceState.waterTemperature

        if temp == 0 {
            return .gray
        } else if temp > 0 && temp <= 15 {
            return .blue // Optimal cold water
        } else if temp > 15 && temp <= 25 {
            return .orange // Getting warm
        } else {
            return .red // Too warm
        }
    }

    private var temperatureStatus: String {
        let temp = bluetoothManager.deviceState.waterTemperature

        if temp == 0 {
            return "No Data"
        } else if temp > 0 && temp <= 15 {
            return "Optimal"
        } else if temp > 15 && temp <= 25 {
            return "Warming Up"
        } else {
            return "Too Warm"
        }
    }
}

// MARK: - Skin Temperature Card

struct SkinTemperatureCard: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text("Skin Temperature")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text(bluetoothManager.deviceState.formattedSkinTemperature)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(temperatureColor)
            }

            // Temperature range indicator
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

                // Temperature status indicator
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
    }

    private var temperatureColor: Color {
        let temp = bluetoothManager.deviceState.skinTemperature

        if temp == 0 {
            return .gray
        } else if temp >= 34 && temp <= 35 {
            return .green // Optimal scrotal temp
        } else if temp > 35 && temp < 40 {
            return .orange // Warm
        } else if temp >= 40 {
            return .red // Too hot - danger!
        } else {
            return .blue // Too cold
        }
    }

    private var temperatureStatus: String {
        let temp = bluetoothManager.deviceState.skinTemperature

        if temp == 0 {
            return "No Data"
        } else if temp >= 34 && temp <= 35 {
            return "Optimal"
        } else if temp > 35 && temp < 40 {
            return "Warm"
        } else if temp >= 40 {
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

// MARK: - Preview

struct PumpControlView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PumpControlView()
                .environmentObject(BluetoothManager())
        }
    }
}
