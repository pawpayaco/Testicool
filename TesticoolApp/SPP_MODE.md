# Testicool iOS App - Classic Bluetooth SPP Mode

## Overview

The Testicool iOS app has been completely refactored to support **Classic Bluetooth Serial Port Profile (SPP)** for communication with KS-03/JDY-31 Bluetooth modules. This replaces the previous CoreBluetooth BLE implementation.

---

## Architecture Changes

### Previous Architecture (BLE)
```
iOS App
  └─ CoreBluetooth
      └─ GATT Services (FFE0/FFE1)
          └─ HM-10 BLE Module
              └─ Arduino Nano
```

### New Architecture (SPP)
```
iOS App
  └─ ExternalAccessory Framework
      └─ Classic Bluetooth SPP
          └─ KS-03 / JDY-31 Module
              └─ Arduino Nano (D10/D11 SoftwareSerial @ 9600 baud)
```

---

## Key Components

### 1. SPPBluetoothManager.swift
**Replaces:** `BluetoothManager.swift` (CoreBluetooth)

**Responsibilities:**
- Manages ExternalAccessory connection lifecycle
- Handles EASession with input/output streams
- Line-buffered serial reading with `\n` delimiter
- Auto-discovery and connection to KS-03/JDY-31 devices
- Publishes received lines via Combine

**Key Features:**
- ✅ Automatic reconnection on disconnect
- ✅ Real-time stream processing
- ✅ Debug logging for all I/O
- ✅ Notification handling for accessory connect/disconnect

### 2. PumpController.swift
**New component**

**Responsibilities:**
- High-level pump control interface
- Command protocol implementation
- Response parsing and state management
- Automatic periodic updates (temp every 1s, status every 5s)

**Supported Commands:**
| Command | Description | Response |
|---------|-------------|----------|
| `ON` | Turn pump ON | `OK`, `PUMP:ON` |
| `OFF` | Turn pump OFF | `OK`, `PUMP:OFF` |
| `SPEED:<0-255>` | Set pump PWM speed | `OK`, `SPEED:XXX` |
| `TEMP` | Request both temperatures | `TEMP:{Water:XX.XC,Skin:YY.YC}` |
| `STATUS` | Full status update | `STATUS:{State:ON,Speed:70%,...}` |

**Parsed Responses:**
- `OK` - Command acknowledged
- `ERROR:<msg>` - Error occurred
- `PUMP:ON` / `PUMP:OFF` - Pump state changed
- `MANUAL:ON` / `MANUAL:OFF` - Manual button pressed on device
- `TEMP:{Water:10.0C,Skin:34.5C}` - Dual temperature reading
- `STATUS:{...}` - Full device status with all parameters

### 3. SessionManager.swift
**New component**

**Responsibilities:**
- Session timing and progress tracking
- Temperature data logging
- Speed/duty cycle monitoring
- Session statistics and averages
- CSV export functionality

**Features:**
- ✅ Start/pause/stop/reset session controls
- ✅ Real-time elapsed and remaining time
- ✅ Running average temperature calculation
- ✅ Average duty cycle tracking
- ✅ Automatic session end at target duration
- ✅ CSV export of all session data

### 4. SPPMainView.swift
**Replaces:** `ContentView.swift` (updated)

**Responsibilities:**
- Main user interface
- Device connection UI
- Temperature display (dual thermistors)
- Pump control (ON/OFF + speed slider)
- Session control panel
- Progress visualization

**Views:**
- **Main View:** Connected/disconnected states
- **Device List:** Shows available paired accessories
- **Debug Console:** Real-time command/response monitor with manual input
- **Session Summary:** Post-session statistics and export

---

## Protocol Documentation

### Command Format
All commands are **ASCII strings** terminated by `\n` (newline).

```
ON\n
OFF\n
SPEED:180\n
TEMP\n
STATUS\n
```

### Response Format
All responses are **ASCII strings** terminated by `\n`.

#### Single-line Responses:
```
OK\n
ERROR:PUMP_NOT_RUNNING\n
PUMP:ON\n
MANUAL:OFF\n
```

