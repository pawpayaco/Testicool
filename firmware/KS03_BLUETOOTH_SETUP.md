# KS-03 / JDY-31 Bluetooth Module Setup Guide

## Overview

The Testicool firmware has been updated to support **KS-03** and **JDY-31** Bluetooth modules, which are low-cost HM-10 clones using **Classic Bluetooth SPP (Serial Port Profile)** instead of BLE.

**Key Differences from HM-10:**
- ❌ NOT Bluetooth Low Energy (BLE)
- ✅ Classic Bluetooth SPP (Serial Port Profile)
- ❌ Does NOT support HM-10 AT commands
- ✅ Transparent UART bridge (9600 baud default)
- ❌ No FFE0/FFE1 BLE service characteristics
- ✅ Broadcasts as "KS03~XXXXXX" or "JDY-31"
- ⚠️ Often requires **3.3V logic** on RX pin

---

## Hardware Wiring

### KS-03 / JDY-31 Module Pinout

```
KS-03 Module (6 pins)
┌─────────────────┐
│  STATE  VCC     │
│  RXD    GND     │
│  TXD    EN      │
└─────────────────┘
```

### Connection to Arduino Nano

```
KS-03 Module          Arduino Nano
─────────────────────────────────────
VCC      →  5V (or 3.3V - check datasheet)
GND      →  GND
TXD      →  D10 (Arduino RX - SoftwareSerial)
RXD      →  D11 (Arduino TX - SoftwareSerial)
            ⚠️ Use voltage divider or level shifter!
STATE    →  Not connected
EN       →  Not connected (or VCC to enable)
```

### ⚠️ IMPORTANT: 3.3V Logic Level for RXD

Many KS-03 modules use **3.3V logic** and can be damaged by 5V signals. The Arduino Nano outputs 5V on D11, so you MUST use a voltage divider:

```
Arduino D11 (TX) ──[1kΩ]──┬── KS-03 RXD
                           │
                        [2kΩ]
                           │
                          GND

Output voltage: 5V × (2kΩ / 3kΩ) = 3.3V
```

**Alternative:** Use a bi-directional logic level shifter (recommended for production).

---

## Firmware Configuration

### config.h Settings

The firmware uses **SoftwareSerial** on pins D10/D11 by default:

```cpp
// Use SoftwareSerial for Bluetooth
#define USE_SOFTWARE_SERIAL true   // true = D10/D11, false = hardware Serial

// Bluetooth pins (when USE_SOFTWARE_SERIAL = true)
#define BT_RX_PIN           10     // Arduino D10 -> KS-03 TX
#define BT_TX_PIN           11     // Arduino D11 -> KS-03 RX (use 3.3V!)

#define BLUETOOTH_BAUD_RATE 9600   // KS-03 default is 9600

// Debug echo: prints all BT traffic to Serial Monitor
#define BT_DEBUG_ECHO       true   // Set false in production
```

### Why SoftwareSerial?

Using SoftwareSerial on D10/D11 allows:
- ✅ **Simultaneous USB debugging** via Serial Monitor (hardware Serial)
- ✅ **Real-time monitoring** of Bluetooth commands
- ✅ **No conflicts** between USB and Bluetooth
- ✅ **BT_DEBUG_ECHO** can show all traffic in Serial Monitor

---

## Testing the Bluetooth Connection

### Step 1: Upload Firmware

1. Open `Testicool.ino` in Arduino IDE
2. Select **Board:** Arduino Nano
3. Select **Processor:** ATmega328P (Old Bootloader)
4. Select **Port:** `/dev/cu.usbserial-XXX` or `/dev/tty.usbserial-XXX`
5. Click **Upload**

### Step 2: Open Serial Monitor

1. Open **Tools → Serial Monitor**
2. Set baud rate to **9600**
3. You should see:

```
========================================
  TESTICOOL BLUETOOTH INITIALIZED
========================================
Device: Testicool_Prototype
Version: 1.0.0
Module: KS-03 / JDY-31 (Classic SPP)
Pins: RX=D10, TX=D11
Baud Rate: 9600
========================================
[BT] KS-03 module initialized
[BT] Waiting for phone connection...
```

### Step 3: Pair from Phone

#### iOS (requires Serial Bluetooth app):
1. Download "Serial Bluetooth Terminal" or "Bluetooth Terminal"
2. Go to Settings → Bluetooth
3. Find device named **"KS03~XXXXXX"** or **"JDY-31"**
4. Pair (default PIN is usually **1234** or **0000**)
5. Open the app and connect to the device

#### Android:
1. Download "Serial Bluetooth Terminal" from Play Store
2. Enable Bluetooth
3. Open app → Devices → Scan
4. Find **"KS03~XXXXXX"** or **"JDY-31"**
5. Connect (PIN: **1234** or **0000**)

### Step 4: Test Commands

In the Bluetooth terminal app, send these commands:

```
ON        → Should turn pump ON, reply "OK" and "PUMP:ON"
STATUS    → Should return current status
TEMP      → Should return temperatures
SPEED:128 → Should set speed to 50%
OFF       → Should turn pump OFF
```

If `BT_DEBUG_ECHO` is enabled, you'll see all commands echoed in the Serial Monitor.

---

## Protocol Details

### Commands (Phone → Arduino)

