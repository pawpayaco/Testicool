# Testicool iOS App

<div align="center">

**A SwiftUI-based iOS companion app for the Testicool prototype cooling device**

Version 1.0.0 | BME 200/300 Section 301 | University of Wisconsin-Madison

</div>

---

## Overview

The Testicool iOS app provides wireless Bluetooth control and monitoring of the Testicool cooling device—a wearable scrotal cooling system designed to maintain optimal temperature (34-35°C) during sauna exposure.

### Key Features

- ✅ **Bluetooth LE connectivity** via CoreBluetooth (HM-10 module)
- ✅ **Remote pump control** - Turn ON/OFF from your iPhone
- ✅ **Speed adjustment** - Smooth slider control (0-100%)
- ✅ **Live status monitoring** - Real-time temperature, runtime, and remaining time
- ✅ **Safety features** - Automatic shutoff alerts and error handling
- ✅ **Manual/App hybrid control** - Works seamlessly whether controlled via app or physical buttons
- ✅ **Clean, minimal UI** - SwiftUI-based design with dark mode support
- ✅ **Session tracking** - Visual countdown timer and progress indicators

---

## Quick Start

### Option 1: Automated Setup (Recommended)

```bash
cd /Users/oscarmullikin/Testicool
./setup_xcode_project.sh
```

This will automatically:
- Create a complete Xcode project structure
- Organize all source files
- Generate the `.xcodeproj` file
- Set up assets and Info.plist

After running the script, open the project:

```bash
open TesticoolApp/Testicool.xcodeproj
```

### Option 2: Manual Setup

If you prefer to create the project manually in Xcode:

1. **Create New Project**
   - Open Xcode
   - File → New → Project
   - Select "App" template
   - Product Name: `Testicool`
   - Interface: SwiftUI
   - Language: Swift

2. **Add Source Files**
   - Drag and drop all files from `TesticoolApp/` into your project
   - Maintain the folder structure:
     ```
     Testicool/
     ├── TesticoolApp.swift
     ├── ContentView.swift
     ├── Info.plist
     ├── Managers/
     │   └── BluetoothManager.swift
     ├── Models/
     │   ├── DeviceState.swift
     │   └── StatusParser.swift
     └── Views/
         ├── PumpControlView.swift
         ├── StatusView.swift
         └── SettingsView.swift
     ```

3. **Configure Info.plist**
   - Add Bluetooth usage descriptions (already included in provided Info.plist)

4. **Build and Run**
   - Select your target device or simulator
   - Click the Play button (⌘R)

---

## Building and Running

### Requirements

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **macOS** with Xcode installed
- **Physical iOS device** for Bluetooth testing (simulator cannot test Bluetooth)

### Build Steps

1. **Open Project**
   ```bash
   open TesticoolApp/Testicool.xcodeproj
   ```

2. **Select Target**
   - Choose your iPhone from the device dropdown
   - Or select "Any iOS Device" for simulator preview

3. **Configure Signing**
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Choose your development team
   - Xcode will automatically manage provisioning

4. **Build and Run**
   - Press ⌘R or click the Play button
   - App will install on your device

### Testing in Simulator

The app **will run** in the iOS Simulator, but:
- ❌ Bluetooth scanning won't work (simulator limitation)
- ✅ UI and previews are fully functional
- ✅ All views can be tested visually

**To see live previews without running:**
- Open any View file (e.g., `ContentView.swift`)
- Click "Resume" in the canvas preview
- SwiftUI previews will render the interface

### Testing with Hardware

1. **Prepare Arduino Device**
   - Upload the Testicool firmware to your Arduino Nano
   - Ensure HM-10 Bluetooth module is powered and configured
   - Device should advertise as "Testicool_Prototype"

2. **Run App on Physical iPhone**
   - Connect iPhone via USB
   - Build and run from Xcode
   - Grant Bluetooth permissions when prompted

3. **Connect to Device**
   - Tap "Connect to Device"
   - Your Testicool device should appear in the list
   - Tap to connect

4. **Control Device**
   - Use the big green button to turn pump ON
   - Adjust speed with the slider
   - Monitor temperature and runtime

---

## App Architecture

### Project Structure