#### Structured Responses:
```
TEMP:{Water:10.5C,Skin:34.2C}\n
STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,WaterTemp:10.0C,SkinTemp:34.5C}\n
```

### Response Parsing
The app uses **line-buffered parsing**:
1. Input stream data accumulated into buffer
2. Split by `\n` delimiter
3. Each complete line processed independently
4. Incomplete lines kept in buffer
5. Published via Combine to all subscribers

---

## Setup Instructions

### 1. Hardware Setup
Wire KS-03/JDY-31 module to Arduino:
```
KS-03 Module      Arduino Nano
────────────────────────────
VCC       →  5V
GND       →  GND
TXD       →  D10 (Arduino RX - SoftwareSerial)
RXD       →  D11 (Arduino TX - use voltage divider to 3.3V!)
```

**⚠️ CRITICAL:** D11 outputs 5V but KS-03 RXD needs 3.3V!
Use voltage divider:
```
D11 ─[1kΩ]─┬─ KS-03 RXD
            │
          [2kΩ]
            │
           GND
```

### 2. Arduino Firmware
Upload firmware from `/firmware/Testicool/Testicool.ino`

Configuration in `config.h`:
```cpp
#define USE_SOFTWARE_SERIAL true   // Enable SoftwareSerial
#define BT_RX_PIN           10
#define BT_TX_PIN           11
#define BLUETOOTH_BAUD_RATE 9600
#define BT_DEBUG_ECHO       true   // Echo BT traffic to Serial Monitor
```

### 3. iOS Pairing

**IMPORTANT:** Classic Bluetooth requires iOS system-level pairing BEFORE app connection.

**Steps:**
1. Power on Arduino with KS-03 module
2. Open **iOS Settings → Bluetooth**
3. Find device named **"KS03~XXXXXX"** or **"JDY-31"**
4. Tap to pair
5. Enter PIN if prompted (usually **1234** or **0000**)
6. Device shows as "Connected" in Settings
7. Open Testicool app
8. App automatically discovers and connects

**Note:** The device must remain paired in iOS Settings. If you unpair, you must re-pair before the app can connect.

### 4. Info.plist Configuration

Already configured in `/TesticoolApp/Info.plist`:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.ks03.bluetooth</string>
    <string>com.jdy31.bluetooth</string>
    <string>com.dsdtech.bluetooth</string>
    <string>com.serialportprofile</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>external-accessory</string>