| Command | Description | Response |
|---------|-------------|----------|
| `ON` | Turn pump ON | `OK`<br>`PUMP:ON` |
| `OFF` | Turn pump OFF | `OK`<br>`PUMP:OFF` |
| `SPEED:0-255` | Set pump speed | `OK`<br>`SPEED:XXX` |
| `STATUS` | Request status | `STATUS:{State:ON,Speed:70%,...}` |
| `TEMP` | Request temperature | `TEMP:{Water:10.0C,Skin:34.5C}` |

### Responses (Arduino → Phone)

| Response | Description |
|----------|-------------|
| `OK` | Command acknowledged |
| `ERROR:MSG` | Error occurred |
| `PUMP:ON` / `PUMP:OFF` | Pump state changed |
| `MANUAL:ON` / `MANUAL:OFF` | Manual button pressed |
| `STATUS:{...}` | Full status update |
| `TEMP:{...}` | Temperature reading |
| `HELLO:Testicool Ready` | Sent on initialization |

All commands and responses are **ASCII strings** terminated by `\n` (newline).

---

## Troubleshooting

### Problem: Can't find "KS03~XXXXXX" in Bluetooth scan

**Solutions:**
1. Check power LED on KS-03 module (should be blinking)
2. Measure voltage on VCC pin (should be 3.3V-5V)
3. Ensure EN pin is HIGH (connect to VCC if not already)
4. Try power cycling the Arduino

### Problem: Can pair but no data received

**Solutions:**
1. Check TX/RX connections (TX→RX, RX→TX)
2. Verify baud rate is 9600 on both sides
3. Enable `BT_DEBUG_ECHO` and check Serial Monitor
4. Send "ON" command and watch for Serial Monitor output

### Problem: Arduino crashes or garbled data

**Solutions:**
1. Check if RXD voltage divider is correct (3.3V)
2. Verify ground connection between Arduino and KS-03
3. Try reducing `BLUETOOTH_BAUD_RATE` to 4800
4. Check for power supply noise (add 100µF capacitor to VCC/GND)

### Problem: Commands work from Serial Monitor but not Bluetooth

**Solutions:**
1. Verify `USE_SOFTWARE_SERIAL` is set to `true`
2. Check that D10/D11 pins are not used by anything else
3. Add delay after sending commands (50ms minimum)
4. Ensure newline character is sent with commands

---

## iOS App Integration

### ⚠️ Important: CoreBluetooth NOT Compatible

The KS-03/JDY-31 uses **Classic Bluetooth SPP**, not BLE. Therefore:

- ❌ **CoreBluetooth framework will NOT work**
- ❌ No FFE0/FFE1 service UUIDs
- ❌ Cannot use CBCentralManager

### iOS App Options

**Option 1: Use External Accessory Framework** (requires MFi certification)
- Requires Apple MFi (Made for iPhone) certification
- Uses `ExternalAccessory.framework`
- Not feasible for prototypes

**Option 2: Use Third-Party Serial Bluetooth App**
- Download "Serial Bluetooth Terminal" from App Store
- Use as interface to control Testicool
- Good for testing and debugging

**Option 3: Switch to BLE Module** (recommended for iOS app)
- Use genuine HM-10 or Nordic nRF52 module
- Firmware supports both (set `USE_SOFTWARE_SERIAL false`)
- iOS app can use CoreBluetooth

### Android App Integration

Android **fully supports** Classic Bluetooth SPP:

```kotlin
// Use BluetoothSocket with SPP UUID
val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
val socket = device.createRfcommSocketToServiceRecord(uuid)
socket.connect()
val inputStream = socket.inputStream
val outputStream = socket.outputStream
```

This works seamlessly with KS-03/JDY-31 modules.

---

## Pin Reference Quick Guide

```
ARDUINO NANO PIN ASSIGNMENTS (with KS-03 Bluetooth)
════════════════════════════════════════════════════

ANALOG PINS:
  A0  → Water temperature sensor (thermistor + 10kΩ)
  A1  → Skin temperature sensor (thermistor + 10kΩ)
  A2  → Speed potentiometer (wiper)

DIGITAL PINS:
  D2  → Manual toggle button (with pull-up)
  D7  → Pump direction (optional, unused)
  D8  → Pump enable pin
  D9  → Pump PWM speed control
  D10 → Bluetooth RX (SoftwareSerial) ← KS-03 TX
  D11 → Bluetooth TX (SoftwareSerial) → KS-03 RX (3.3V!)
  D12 → Power LED (optional)
  D13 → Status LED / Bluetooth indicator

POWER:
  5V  → Pump, potentiometer, KS-03 VCC
  3.3V → (not used, but available)
  GND → All grounds common
```

---

## Next Steps

1. ✅ Wire up KS-03 module with voltage divider on RXD
2. ✅ Upload firmware and verify Serial Monitor output
3. ✅ Pair phone and test commands via Bluetooth terminal
4. ✅ Verify pump control and temperature readings
5. ⚠️ For iOS app, consider switching to genuine BLE module
6. ✅ For Android app, use BluetoothSocket with SPP UUID

---

## Additional Resources

- **KS-03 Datasheet:** https://github.com/RRechallenge/KS0108/blob/master/KS-03_datasheet.pdf
- **JDY-31 Info:** Similar to KS-03, uses SPP
- **Arduino SoftwareSerial:** https://www.arduino.cc/en/Reference/SoftwareSerial
- **Voltage Divider Calculator:** https://ohmslawcalculator.com/voltage-divider-calculator

---

**Firmware Version:** 1.0.0
**Last Updated:** October 2025
**Team:** BME 200/300 Section 301
