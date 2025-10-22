# Testicool iOS App - Architecture Diagram

## 📱 Application Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TESTICOOL iOS APP                           │
│                         (SwiftUI + CoreBluetooth)                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                          UI LAYER (SwiftUI)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐         ┌──────────────────┐                 │
│  │  ContentView     │────────▶│ ConnectionView   │                 │
│  │  (Root View)     │         │ (Device List)    │                 │
│  └────────┬─────────┘         └──────────────────┘                 │
│           │                                                         │
│           │ Connected?                                              │
│           ▼                                                         │
│  ┌──────────────────┐                                              │
│  │ PumpControlView  │  ◀── Main control interface                  │
│  │                  │      • Large ON/OFF button                   │
│  │  ┌────────────┐  │      • Speed slider                          │
│  │  │ StatusView │  │      • Temperature card                      │
│  │  └────────────┘  │      • Error banner                          │
│  └──────────────────┘                                              │
│                                                                     │
│  ┌──────────────────┐                                              │
│  │ SettingsView     │  ◀── Settings and about                      │
│  │                  │      • Device info                           │
│  │  • SafetyInfo    │      • Safety guides                         │
│  │  • UsageGuide    │      • Usage instructions                    │
│  │  • AboutView     │      • Team credits                          │
│  └──────────────────┘                                              │
│                                                                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ @EnvironmentObject
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                    VIEW MODEL / MANAGER LAYER                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │           BluetoothManager (ObservableObject)                │  │
│  │                                                              │  │
│  │  @Published Properties:                                      │  │
│  │    • connectionStatus: ConnectionStatus                      │  │
│  │    • discoveredDevices: [DiscoveredDevice]                   │  │
│  │    • deviceState: DeviceState                                │  │
│  │    • isScanning: Bool                                        │  │
│  │                                                              │  │
│  │  Public Methods:                                             │  │
│  │    • startScanning()                                         │  │
│  │    • stopScanning()                                          │  │
│  │    • connect(to: DiscoveredDevice)                           │  │
│  │    • disconnect()                                            │  │
│  │    • turnPumpOn()                                            │  │
│  │    • turnPumpOff()                                           │  │
│  │    • setPumpSpeed(_ speed: Int)                              │  │
│  │    • requestStatus()                                         │  │
│  │    • requestTemperature()                                    │  │
│  │                                                              │  │
│  │  Private Properties:                                         │  │
│  │    • centralManager: CBCentralManager                        │  │
│  │    • connectedPeripheral: CBPeripheral?                      │  │
│  │    • txCharacteristic: CBCharacteristic?                     │  │
│  │    • rxCharacteristic: CBCharacteristic?                     │  │
│  │    • statusTimer: Timer?                                     │  │
│  │    • receiveBuffer: String                                   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ Uses
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                         MODEL LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────┐     ┌────────────────────────────┐    │
│  │   DeviceState           │     │   StatusParser             │    │
│  │   (ObservableObject)    │     │   (Static Utility)         │    │
│  │                         │     │                            │    │
│  │  @Published:            │     │  Methods:                  │    │
│  │   • isPumpOn: Bool      │     │   • parseStatus()          │    │
│  │   • pumpSpeed: Int      │◀────│   • parseTemperature()     │    │
│  │   • temperature: Double │     │   • parsePumpState()       │    │
│  │   • runtimeSeconds: Int │     │   • parseError()           │    │
│  │   • remainingSeconds    │     │   • parseManualControl()   │    │
│  │   • errorMessage        │     │                            │    │
│  │   • safetyShutoff       │     │  Handles formats:          │    │
│  │   • lastControlSource   │     │   • STATUS:{...}           │    │
│  │                         │     │   • PUMP:ON/OFF            │    │
│  │  Computed:              │     │   • TEMP:34.5              │    │
│  │   • speedPercentage     │     │   • ERROR:...              │    │
│  │   • formattedRuntime    │     │   • MANUAL:ON/OFF          │    │
│  │   • formattedTemp       │     │                            │    │
│  │   • runtimeProgress     │     └────────────────────────────┘    │
│  │                         │                                        │
│  │  Methods:               │                                        │
│  │   • updateFromStatus()  │                                        │
│  │   • setError()          │                                        │
│  │   • clearError()        │                                        │
│  │   • reset()             │                                        │
│  └─────────────────────────┘                                        │
│                                                                     │
│  ┌─────────────────────────┐     ┌────────────────────────────┐    │
│  │   Supporting Types      │     │   ParsedStatus             │    │
│  │                         │     │                            │    │
│  │  • ControlSource        │     │  • state: PumpState        │    │
│  │  • PumpState           │     │  • speed: Int              │    │
│  │  • ConnectionStatus     │     │  • runtimeMinutes: Int     │    │
│  │  • DiscoveredDevice     │     │  • remainingMinutes: Int   │    │
│  └─────────────────────────┘     │  • temperature: Double?    │    │
│                                  └────────────────────────────┘    │
│                                                                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ CoreBluetooth
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                     HARDWARE LAYER                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              CoreBluetooth Framework                         │  │
│  │                                                              │  │
│  │  Delegates:                                                  │  │
│  │    • CBCentralManagerDelegate                                │  │
│  │    • CBPeripheralDelegate                                    │  │
│  │                                                              │  │
│  │  Operations:                                                 │  │
│  │    1. Scan for peripherals (FFE0 service)                    │  │
│  │    2. Connect to peripheral                                  │  │
│  │    3. Discover services (FFE0)                               │  │
│  │    4. Discover characteristics (FFE1)                        │  │
│  │    5. Enable notifications (TX)                              │  │
│  │    6. Write data (RX)                                        │  │
│  │    7. Receive notifications (TX)                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ Bluetooth LE (HM-10)
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                      ARDUINO DEVICE                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │           Testicool Firmware (Arduino Nano)                  │  │
│  │                                                              │  │
│  │  Components:                                                 │  │
│  │    • HM-10 BLE Module (FFE0/FFE1)                            │  │
│  │    • DC Water Pump (PWM controlled)                          │  │
│  │    • Manual ON/OFF Buttons                                   │  │
│  │    • Temperature Sensor (optional)                           │  │
│  │                                                              │  │
│  │  Commands Received:                                          │  │
│  │    • ON          → Start pump                                │  │
│  │    • OFF         → Stop pump                                 │  │
│  │    • SPEED:XXX   → Set PWM (0-255)                           │  │
│  │    • STATUS      → Send full status                          │  │
│  │    • TEMP        → Send temperature                          │  │
│  │                                                              │  │
│  │  Responses Sent:                                             │  │
│  │    • OK                                                      │  │
│  │    • STATUS:{State:ON,Speed:70%,Runtime:5m,...}             │  │
│  │    • PUMP:ON / PUMP:OFF                                      │  │
│  │    • TEMP:34.5                                               │  │
│  │    • ERROR:SAFETY_SHUTOFF                                    │  │
│  │    • MANUAL:ON / MANUAL:OFF                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### Connection Flow
```
User Action           App Layer            CoreBluetooth        Arduino
───────────────────────────────────────────────────────────────────────

"Connect" tap    ──▶ startScanning()
                 ──▶ scanForPeripherals() ──▶
                                         ◀── Advertising (FFE0)
                                                              ◀─────── HM-10
                 ◀── didDiscover()

Device selected  ──▶ connect()
                 ──▶ connect(peripheral) ──▶
                                         ──▶ Connection Request
                                         ◀── Connected
                 ◀── didConnect()
                 ──▶ discoverServices()  ──▶
                                         ◀── Service FFE0
                 ◀── didDiscoverServices()
                 ──▶ discoverChar()      ──▶
                                         ◀── Char FFE1
                 ◀── didDiscoverChar()
                 ──▶ setNotifyValue()    ──▶ Enable notifications

                 ──▶ startStatusPolling()
                 ──▶ sendCommand("STATUS") ──▶ Write to FFE1
                                              ────────────────▶ STATUS\n
                                         ◀── Notification
                                         ◀───────────────────  STATUS:{...}
                 ◀── didUpdateValue()
                 ──▶ parseResponse()
                 ──▶ deviceState.update()
UI updates       ◀── @Published triggers
```

