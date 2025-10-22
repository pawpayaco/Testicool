//
//  ContentView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @AppStorage("demoMode") private var demoMode = false

    var body: some View {
        NavigationView {
            Group {
                if demoMode || bluetoothManager.connectionStatus == .connected {
                    // Show main control interface when connected OR in demo mode
                    PumpControlView()
                } else {
                    // Show connection screen when disconnected
                    ConnectionView()
                }
            }
            .navigationTitle("Testicool")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        demoMode.toggle()
                    }) {
                        Image(systemName: demoMode ? "wand.and.stars.inverse" : "wand.and.stars")
                            .foregroundColor(demoMode ? .orange : .blue)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Connection View

struct ConnectionView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showDeviceList = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App logo/icon area
            VStack(spacing: 15) {
                Image(systemName: "snowflake")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Testicool")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Prototype Control")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            Spacer()

            // Connection status
            VStack(spacing: 15) {
                StatusIndicator(status: bluetoothManager.connectionStatus)

                Text(bluetoothManager.connectionStatus.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Connect button
            VStack(spacing: 15) {
                Button(action: {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScanning()
                    } else {
                        bluetoothManager.startScanning()
                    }
                    showDeviceList = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: bluetoothManager.isScanning ? "stop.circle.fill" : "wave.3.right")
                            .font(.system(size: 20))

                        Text(bluetoothManager.isScanning ? "Stop Scanning" : "Connect to Device")
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
                .disabled(bluetoothManager.connectionStatus == .connecting)

                if bluetoothManager.isScanning {
                    Text("Scanning for devices...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showDeviceList) {
            DeviceListView(isPresented: $showDeviceList)
                .environmentObject(bluetoothManager)
        }
    }
}

// MARK: - Device List View

struct DeviceListView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
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
                            .foregroundColor(.secondary)

                        Text("Make sure your Testicool device is powered on and nearby")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(bluetoothManager.discoveredDevices) { device in
                        DeviceRow(device: device)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                bluetoothManager.connect(to: device)
                                isPresented = false
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

// MARK: - Device Row

struct DeviceRow: View {
    let device: DiscoveredDevice

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 8) {
                    Text("Signal: \(device.signalStrength)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("RSSI: \(device.rssi) dBm")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: ConnectionStatus

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 4)
                    .scaleEffect(status == .connecting ? 1.5 : 1.0)
                    .opacity(status == .connecting ? 0 : 1)
                    .animation(
                        status == .connecting ?
                            Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false) :
                            .default,
                        value: status
                    )
            )
    }

    private var statusColor: Color {
        switch status {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BluetoothManager())
    }
}