```
TesticoolApp/
├── TesticoolApp.swift          # App entry point, environment setup
├── ContentView.swift            # Main view switcher (connection/control)
├── Info.plist                   # Bluetooth permissions and app config
├── Managers/
│   └── BluetoothManager.swift  # CoreBluetooth communication layer
├── Models/
│   ├── DeviceState.swift       # Observable device state model
│   └── StatusParser.swift      # Firmware response parser
└── Views/
    ├── PumpControlView.swift   # Main control interface
    ├── StatusView.swift        # Session status and countdown
    └── SettingsView.swift      # Settings and about screens
```

### Data Flow

```
Arduino Firmware
       ↓ (Bluetooth Serial)
BluetoothManager (CoreBluetooth)
       ↓ (Parse responses)
StatusParser
       ↓ (Update state)
DeviceState (@Published)
       ↓ (SwiftUI binding)
UI Views (Auto-updates)
```

### Key Components

#### 1. **BluetoothManager.swift**
Handles all Bluetooth communication using CoreBluetooth framework.

**Responsibilities:**
- Scanning for HM-10 devices
- Connecting/disconnecting
- Sending commands (`ON`, `OFF`, `SPEED:xxx`, `STATUS`)
- Receiving and parsing responses
- Auto-polling status every 5 seconds

**HM-10 BLE Configuration:**
```swift
serviceUUID = "FFE0"           // HM-10 default service
txCharacteristicUUID = "FFE1"  // Device TX (app receives)
rxCharacteristicUUID = "FFE1"  // Device RX (app sends)
```

#### 2. **DeviceState.swift**
Observable object that holds current device state.

**Published Properties:**
- `isPumpOn: Bool` - Pump running state
- `pumpSpeed: Int` - PWM value (0-255)
- `temperature: Double` - Current temperature in °C
- `runtimeSeconds: Int` - Elapsed runtime
- `remainingSeconds: Int` - Time until auto-shutoff
- `errorMessage: String?` - Current error (if any)

#### 3. **StatusParser.swift**
Parses incoming firmware messages into structured data.

**Supported Formats:**
```
STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,Temp:34.5C}
PUMP:ON / PUMP:OFF
TEMP:34.5
ERROR:SAFETY_SHUTOFF
MANUAL:ON / MANUAL:OFF
```

#### 4. **Views**
SwiftUI views that compose the user interface.

- **ContentView** - Root view, switches between connection and control screens
- **PumpControlView** - Main control interface with ON/OFF button and speed slider
- **StatusView** - Session timer with progress ring and status rows
- **SettingsView** - Device info, safety guides, and about section

---

## Bluetooth Protocol

### Command Format

Commands are ASCII strings terminated by newline (`\n`).

### Commands (App → Device)

| Command | Description | Example |
|---------|-------------|---------|
| `ON` | Turn pump ON at default speed | `ON\n` |
| `OFF` | Turn pump OFF | `OFF\n` |
| `STATUS` | Request full status update | `STATUS\n` |
| `TEMP` | Request temperature reading | `TEMP\n` |
| `SPEED:<value>` | Set pump speed (0-255) | `SPEED:180\n` |

### Responses (Device → App)

| Response | Description | Example |
|----------|-------------|---------|
| `OK` | Command acknowledged | `OK` |
| `ERROR:<msg>` | Error occurred | `ERROR:SAFETY_SHUTOFF` |
| `STATUS:{...}` | Status data packet | `STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,Temp:34.5C}` |
| `TEMP:<value>` | Temperature in Celsius | `TEMP:34.5` |
| `PUMP:ON/OFF` | Pump state notification | `PUMP:ON` |
| `MANUAL:ON/OFF` | Manual button pressed | `MANUAL:ON` |

### Auto-Polling

The app automatically requests `STATUS` every **5 seconds** when connected. This keeps the UI synchronized with the device state, even when controlled manually via physical buttons.

---

## User Interface

### Connection Screen

<details>
<summary>Features</summary>

- App logo and branding
- Connection status indicator (Disconnected / Connecting / Connected)
- "Connect to Device" button triggers Bluetooth scan
- Device list sheet showing:
  - Device name
  - Signal strength (RSSI)
  - Tap to connect

</details>

### Control Screen

<details>
<summary>Features</summary>

**Header:**
- Connection status (green)
- Last update timestamp
- Disconnect button

**Pump Control Card:**
- Large circular ON/OFF button
  - Green when OFF, Red when ON
  - Shows "TURN ON" or "TURN OFF"