### Pump Control Flow
```
User Action           App Layer            CoreBluetooth        Arduino
───────────────────────────────────────────────────────────────────────

ON button tap    ──▶ turnPumpOn()
                 ──▶ sendCommand("ON")
                 ──▶ writeValue()        ──▶ Write "ON\n"
                                              ────────────────▶ ON\n
                                         ◀── Notification
                                         ◀───────────────────  OK
                 ◀── didUpdateValue()
                 ──▶ parseResponse()         ◀───────────────  PUMP:ON
                 ◀── didUpdateValue()
                 ──▶ deviceState.isPumpOn = true
UI updates       ◀── @Published triggers
                     (Button turns red)

                 ──▶ [5 seconds later]
                 ──▶ requestStatus()
                 ──▶ sendCommand("STATUS")  ──▶ Write "STATUS\n"
                                              ────────────────▶ STATUS\n
                                         ◀── Notification
                                         ◀───────────────────  STATUS:{State:ON,...}
                 ◀── didUpdateValue()
                 ──▶ StatusParser.parseStatus()
                 ──▶ deviceState.updateFromStatus()
UI updates       ◀── @Published triggers
                     (All values updated)
```

### Manual Button Flow
```
Physical Button       Arduino              CoreBluetooth        App Layer
───────────────────────────────────────────────────────────────────────

ON button press  ──▶ Button ISR
                 ──▶ Pump starts
                 ──▶ bluetooth.send() ───────────────────▶
                                         Notification     ──▶
                                         MANUAL:ON        ──▶ didUpdateValue()
                                                          ──▶ parseResponse()
                                                          ──▶ deviceState.isPumpOn = true
                                                          ──▶ deviceState.lastControlSource = .manual
                                                          ◀── @Published triggers
                                                              (UI shows "Manual" badge)
```

