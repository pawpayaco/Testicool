//
//  StatusView.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI

struct StatusView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

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
                        .trim(from: 0, to: bluetoothManager.deviceState.runtimeProgress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: bluetoothManager.deviceState.runtimeProgress)

                    // Center text
                    VStack(spacing: 4) {
                        Text(bluetoothManager.deviceState.formattedRemainingTime)
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
                    StatusRow(
                        icon: "clock.fill",
                        label: "Runtime",
                        value: bluetoothManager.deviceState.formattedRuntime,
                        color: .blue
                    )

                    Divider()

                    StatusRow(
                        icon: "hourglass",
                        label: "Max Session",
                        value: "30m 0s",
                        color: .gray
                    )

                    if bluetoothManager.deviceState.isPumpOn {
                        Divider()

                        StatusRow(
                            icon: "drop.fill",
                            label: "Flow Status",
                            value: "Active",
                            color: .green
                        )
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
            if bluetoothManager.deviceState.remainingSeconds < 300 && bluetoothManager.deviceState.isPumpOn {
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
    }

    private var progressColor: Color {
        let progress = bluetoothManager.deviceState.runtimeProgress

        if progress < 0.5 {
            return .green
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
            .environmentObject(BluetoothManager())
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}