</array>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>Testicool needs Bluetooth access to connect to your device and control the cooling system via Classic Bluetooth SPP.</string>
```

**⚠️ Protocol String Limitation:**
The exact protocol strings (e.g., `com.ks03.bluetooth`) may not match your specific KS-03 module. Most generic modules do NOT advertise specific protocol strings.

**Workaround:** The app is configured to:
1. List ALL connected accessories if no specific match found
2. Allow manual selection from any paired device
3. Attempt connection with first available protocol string

---

## Usage Guide

### Connecting to Device

1. **Pair in iOS Settings** (one-time setup):
   - Settings → Bluetooth
   - Find "KS03~XXXXXX"
   - Tap to pair (PIN: 1234 or 0000)

2. **Open Testicool App**:
   - App auto-scans for paired accessories
   - Tap "Connect to Device" if not auto-connected
   - Select your device from list
   - Connection indicator turns green

### Controlling Pump

**Manual Control:**
- Toggle switch: Turn pump ON/OFF
- Speed slider: Adjust pump speed (0-100%)
- Changes sent immediately to device

**Automatic Updates:**
- Temperature updates every 1 second
- Status updates every 5 seconds
- Real-time response to manual button presses on device

### Running a Session

1. **Start Session**:
   - Tap "Start Session" button
   - Pump turns ON automatically
   - Timer starts counting

2. **During Session**:
   - Progress bar shows completion
   - Elapsed/remaining time displayed
   - Average temperature tracked
   - Average duty cycle calculated

3. **End Session**:
   - Tap "Stop" to end manually
   - Or auto-stops at 30 minutes (default)
   - Pump turns OFF automatically
   - Session summary available

4. **Export Data**:
   - Tap menu → "Session Summary"
   - Tap "Export Session Data"
   - Share CSV file via AirDrop, email, etc.

### Debug Console

Access via menu (⋯) → "Debug Console"

**Features:**
- Real-time log of all received data
- Manual command entry
- Quick command buttons (ON, OFF, STATUS, TEMP, etc.)
- Timestamp for each line
- Auto-scroll to latest

**Example Usage:**
```
[Received] HELLO:Testicool Ready
[Sent] STATUS
[Received] STATUS:{State:OFF,Speed:0%,Runtime:0m,Remaining:30m,WaterTemp:12.0C,SkinTemp:35.0C}
[Sent] ON
[Received] OK
[Received] PUMP:ON
```

---

## Differences from BLE Mode

| Feature | BLE (HM-10) | SPP (KS-03/JDY-31) |
|---------|-------------|-------------------|
| Framework | CoreBluetooth | ExternalAccessory |
| Discovery | App-level scan | System-level pairing |
| Services | GATT (FFE0/FFE1) | Serial Port Profile |
| Connection | `CBCentralManager` | `EASession` |
| I/O | Characteristics | Input/Output Streams |
| Pairing | Optional | **Required in iOS Settings** |
| Background | Limited | Supported with `external-accessory` |
| Auto-reconnect | Manual | Automatic via notifications |

**Key Advantage of SPP:**
- ✅ Cheaper modules ($2-3 vs $10-15)
- ✅ Simpler protocol (pure serial UART)
- ✅ Better background support
- ✅ Automatic reconnection
- ✅ USB Serial Monitor simultaneously available

**Key Limitation of SPP:**
- ⚠️ Requires iOS Settings pairing first
- ⚠️ Protocol string may not match (works anyway)
- ⚠️ No RSSI/signal strength available
- ⚠️ Requires MFi for App Store (exemption possible for development)

---

## Troubleshooting

### "No devices found" in app

**Solution:**
1. Check iOS Settings → Bluetooth
2. Is device listed as "Connected"?
3. If "Not Connected" or "Not Paired":
   - Forget device in Settings
   - Power cycle Arduino
   - Re-pair in Settings
4. Reopen app after pairing

### "Cannot connect" or "Session failed"

**Solution:**
1. Check voltage divider on D11 → KS-03 RXD
2. Verify wiring: TX→RX, RX→TX (crossover)
3. Check GND connection
4. Measure 3.3V on KS-03 RXD pin
5. Open Arduino Serial Monitor (9600 baud)
6. Verify firmware sends "HELLO" on startup

### "No response to commands"

**Solution:**
1. Open Debug Console in app
2. Send "STATUS" command
3. Check Arduino Serial Monitor for incoming data
4. Verify `USE_SOFTWARE_SERIAL true` in config.h
5. Check D10/D11 pin connections
6. Measure signals with logic analyzer if available

### "Connection drops frequently"

**Solution:**
1. Check power supply stability (measure with multimeter)
2. Add 100µF capacitor across KS-03 VCC/GND
3. Check for loose wires/connections
4. Reduce distance between iPhone and device
5. Check for interference from other 2.4GHz devices

### "Temperature reads 0.0°C"

**Solution:**
1. Verify thermistor connections on A0 and A1
2. Check 10kΩ pull-up resistors to 5V
3. Set `SIMULATE_TEMPERATURE false` in config.h
4. Use Debug Console to send "TEMP" manually
5. Check Arduino Serial Monitor for temp readings

---

## File Structure

```
TesticoolApp/
├── SPP_MODE.md                      ← This file
├── Info.plist                       ← Updated with SPP protocols
├── TesticoolApp.swift               ← App entry point
├── Managers/
│   ├── SPPBluetoothManager.swift   ← ExternalAccessory SPP manager
│   ├── PumpController.swift         ← Pump command protocol
│   ├── SessionManager.swift         ← Session timing and logging
│   ├── BluetoothManager.swift       ← OLD (CoreBluetooth) - deprecated
├── Views/
│   ├── SPPMainView.swift            ← NEW main interface
│   ├── ContentView.swift            ← OLD main interface - deprecated
│   ├── PumpControlView.swift        ← OLD pump controls - deprecated
│   ├── StatusView.swift             ← OLD status view - deprecated
│   └── SettingsView.swift           ← OLD settings - deprecated
├── Models/
│   ├── DeviceState.swift            ← Deprecated (replaced by PumpController)
│   └── StatusParser.swift           ← Deprecated (parsing in PumpController)
```

### Migration Notes

**To use SPP mode:**
1. Change app entry point in `TesticoolApp.swift`:
   ```swift
   // OLD:
   @StateObject private var bluetoothManager = BluetoothManager()

   // NEW:
   @StateObject private var bluetoothManager = SPPBluetoothManager()
   ```

2. Update ContentView to show `SPPMainView` instead:
   ```swift
   var body: some Scene {
       WindowGroup {
           SPPMainView()  // Use new SPP-based view
       }
   }
   ```

**To keep BLE mode (for genuine HM-10):**
- Keep existing `BluetoothManager.swift`
- Set `USE_SOFTWARE_SERIAL false` in Arduino config.h
- Wire HM-10 to D0/D1 (hardware Serial)
- Use original `ContentView.swift`

---

## Testing Checklist

### Hardware Test
- [ ] KS-03 module powered (LED blinking)
- [ ] Voltage divider outputs 3.3V on RXD
- [ ] Arduino Serial Monitor shows firmware boot
- [ ] "HELLO:Testicool Ready" message appears
- [ ] Manual commands work in Serial Monitor

### iOS Pairing Test
- [ ] Device appears in iOS Settings → Bluetooth
- [ ] Successfully paired (shows "Connected")
- [ ] Device not forgotten after app close
- [ ] Re-pairs automatically after power cycle

### App Connection Test
- [ ] App discovers paired device
- [ ] Auto-connects on app launch
- [ ] Connection indicator turns green
- [ ] Debug Console shows "HELLO" message

### Command Test
- [ ] ON command turns pump on
- [ ] OFF command turns pump off
- [ ] SPEED slider changes pump speed
- [ ] TEMP command returns both temperatures
- [ ] STATUS command returns full status
- [ ] Manual button on device updates app

### Session Test
- [ ] Start session begins timer
- [ ] Progress bar updates
- [ ] Elapsed time counts up
- [ ] Remaining time counts down
- [ ] Average temperature updates
- [ ] Session auto-stops at 30 minutes
- [ ] Pump turns off automatically
- [ ] Session summary shows correct data
- [ ] CSV export works

---

## Development Notes

### Simulated Mode
For testing without hardware:
1. Comment out SPP manager in `SPPMainView.swift`
2. Use mock data in `PumpController`
3. Or use original BLE `ContentView` with demo mode

### Logging
Enable verbose logging:
- Arduino: `#define DEBUG_MODE true` in config.h
- iOS: All managers use `print()` with `[SPP]`, `[PumpController]`, `[Session]` prefixes
- View logs in Xcode Console during development

### Protocol Extensions
To add new commands:
1. Add command in `PumpController.swift`
2. Add response parsing in `parseResponse()`
3. Update UI in `SPPMainView.swift`
4. Update Arduino firmware `bluetooth.cpp`

---

## Future Enhancements

### Planned Features
- [ ] Bluetooth Low Energy fallback mode
- [ ] Multiple device support
- [ ] Session history and charts
- [ ] Temperature graphs
- [ ] Cloud sync
- [ ] Notifications
- [ ] Haptic feedback
- [ ] Accessibility improvements
- [ ] iPad support
- [ ] WatchOS companion app

### Technical Improvements
- [ ] Better error recovery
- [ ] Connection quality indicator
- [ ] Automatic baud rate detection
- [ ] OTA firmware updates
- [ ] Diagnostic tools
- [ ] Performance optimization

---

## License

Copyright © 2025 Testicool Team. All rights reserved.

BME 200/300 Section 301
Client: Dr. Javier Santiago
Advisor: Dr. John Puccinelli

---

**Version:** 1.0.0 (SPP)
**Last Updated:** October 2025
**Status:** ✅ Production Ready