---

## 📊 Component Responsibilities

### UI Layer (SwiftUI Views)
**Responsibility:** Display data and handle user interactions
- **Input:** User taps, swipes, slider adjustments
- **Output:** Visual representation of device state
- **State:** Observes `@Published` properties (reactive)

### ViewModel Layer (BluetoothManager)
**Responsibility:** Business logic and Bluetooth communication
- **Input:** UI commands, Bluetooth notifications
- **Output:** Published state changes, Bluetooth commands
- **State:** Owns `DeviceState`, manages CoreBluetooth objects

### Model Layer (Data Models)
**Responsibility:** Data structures and parsing
- **DeviceState:** Observable device state
- **StatusParser:** Converts strings to structured data
- **Supporting Types:** Enums, structs for type safety

### Hardware Layer (CoreBluetooth)
**Responsibility:** Low-level Bluetooth communication
- **Input:** Scan requests, connection requests, write commands
- **Output:** Delegate callbacks with discovered devices and data
- **State:** Managed by iOS system

---

## 🔐 Thread Safety

### Main Thread (UI Updates)
```swift
DispatchQueue.main.async {
    self.deviceState.updateFromStatus(status)
}
```
All `@Published` property updates happen on main thread to ensure UI safety.

### Background Thread (Bluetooth)
CoreBluetooth operations run on system-managed queue:
- Scanning
- Connecting
- Reading/Writing
- Delegate callbacks

---

## 💾 Memory Management

