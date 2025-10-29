//
//  TesticoolApp.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import SwiftUI

@main
struct TesticoolApp: App {
    // TEMPORARY: Back to BLE mode since DSD TECH advertises as BLE
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            ContentView()  // Use BLE mode (original)
                .environmentObject(bluetoothManager)
        }
    }
}
