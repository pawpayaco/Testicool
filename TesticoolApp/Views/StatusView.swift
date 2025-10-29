//
//  StatusView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI
import Combine

struct StatusView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    // Local state that updates every second
    @State private var displayRuntime: Int = 0
    @State private var displayRemaining: Int = 1800

    // Timer for live updates
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)

                Text("Session Status")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()
            }

            // Runtime and Remaining Time
            VStack(spacing: 12) {
                // Runtime Progress Ring
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: runtimeProgress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Center text
                    VStack(spacing: 4) {
                        Text(formattedRemainingTime)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("remaining")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)

                // Status rows
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text("Runtime")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formattedRuntime)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .frame(width: 24)

                        Text("Max Session")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("30m 0s")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    if bluetoothManager.deviceState.isPumpOn {
                        Divider()

                        HStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .frame(width: 24)

                            Text("Flow Status")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("Active")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }

            // Safety notice
            if displayRemaining < 300 && bluetoothManager.deviceState.isPumpOn {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)

                    Text("Less than 5 minutes remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .onReceive(timer) { _ in
            if bluetoothManager.deviceState.isPumpOn {
                // Increment runtime every second
                displayRuntime += 1
                // Decrement remaining every second
                if displayRemaining > 0 {
                    displayRemaining -= 1
                }
            }
        }
        .onChange(of: bluetoothManager.deviceState.isPumpOn) { isOn in
            print("[StatusView] isPumpOn changed to: \(isOn)")
            if isOn {
                // Pump turned on - start fresh if runtime is 0
                if displayRuntime == 0 {
                    displayRemaining = 1800
                }
            } else {
                // Pump turned off - IMMEDIATE RESET
                print("[StatusView] Resetting clock to 30:00")
                displayRuntime = 0
                displayRemaining = 1800
            }
        }
        .onChange(of: bluetoothManager.deviceState.runtimeSeconds) { newValue in
            // Sync with firmware data
            displayRuntime = newValue
        }
        .onChange(of: bluetoothManager.deviceState.remainingSeconds) { newValue in
            // Sync with firmware data
            displayRemaining = newValue
        }
        .onAppear {
            displayRuntime = bluetoothManager.deviceState.runtimeSeconds
            displayRemaining = bluetoothManager.deviceState.remainingSeconds
        }
    }

    private var runtimeProgress: Double {
        let maxSeconds = 1800.0
        return min(Double(displayRuntime) / maxSeconds, 1.0)
    }

    private var formattedRuntime: String {
        let minutes = displayRuntime / 60
        let seconds = displayRuntime % 60
        return String(format: "%dm %ds", minutes, seconds)
    }

    private var formattedRemainingTime: String {
        let minutes = displayRemaining / 60
        let seconds = displayRemaining % 60
        return String(format: "%dm %ds", minutes, seconds)
    }

    private var progressColor: Color {
        let progress = runtimeProgress
        if progress < 0.5 {
            return .green
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
            .environmentObject(BluetoothManager())
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}
