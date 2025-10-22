# Testicool - Missing Pieces & Quick Fixes

## 🎯 Current Status

### ✅ What Works Right Now
- Arduino firmware is complete (single thermistor)
- iOS app fully functional
- Pump control (ON/OFF, speed)
- Bluetooth communication
- Manual buttons
- Safety shutoff (30 min)
- Demo mode in app

### ❌ What's Missing

---

## Gap #1: Second Thermistor (SKIN TEMP)

**Problem:** Firmware only reads water temperature (A0), not skin temperature (A1)

### Quick Fix (5 minutes):

**1. Update `firmware/config.h`:**
```cpp
// Find line ~30, add after TEMP_SENSOR_PIN:
#define TEMP_SENSOR_WATER_PIN  A0  // Water temperature
#define TEMP_SENSOR_SKIN_PIN   A1  // Skin temperature
```

**2. Update `firmware/Firmware.ino`:**
Find the `loop()` function, add this after the existing temperature reading:

```cpp
// Around line 80-90, add:
float skinTemp = readTemperature(TEMP_SENSOR_SKIN_PIN);
```

**3. Update `firmware/bluetooth.cpp`:**
Find the `handleStatusCommand()` function, change the STATUS output:

```cpp
// Change from:
String status = "STATUS:{State:" + stateStr + ",Speed:" + String(speedPercent) +
                "%,Runtime:" + String(runtimeMin) + "m,Remaining:" + String(remainMin) +
                "m,Temp:" + String(temp, 1) + "C}";

// To:
float waterTemp = readTemperature(TEMP_SENSOR_WATER_PIN);
float skinTemp = readTemperature(TEMP_SENSOR_SKIN_PIN);

String status = "STATUS:{State:" + stateStr + ",Speed:" + String(speedPercent) +
                "%,Runtime:" + String(runtimeMin) + "m,Remaining:" + String(remainMin) +
                "m,WaterTemp:" + String(waterTemp, 1) + "C,SkinTemp:" + String(skinTemp, 1) + "C}";
```

---

## Gap #2: iOS App Dual Temperature Display

**Problem:** App only shows one temperature, needs to show both water + skin

### Quick Fix (10 minutes):

**1. Update `TesticoolApp/Models/DeviceState.swift`:**
```swift
// Replace:
@Published var temperature: Double = 0.0

// With:
@Published var waterTemperature: Double = 0.0
@Published var skinTemperature: Double = 0.0
```

**2. Update `TesticoolApp/Models/StatusParser.swift`:**
```swift
// In parseStatus() function, add these cases in the switch:

case "WaterTemp":
    let tempString = value.replacingOccurrences(of: "C", with: "")
    waterTemperature = Double(tempString)

case "SkinTemp":
    let tempString = value.replacingOccurrences(of: "C", with: "")
    skinTemperature = Double(tempString)
```

And update the ParsedStatus struct:
```swift
struct ParsedStatus {
    let state: PumpState
    let speed: Int
    let runtimeMinutes: Int
    let remainingMinutes: Int
    let waterTemperature: Double?
    let skinTemperature: Double?
}
```

**3. Update `TesticoolApp/Views/PumpControlView.swift`:**

Replace the single `TemperatureCard()` with:
```swift
// Water Temperature
TemperatureCard(
    title: "Water Temp",
    temperature: bluetoothManager.deviceState.waterTemperature,
    targetRange: "0-15°C",
    icon: "drop.fill"
)
.padding(.horizontal, 20)

// Skin Temperature
TemperatureCard(
    title: "Skin Temp",
    temperature: bluetoothManager.deviceState.skinTemperature,
    targetRange: "34-35°C",
    icon: "figure.stand"
)
.padding(.horizontal, 20)
```

---

## Gap #3: HM-10 Bluetooth Module Configuration

**Problem:** HM-10 might not be configured correctly out of the box

### Quick Fix (Optional):

If you can't connect via Bluetooth, configure HM-10:

**1. Connect HM-10 to Arduino:**
- Don't upload firmware yet
- Wire: HM-10 TX → Arduino RX, HM-10 RX → Arduino TX
- Power HM-10 from 5V

**2. Open Serial Monitor (9600 baud):**

**3. Send AT commands:**
```
AT             → Should reply "OK"
AT+NAME?       → Check current name
AT+NAMETesticool_Prototype  → Set name
AT+BAUD?       → Check baud rate (should be 4 = 9600)
AT+BAUD4       → Set to 9600 if different
```

---

## Gap #4: Temperature Calibration

**Problem:** Thermistor readings might be inaccurate