- Manual control indicator (shows when physical button used)

**Speed Control Card:**
- Speed percentage display (0-100%)
- Slider control (mapped to 0-255 PWM internally)
- Disabled when pump is OFF

**Status Card:**
- Circular progress ring showing runtime progress
- Remaining time countdown
- Runtime elapsed
- Warning when < 5 minutes remaining

**Temperature Card:**
- Current temperature display
- Target range indicator (34-35°C)
- Status indicator:
  - 🔵 Cool (< 34°C)
  - 🟢 Optimal (34-35°C)
  - 🟠 Warm (35-40°C)
  - 🔴 Too Hot (≥ 40°C)

**Error Banner** (when applicable):
- Red alert banner at top
- Error message from firmware
- Dismiss button

</details>

### Settings Screen

<details>
<summary>Features</summary>

- Auto-connect toggle
- Device information (name, firmware version, max runtime)
- Safety information guide
- Usage guide with step-by-step instructions
- About page with team credits

</details>

---

## Customization

### Changing Bluetooth UUIDs

If your HM-10 module uses different UUIDs, edit `BluetoothManager.swift`:

```swift
// Line ~39-41
private let serviceUUID = CBUUID(string: "YOUR_SERVICE_UUID")
private let txCharacteristicUUID = CBUUID(string: "YOUR_TX_UUID")
private let rxCharacteristicUUID = CBUUID(string: "YOUR_RX_UUID")
```

### Changing Device Name

To connect to a different device name, edit `BluetoothManager.swift`:

```swift
// Line ~44
private let targetDeviceName = "Your_Device_Name"
```

### Adjusting Status Polling Interval

To change how often status is requested (default 5 seconds):

```swift
// Line ~49
private let statusPollingInterval: TimeInterval = 5.0
```

### Styling and Colors

All colors use SwiftUI's semantic colors for automatic dark mode support:

- Primary accent: `.blue` (iOS system blue)
- Success: `.green`
- Warning: `.orange`
- Error: `.red`

To customize, search and replace color values in the Views files.

---

## Troubleshooting

### App Won't Build

**Error:** "No such module 'CoreBluetooth'"
- **Solution:** CoreBluetooth is a system framework, no import needed. Make sure you're targeting iOS (not macOS).

**Error:** "Info.plist not found"
- **Solution:** Ensure `Info.plist` is in the project root and added to the target.

### Bluetooth Issues

**Problem:** "No devices found" when scanning
- ✅ Ensure you're running on a **physical iOS device** (not simulator)
- ✅ Grant Bluetooth permissions when prompted
- ✅ Check that Arduino device is powered on
- ✅ Verify HM-10 module is advertising (LED should blink)
- ✅ Check HM-10 service UUID matches (`FFE0` is default)

**Problem:** "Failed to connect"
- ✅ Move closer to the device (within 10 meters)
- ✅ Restart the Arduino device
- ✅ Toggle Bluetooth off/on in iOS Settings
- ✅ Restart the app

**Problem:** "Commands not working"
- ✅ Check Serial Monitor on Arduino for incoming commands
- ✅ Verify baud rate is 9600 in firmware
- ✅ Ensure characteristic UUIDs are correct

### UI Issues

**Problem:** SwiftUI previews not showing
- ✅ Click "Resume" in the canvas
- ✅ Clean build folder (⌘⇧K)
- ✅ Restart Xcode

**Problem:** Status not updating
- ✅ Check Bluetooth connection is active
- ✅ Verify device is sending STATUS responses
- ✅ Look for errors in Xcode console

---

## Testing Checklist

### Without Hardware (Simulator)

- [ ] App launches successfully
- [ ] Connection screen displays properly
- [ ] Tap "Connect" shows device list (empty)
- [ ] UI renders correctly in light and dark mode
- [ ] SwiftUI previews work for all views

### With Hardware (Physical Device)

- [ ] App discovers "Testicool_Prototype" device
- [ ] Successfully connects to device
- [ ] Receives initial STATUS update
- [ ] Turn ON button starts pump
- [ ] Turn OFF button stops pump
- [ ] Speed slider changes pump speed
- [ ] Temperature updates every 5 seconds
- [ ] Runtime countdown progresses
- [ ] Manual button press shows in app
- [ ] Error messages display correctly
- [ ] Disconnect button works
- [ ] App reconnects after disconnection

---

## Development Notes