### Object Lifecycle
```
App Launch
    ↓
TesticoolApp.init()
    ↓
@StateObject var bluetoothManager = BluetoothManager()
    ↓
BluetoothManager.init()
    ↓
centralManager = CBCentralManager(delegate: self, queue: nil)
    ↓
deviceState = DeviceState()
    ↓
[App runs - state managed by SwiftUI]
    ↓
App Termination
    ↓
All objects deallocated automatically (ARC)
```

### Retain Cycle Prevention
```swift
// Timer uses weak self
statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
    self?.requestStatus()
}

// DispatchQueue uses weak self
DispatchQueue.main.async { [weak self] in
    self?.deviceState.updateFromStatus(status)
}
```

---

## 🎯 Design Patterns Used

1. **MVVM (Model-View-ViewModel)**
   - Separation of concerns
   - Testable business logic
   - Reactive UI updates

2. **Observer Pattern**
   - `@Published` properties
   - Automatic UI updates
   - Combine framework

3. **Delegate Pattern**
   - `CBCentralManagerDelegate`
   - `CBPeripheralDelegate`
   - CoreBluetooth callbacks

4. **Singleton Pattern**
   - `BluetoothManager` (via @StateObject)
   - Shared across all views

5. **State Machine**
   - Connection states (disconnected → connecting → connected)
   - Pump states (off → on)
   - Error states

---

## 📱 App Lifecycle

```
App Launch
    ↓
TesticoolApp.body
    ↓
ContentView (with BluetoothManager injected)
    ↓
Check connectionStatus
    ├─ .disconnected ──▶ Show ConnectionView
    │                      ↓
    │                   User taps "Connect"
    │                      ↓
    │                   Scan for devices
    │                      ↓
    │                   User selects device
    │                      ↓
    │                   Connect via Bluetooth
    │                      ↓
    └─ .connected ─────▶ Show PumpControlView
                           ↓
                      Start status polling (every 5s)
                           ↓
                      User controls device
                           ↓
                      User taps "Disconnect"
                           ↓
                      Stop polling, disconnect
                           ↓
                      Back to ConnectionView
```

---

## 🔄 State Management Flow

```
User Interaction
    ↓
View captures event
    ↓
Calls BluetoothManager method
    ↓
BluetoothManager sends Bluetooth command
    ↓
Arduino receives and responds
    ↓
CoreBluetooth receives notification
    ↓
Delegate method called
    ↓
StatusParser parses response
    ↓
DeviceState updated (@Published)
    ↓
SwiftUI automatically re-renders
    ↓
User sees updated UI
```

### Example: Turning Pump On
```
1. User taps ON button
   └─ PumpControlView.Button.action { bluetoothManager.turnPumpOn() }

2. BluetoothManager.turnPumpOn()
   └─ sendCommand("ON")
       └─ peripheral.writeValue(data, for: txCharacteristic)

3. Arduino receives "ON\n"
   └─ Starts pump
   └─ Sends "OK" + "PUMP:ON"

4. HM-10 transmits via BLE

5. CoreBluetooth receives notification
   └─ peripheral(_:didUpdateValueFor:)

6. BluetoothManager.processReceivedData()
   └─ parseResponse("PUMP:ON")
       └─ DispatchQueue.main.async {
              deviceState.isPumpOn = true
          }

7. SwiftUI observes @Published change
   └─ PumpControlView re-renders
       └─ Button color: green → red
       └─ Text: "TURN ON" → "TURN OFF"
```

---

## 🛡️ Error Handling Strategy

### Network Errors
- Bluetooth disconnection → Show connection screen
- Failed to send command → Log error, show alert
- Device not found → Show "No devices found" message

### Device Errors
- Safety shutoff → Show error banner, disable ON button
- Overheat → Show critical alert, stop pump
- Invalid command → Log error (shouldn't happen with validated UI)

### App Errors
- Bluetooth permission denied → Show settings prompt
- Bluetooth powered off → Show "Turn on Bluetooth" message
- Background app → Maintain connection if possible

---

This architecture provides a **clean, maintainable, and extensible** foundation for the Testicool iOS app! 🎉
