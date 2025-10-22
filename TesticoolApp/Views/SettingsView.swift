//
//  SettingsView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @AppStorage("autoConnect") private var autoConnect = false
    @State private var showAbout = false

    var body: some View {
        NavigationView {
            List {
                // Connection Settings
                Section {
                    Toggle("Auto-Connect", isOn: $autoConnect)

                    if bluetoothManager.connectionStatus == .connected {
                        Button(action: {
                            bluetoothManager.disconnect()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Disconnect Device")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Automatically connect to the last used device when app opens")
                }

                // Device Information
                if bluetoothManager.connectionStatus == .connected {
                    Section("Device Information") {
                        InfoRow(label: "Device Name", value: "Testicool_Prototype")
                        InfoRow(label: "Firmware Version", value: "1.0.0")
                        InfoRow(label: "Protocol", value: "Bluetooth LE")
                        InfoRow(label: "Max Runtime", value: "30 minutes")
                    }
                }

                // Safety Information
                Section {
                    NavigationLink(destination: SafetyInfoView()) {
                        Label("Safety Information", systemImage: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                    }

                    NavigationLink(destination: UsageGuideView()) {
                        Label("Usage Guide", systemImage: "book.fill")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Help & Safety")
                }

                // About
                Section {
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack {
                            Label("About Testicool", systemImage: "info.circle.fill")
                                .foregroundColor(.purple)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("About")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Testicool v1.0.0")
                        Text("© 2025 BME 200/300 Section 301")
                        Text("University of Wisconsin-Madison")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo
                    Image(systemName: "snowflake")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    VStack(spacing: 10) {
                        Text("Testicool")
                            .font(.system(size: 32, weight: .bold))

                        Text("Version 1.0.0")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 15) {
                        Text("About")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 20)

                        Text("Testicool is a wearable scrotal cooling device designed to maintain optimal scrotal temperature (34-35°C) during sauna exposure (80-100°C environments).")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Team
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Development Team")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Oscar Mullikin - Team Leader")
                            Text("Luke Rosner - BSAC")
                            Text("Murphy Diggins - BPAG")
                            Text("Nicholas Grotenhuis - Communicator")
                            Text("Pablo Muzquiz - BWIG")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Advisors
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Project Leadership")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Client: Dr. Javier Santiago")
                            Text("Advisor: Dr. John Puccinelli")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Institution
                    VStack(spacing: 8) {
                        Text("BME 200/300 Section 301")
                            .font(.system(size: 15, weight: .medium))

                        Text("University of Wisconsin-Madison")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
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
}

// MARK: - Safety Info View

struct SafetyInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SafetySection(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    title: "Important Safety Information",
                    content: "Please read and understand these safety guidelines before using Testicool."
                )

                SafetySection(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "Maximum Runtime",
                    content: "The device will automatically shut off after 30 minutes of continuous operation. This is a safety feature to prevent prolonged exposure."
                )

                SafetySection(
                    icon: "thermometer",
                    iconColor: .red,
                    title: "Temperature Monitoring",
                    content: "Monitor the temperature display. If temperature exceeds 40°C, the device will automatically shut off for safety."
                )

                SafetySection(
                    icon: "cross.case.fill",
                    iconColor: .blue,
                    title: "Medical Disclaimer",
                    content: "This device is a prototype for educational purposes. Consult with a healthcare provider before use, especially if you have any medical conditions."
                )

                SafetySection(
                    icon: "hand.raised.fill",
                    iconColor: .orange,
                    title: "Emergency Stop",
                    content: "If you experience any discomfort, immediately press the OFF button on the device or in the app. Remove the device and discontinue use."
                )

                SafetySection(
                    icon: "drop.fill",
                    iconColor: .blue,
                    title: "Water Safety",
                    content: "Ensure all connections are secure before use. Check for leaks regularly. Use only clean, cold water in the reservoir."
                )
            }
            .padding(20)
        }
        .navigationTitle("Safety Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Usage Guide View

struct UsageGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                UsageStep(
                    number: 1,
                    title: "Prepare the Device",
                    description: "Fill the water reservoir with cold water (50:50 ice:water ratio recommended). Ensure all tubing connections are secure."
                )

                UsageStep(
                    number: 2,
                    title: "Connect via Bluetooth",
                    description: "Open the app and tap 'Connect to Device'. Select your Testicool device from the list."
                )

                UsageStep(
                    number: 3,
                    title: "Turn On the Pump",
                    description: "Tap the green TURN ON button. The pump will start at default speed (70%)."
                )

                UsageStep(
                    number: 4,
                    title: "Adjust Speed",
                    description: "Use the speed slider to adjust water flow. Higher speed = more cooling effect."
                )

                UsageStep(
                    number: 5,
                    title: "Monitor Status",
                    description: "Keep an eye on the temperature reading and runtime. The device will automatically shut off after 30 minutes."
                )

                UsageStep(
                    number: 6,
                    title: "Manual Control",
                    description: "You can also use the physical buttons on the device lid. The app will show when manual controls are used."
                )
            }
            .padding(20)
        }
        .navigationTitle("Usage Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Safety Section

struct SafetySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Usage Step

struct UsageStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(BluetoothManager())
    }
}