### Adding New Features

**To add a new command:**

1. Add command method in `BluetoothManager.swift`:
   ```swift
   func sendNewCommand() {
       sendCommand("NEW_CMD")
   }
   ```

2. Add response handling in `parseResponse()`:
   ```swift
   else if response.hasPrefix("NEW_CMD:") {
       // Parse response
   }
   ```

3. Update UI to call the new method

**To add a new view:**

1. Create new file in `Views/` folder
2. Import SwiftUI and add `@EnvironmentObject var bluetoothManager`
3. Build your view
4. Add navigation link from appropriate parent view

### Debugging

Enable verbose logging by checking Xcode console output. All Bluetooth operations are logged with `[BT]` prefix:

```
[BT] Started scanning for devices...
[BT] Discovered: Testicool_Prototype (RSSI: -45)
[BT] Connected to Testicool_Prototype
[BT] Sent command: ON
[BT] Received: PUMP:ON
```

---

## Future Enhancements

Potential features for future versions:

- [ ] Session history logging (save past sessions to CoreData)
- [ ] Temperature graphs and charts
- [ ] Push notifications for safety shutoffs
- [ ] Multiple device profiles
- [ ] Export session data (CSV/PDF)
- [ ] Apple Watch companion app
- [ ] HealthKit integration
- [ ] Firmware OTA updates via Bluetooth
- [ ] Custom speed presets
- [ ] Scheduled sessions

---

## Technical Specifications

### Minimum Requirements

- **iOS:** 16.0+
- **Xcode:** 15.0+
- **Swift:** 5.9+
- **Device:** iPhone (iPad support possible with minor UI adjustments)

### Frameworks Used

- **SwiftUI** - Declarative UI framework
- **CoreBluetooth** - Bluetooth LE communication
- **Combine** - Reactive programming (via @Published)

### Architecture Pattern

- **MVVM** (Model-View-ViewModel)
  - Models: `DeviceState`, `StatusParser`
  - Views: SwiftUI views in `Views/`
  - ViewModel: `BluetoothManager` (combines manager + view model roles)

### Memory Management

- Uses `@StateObject` for lifecycle-owned objects
- Uses `@EnvironmentObject` for dependency injection
- Uses `weak self` in closures to prevent retain cycles
- No manual memory management required (ARC handles everything)

---

## Safety and Compliance

### Medical Disclaimer

This app is a **prototype for educational purposes** as part of a BME capstone project. It is **not a medical device** and has not been approved by the FDA or any regulatory body.

**Do not use for medical purposes without proper clinical validation and regulatory approval.**

### Data Privacy

- ✅ No data collection or analytics
- ✅ No network requests (fully offline)
- ✅ No user accounts or authentication
- ✅ All data stays on device

### Bluetooth Security

- Uses standard iOS Bluetooth encryption
- No pairing PIN required (HM-10 default behavior)
- For production use, consider:
  - Adding PIN-based pairing
  - Implementing command authentication
  - Encrypting sensitive commands

---

## Support and Contact

### Development Team

**BME 200/300 Section 301**
University of Wisconsin-Madison

- **Oscar Mullikin** (Team Leader) - omullikin@wisc.edu
- **Luke Rosner** (BSAC) - lrosner2@wisc.edu
- **Murphy Diggins** (BPAG) - mdiggins@wisc.edu
- **Nicholas Grotenhuis** (Communicator) - ngrotenhuis@wisc.edu
- **Pablo Muzquiz** (BWIG) - jmuzquiz@wisc.edu

**Client:** Dr. Javier Santiago
**Advisor:** Dr. John Puccinelli

### Reporting Issues

For bugs or feature requests, contact the development team via email.

---

## License

This software is developed as part of an educational capstone project at the University of Wisconsin-Madison.

**All rights reserved by the project team and client.**

For academic use and evaluation purposes only.

---

## Acknowledgments

- **Dr. Javier Santiago** - Project client and medical advisor
- **Dr. John Puccinelli** - Faculty advisor
- **BME Department** - University of Wisconsin-Madison
- **Apple** - SwiftUI and CoreBluetooth frameworks

---

## Version History

### v1.0.0 (December 2025)
- Initial release
- Full Bluetooth connectivity
- Remote pump control
- Live status monitoring
- Safety features
- Manual/app hybrid control

---

**Built with ❄️ by the Testicool Team**