### Quick Calibration (15 minutes):

**1. Prepare ice water bath:** 0°C
**2. Prepare boiling water:** 100°C
**3. Prepare room temp water:** ~25°C

**4. Measure resistance at each temperature:**
- Disconnect thermistor from circuit
- Use multimeter to measure resistance
- Record: R(0°C), R(25°C), R(100°C)

**5. Calculate coefficients:**
Use online Steinhart-Hart calculator with your measurements

**6. Update firmware** `config.h`:
```cpp
// Update these values based on your measurements:
#define THERMISTOR_NOMINAL     10000   // Resistance at 25°C
#define TEMPERATURE_NOMINAL    25      // Temp at nominal resistance
#define B_COEFFICIENT          3950    // Beta coefficient (adjust if needed)
```

---

## Gap #5: Connection Robustness

**Problem:** If Bluetooth disconnects, app doesn't auto-reconnect

### Quick Fix (15 minutes):

**Add to `TesticoolApp/Managers/BluetoothManager.swift`:**

```swift
// Add this property:
@Published var shouldAutoReconnect: Bool = false
private var lastConnectedDeviceID: UUID?

// In disconnect():
func disconnect() {
    guard let peripheral = connectedPeripheral else { return }
    lastConnectedDeviceID = peripheral.identifier  // Save ID
    // ... rest of disconnect code
}

// In didDisconnectPeripheral:
func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("[BT] Disconnected")

    // Auto-reconnect logic
    if shouldAutoReconnect, let lastID = lastConnectedDeviceID {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScanning()  // Try to reconnect
        }
    }

    // ... rest of code
}
```

---

## 🚀 Priority Order (Do These First)

### 1. **Hardware Wiring** (1-2 hours)
Follow `COMPLETE_HARDWARE_SETUP_GUIDE.md`
- Wire power, pump, buttons, HM-10, thermistors
- Test each component individually

### 2. **Upload Firmware** (5 minutes)
- Open `firmware/Firmware.ino` in Arduino IDE
- Select Arduino Nano + Old Bootloader
- Upload to board

### 3. **Test with Serial Monitor** (10 minutes)
- Open Serial Monitor (9600 baud)
- Send commands: `ON`, `OFF`, `STATUS`, `TEMP`
- Verify all work before trying app

### 4. **Test iOS App** (5 minutes)
- Use Demo Mode first (tap magic wand)
- Then connect to real device
- Test all controls

### 5. **Add Second Thermistor** (Gap #1 + #2 above)
- Update firmware for A1 pin
- Update app for dual display
- Re-upload and test

---

## 📋 Quick Test Checklist

```
Hardware:
[ ] Arduino powers on
[ ] HM-10 LED blinks
[ ] Pump runs when ON button pressed
[ ] Pump stops when OFF button pressed
[ ] Water thermistor reads ~room temp
[ ] Skin thermistor reads ~room temp

Firmware:
[ ] Uploads without errors
[ ] Serial Monitor shows boot message
[ ] "STATUS" command returns data
[ ] "ON" command starts pump
[ ] "TEMP" command returns temperature

iOS App:
[ ] App opens without crashing
[ ] Demo mode works (magic wand icon)
[ ] Discovers "Testicool_Prototype"
[ ] Connects successfully
[ ] ON button starts pump
[ ] OFF button stops pump
[ ] Speed slider works
[ ] Temperature displays
[ ] Disconnect button works
```

---

## 💡 Quick Troubleshooting

**"App won't connect"**
→ Check HM-10 is powered and blinking
→ Try AT commands to configure HM-10
→ Make sure you're scanning (not demo mode)

**"Temp shows 0.0"**
→ Check thermistor wiring (A0/A1 to resistor to 5V)
→ Check 10kΩ pull-up resistor is installed
→ Measure voltage at A0/A1 (should be 2-3V)

**"Pump won't start"**
→ Check 12V power to pump
→ Check D8 (enable) goes HIGH when ON
→ Try pump directly with 12V to verify it works

**"Commands don't work"**
→ Check Serial Monitor - are they being received?
→ Check TX/RX wiring (TX→RX, RX→TX)
→ Try typing commands in Serial Monitor first

---

## 🎯 Summary

**To make it fully work:**

1. Wire hardware (follow guide)
2. Upload firmware
3. Test with Serial Monitor
4. Fix Gap #1 (add 2nd thermistor to firmware)
5. Fix Gap #2 (add 2nd temp to app)
6. Done!

**Estimated time:** 2-3 hours total

Ready to start? Let me know which part you want help with first!
