# Testicool Firmware

**Version:** 1.0.0
**Team:** BME 200/300 Section 301
**Client:** Dr. Javier Santiago
**Advisor:** Dr. John Puccinelli

---

## Overview

This firmware repository contains the complete Arduino-compatible code for the **Testicool** prototype—a wearable scrotal cooling device designed to maintain optimal scrotal temperature (34-35°C) during sauna exposure (80-100°C environments).

### Key Features

- **Dual Control Modes:**
  - **Manual Hardware Control:** Physical ON/OFF buttons mounted on water bottle lid
  - **Wireless App Control:** Bluetooth serial interface for smartphone app
- **Liquid Cooling System:** PWM-controlled DC pump circulates cold water through silicone tubing
- **Safety Features:**
  - 30-minute maximum runtime with auto-shutoff
  - Temperature monitoring (optional sensor support)
  - Emergency stop capability
  - Button debouncing
- **Modular Architecture:** Clean separation of pump, Bluetooth, and configuration logic

---

## Hardware Requirements

### Microcontroller
- **Arduino Nano** (ATmega328P) with "Old Bootloader" setting
  - 5V operating voltage
  - 16 MHz clock speed
  - 32KB Flash, 2KB SRAM

### Components

| Component | Specification | Quantity | Notes |
|-----------|--------------|----------|-------|
| DC Water Pump | 12V, 1-3 L/min flow rate | 1 | PWM speed control capable |
| Bluetooth Module | HC-05/HC-06 or HM-10 BLE | 1 | UART serial communication |
| Push Buttons | Momentary tactile switches | 2 | Mounted on bottle lid (ON/OFF) |
| Water Reservoir | 946 mL stainless steel bottle | 1 | With custom lid assembly |
| Silicone Tubing | Medical-grade, ID: 4-6mm | ~2m | Metalized/insulated composite |
| Power Supply | 12V battery or DC adapter | 1 | Sufficient for pump + Arduino |
| Optional: Thermistor | 10K NTC | 1 | For temperature feedback |
| Optional: LEDs | Status indicators | 2 | Power and Bluetooth status |

### Pin Configuration (Arduino Nano)

```
PUMP CONTROL:
  D9  - Pump PWM Speed Control (must be PWM-capable)
  D8  - Pump Enable (HIGH = ON, LOW = OFF)
  D7  - Pump Direction (optional, for reversible pumps)

MANUAL BUTTONS:
  D2  - ON Button (interrupt-capable, internal pull-up)
  D3  - OFF Button (interrupt-capable, internal pull-up)

BLUETOOTH SERIAL:
  D0  - RX (Arduino Nano hardware serial)
  D1  - TX (Arduino Nano hardware serial)

OPTIONAL SENSORS:
  A0  - Temperature Sensor (analog input)

OPTIONAL LEDS:
  D12 - Power/Status LED
  D13 - Bluetooth LED (onboard LED)
```

---

## File Structure

```
firmware/
├── Firmware.ino         # Main program with setup() and loop()
├── config.h             # System constants, pin definitions, safety parameters
├── pump.h               # Pump control interface declarations
├── pump.cpp             # Pump control implementation
├── bluetooth.h          # Bluetooth communication interface
├── bluetooth.cpp        # Bluetooth command parsing and responses
└── README.md            # This file
```

### File Descriptions

#### `Firmware.ino`
Main Arduino sketch containing:
- `setup()`: Initializes all hardware modules
- `loop()`: Non-blocking main loop handling button checks, Bluetooth commands, safety monitoring, and status updates
- Manual button debouncing logic
- LED status indication
- Temperature reading (if sensor installed)

#### `config.h`
Central configuration file with:
- Pin assignments for all hardware
- Pump speed parameters (min/max/default PWM values)
- Safety thresholds (max runtime, temperature limits)
- Bluetooth baud rate and protocol settings
- Debug mode toggle
- Simulated sensor values for testing

#### `pump.h` / `pump.cpp`
Pump control module providing:
- Initialization and state management
- ON/OFF control with configurable speed
- Runtime tracking and remaining time calculation
- Safety checking (max runtime enforcement)
- Emergency stop function
- Status string formatting for debugging

#### `bluetooth.h` / `bluetooth.cpp`
Bluetooth communication module providing:
- Serial initialization at configured baud rate
- Command parsing from app
- Response formatting (OK, ERROR, STATUS, TEMP)
- Status update transmission
- Device info queries

---

## Bluetooth Communication Protocol

### Command Format
Commands are sent as **ASCII strings** terminated by newline (`\n`) or carriage return (`\r`).

### Commands (App → Device)

| Command | Description | Example |
|---------|-------------|---------|
| `ON` | Turn pump ON at default speed | `ON\n` |
| `OFF` | Turn pump OFF | `OFF\n` |
| `STATUS` | Request full status update | `STATUS\n` |
| `TEMP` | Request temperature reading | `TEMP\n` |
| `SPEED:<value>` | Set pump speed (0-255) | `SPEED:200\n` |

### Responses (Device → App)

| Response | Description | Example |
|----------|-------------|---------|
| `OK` | Command acknowledged successfully | `OK` |
| `ERROR:<msg>` | Error occurred | `ERROR:PUMP_START_FAILED` |
| `STATUS:{...}` | Status data packet | `STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,Temp:34.5C}` |
| `TEMP:<value>` | Temperature in Celsius | `TEMP:34.5` |
| `PUMP:ON` | Pump state notification | `PUMP:ON` |
| `PUMP:OFF` | Pump state notification | `PUMP:OFF` |
| `MANUAL:ON` | Manual button pressed | `MANUAL:ON` |
| `MANUAL:OFF` | Manual button pressed | `MANUAL:OFF` |

### Error Codes

- `CMD_TOO_LONG` - Command exceeded buffer size
- `UNKNOWN_COMMAND` - Unrecognized command
- `PUMP_START_FAILED` - Pump failed to start (check error state)
- `PUMP_NOT_RUNNING` - Speed change attempted while pump off
- `INVALID_SPEED_VALUE` - Speed value out of range (0-255)
- `SAFETY_SHUTOFF` - Automatic safety shutoff triggered
- `OVERHEAT` - Temperature exceeded safe threshold

---

## Installation and Setup

### 1. Install Arduino IDE
- Download from [arduino.cc](https://www.arduino.cc/en/software)
- Install version 2.x or later

### 2. Configure Arduino IDE for Nano
1. Connect Arduino Nano via USB
2. Go to **Tools → Board → Arduino AVR Boards → Arduino Nano**
3. **Important:** Select **Tools → Processor → ATmega328P (Old Bootloader)** if using clone boards
4. Select correct COM port under **Tools → Port**

### 3. Upload Firmware
1. Open `Firmware.ino` in Arduino IDE
2. Ensure all files are in the same directory
3. Click **Upload** button (or press Ctrl+U)
4. Wait for "Done uploading" message

### 4. Verify Installation
1. Open **Tools → Serial Monitor**
2. Set baud rate to **9600**
3. You should see initialization messages:
   ```
   ========================================
     TESTICOOL BLUETOOTH INITIALIZED
   ========================================
   Device: Testicool_Prototype
   Version: 1.0.0
   Baud Rate: 9600
   ========================================
   Ready for commands...
   ```

### 5. Test Manual Buttons
- Press **ON button** → Pump should start, message: `[BUTTON] Manual ON pressed`
- Press **OFF button** → Pump should stop, message: `[BUTTON] Manual OFF pressed`

### 6. Test Bluetooth Commands
1. Pair Bluetooth module with smartphone/computer
2. Connect using serial terminal app (e.g., Serial Bluetooth Terminal on Android)
3. Send test commands:
   ```
   ON
   STATUS
   SPEED:150
   TEMP
   OFF
   ```

---

## Configuration

### Adjusting Pump Speed

Edit `config.h`:
```cpp
#define PUMP_DEFAULT_SPEED  180    // Default: 70% power (0-255 scale)
```

### Changing Maximum Runtime

Edit `config.h`:
```cpp
#define MAX_RUN_TIME_MS     1800000L  // 30 minutes (milliseconds)
```

### Enabling Temperature Sensor

Edit `config.h`:
```cpp
#define SIMULATE_TEMPERATURE  false   // Use real sensor
```

Then calibrate thermistor coefficients in `bluetooth.cpp` and `Firmware.ino`:
```cpp
steinhart /= 3950.0;  // Adjust B-coefficient for your thermistor
```

### Adjusting Safety Thresholds

Edit `config.h`:
```cpp
#define OVERHEAT_TEMP_C     40.0   // Maximum safe temperature (°C)
#define TARGET_TEMP_MIN_C   34.0   // Target minimum (°C)
#define TARGET_TEMP_MAX_C   35.0   // Target maximum (°C)
```

### Disabling Debug Messages

For production use, disable verbose logging:

Edit `config.h`:
```cpp
#define DEBUG_MODE  false
```

---

## Safety Features

### 1. Maximum Runtime Enforcement
- **Default:** 30 minutes continuous operation
- **Behavior:** Pump automatically stops after max runtime
- **Notification:** Sends `ERROR:SAFETY_SHUTOFF` via Bluetooth
- **Reset:** Turn pump OFF, wait, then turn back ON

### 2. Temperature Monitoring
- **When enabled:** Continuously reads thermistor
- **Overheat protection:** Emergency stop if temp > `OVERHEAT_TEMP_C`
- **Notification:** Sends `ERROR:OVERHEAT` with temperature reading

### 3. Button Debouncing
- **Debounce delay:** 50ms (configurable in `config.h`)
- **Prevents:** Accidental multiple triggers from single press

### 4. Emergency Stop
- **Trigger:** Can be called programmatically or via overheat detection
- **Behavior:** Immediate pump shutoff, sets ERROR state
- **Recovery:** Call `pumpResetError()` after addressing issue

---

## Troubleshooting

### Pump Won't Start

**Symptoms:** No pump response to ON command or button press

**Possible Causes:**
1. **Power supply issue**
   - Check 12V power connection
   - Verify power supply can deliver sufficient current (typically 0.5-1A)

2. **Wiring error**
   - Verify pump enable pin (D8) connection
   - Check PWM pin (D9) connection

3. **Pump in ERROR state**
   - Send `OFF` command to reset
   - Check Serial Monitor for error messages

**Solutions:**
```cpp
// In Serial Monitor, send:
OFF
// Wait 2 seconds, then:
ON
```

### Bluetooth Not Connecting

**Symptoms:** Cannot pair or connect to Bluetooth module

**Possible Causes:**
1. **Module not powered**
   - Check 5V and GND connections to HC-05/HM-10

2. **Wrong baud rate**
   - Default firmware uses 9600 baud
   - Some modules ship with 38400 or 115200

**Solutions:**
1. Check module LED - should blink rapidly when unpaired
2. Try different baud rates in `config.h`:
   ```cpp
   #define BLUETOOTH_BAUD_RATE 38400  // Try 9600, 38400, 115200
   ```
3. For HC-05 modules, may need AT command configuration

### Commands Not Recognized

**Symptoms:** Sending commands returns `ERROR:UNKNOWN_COMMAND`

**Possible Causes:**
1. **Incorrect termination** - Commands must end with `\n` or `\r`
2. **Case sensitivity** - Commands are case-insensitive but check syntax
3. **Extra spaces** - No spaces before/after command

**Solutions:**
- Ensure your terminal app sends newline after commands
- Use uppercase: `ON`, `OFF`, `STATUS`
- No trailing spaces: `SPEED:200` not `SPEED: 200`

### Pump Runs for Short Time Then Stops

**Symptoms:** Pump starts but stops after a few minutes

**Possible Causes:**
1. **Safety timeout triggered** - Check if runtime exceeded `MAX_RUN_TIME_MS`
2. **Overheating detected** - Temperature sensor reading too high
3. **Power supply dropout** - Insufficient current capacity

**Solutions:**
1. Check Serial Monitor for safety messages
2. Increase `MAX_RUN_TIME_MS` if needed
3. Adjust `OVERHEAT_TEMP_C` threshold
4. Use higher capacity power supply

### Temperature Reading Incorrect

**Symptoms:** Temperature shows unrealistic values

**Possible Causes:**
1. **Simulated mode enabled** - Using placeholder value
2. **Wrong thermistor coefficients** - B-value mismatch
3. **Wiring issue** - Poor connection or wrong series resistor

**Solutions:**
1. Verify `SIMULATE_TEMPERATURE false` in `config.h`
2. Calibrate Steinhart-Hart coefficients for your specific thermistor
3. Check series resistor value (should match thermistor nominal resistance, typically 10K)

---

## Mobile App Development

### Recommended Architecture

For students developing the companion app, consider:

**Platform Options:**
- **React Native** - Cross-platform (iOS/Android)
- **Flutter** - Cross-platform with good Bluetooth support
- **Native Android** - Kotlin with Android Bluetooth API
- **Native iOS** - Swift with CoreBluetooth framework

**Key Libraries:**
- React Native: `react-native-bluetooth-serial` or `react-native-ble-manager`
- Flutter: `flutter_bluetooth_serial` package
- Android: `android.bluetooth` API
- iOS: `CoreBluetooth` framework

### App Features to Implement

**Essential:**
- [ ] Bluetooth device scanning and pairing
- [ ] ON/OFF pump control buttons
- [ ] Current status display (pump state, speed, runtime)
- [ ] Temperature display

**Recommended:**
- [ ] Speed slider (0-255 or 0-100%)
- [ ] Runtime countdown timer
- [ ] Session history logging
- [ ] Disconnection handling and reconnection

**Advanced:**
- [ ] Charts/graphs of temperature over time
- [ ] Push notifications for safety shutoffs
- [ ] Multiple device profiles
- [ ] Firmware update over Bluetooth

### Sample App Code (React Native)

```javascript
import BluetoothSerial from 'react-native-bluetooth-serial';

// Connect to device
const connectToDevice = async (deviceId) => {
  try {
    await BluetoothSerial.connect(deviceId);
    console.log('Connected to Testicool');
  } catch (error) {
    console.error('Connection failed:', error);
  }
};

// Send command
const sendCommand = async (command) => {
  try {
    await BluetoothSerial.write(command + '\n');
  } catch (error) {
    console.error('Send failed:', error);
  }
};

// Turn pump ON
const turnPumpOn = () => sendCommand('ON');

// Turn pump OFF
const turnPumpOff = () => sendCommand('OFF');

// Request status
const getStatus = () => sendCommand('STATUS');

// Listen for responses
BluetoothSerial.on('read', (data) => {
  console.log('Received:', data.data);
  // Parse response and update UI
});
```

---

## Testing Procedure

### Bench Testing (No Sauna)

1. **Power-On Test**
   - Connect power supply
   - Verify Serial Monitor shows initialization messages
   - Check status LEDs

2. **Manual Button Test**
   - Press ON button → Pump starts
   - Press OFF button → Pump stops
   - Verify debouncing (rapid presses don't cause issues)

3. **Bluetooth Command Test**
   - Connect via Bluetooth serial terminal
   - Send `ON` → Pump starts, receive `OK` and `PUMP:ON`
   - Send `STATUS` → Receive full status string
   - Send `SPEED:100` → Pump speed changes
   - Send `OFF` → Pump stops

4. **Safety Timer Test**
   - Reduce `MAX_RUN_TIME_MS` to 60000 (1 minute) in `config.h`
   - Start pump and wait
   - Verify auto-shutoff after 1 minute
   - Check for `ERROR:SAFETY_SHUTOFF` message

5. **Temperature Sensor Test** (if installed)
   - Send `TEMP` command
   - Verify reasonable reading
   - Apply heat source to thermistor
   - Verify temperature increases

### Integration Testing (With Water System)

1. **Flow Test**
   - Fill reservoir with 946 mL water
   - Connect tubing in complete loop
   - Start pump, verify smooth circulation
   - Check for leaks at all connections

2. **Cooling Capacity Test**
   - Fill reservoir with ice water (50:50 ice:water ratio)
   - Measure initial temperature
   - Run pump for 5 minutes
   - Measure water temperature at tubing exit

3. **Duration Test**
   - Fill reservoir with ice water
   - Run pump continuously for 30 minutes
   - Monitor water temperature every 5 minutes
   - Verify pump operates smoothly throughout

### Field Testing (Sauna Environment)

⚠️ **Safety Note:** Conduct initial sauna tests WITHOUT wearing device. Use test rig with thermocouples.

1. **Heat Resistance Test**
   - Place device (without user) in sauna at 80°C
   - Monitor electronics temperature
   - Verify no component failures

2. **Cooling Performance Test**
   - Set up thermal monitoring on test mannequin
   - Run device in 80-100°C sauna
   - Measure cooling effectiveness at target area
   - Compare with/without device operation

3. **User Acceptance Test**
   - Recruit test subjects (with proper IRB approval if required)
   - Collect comfort and usability feedback
   - Measure actual scrotal temperature (non-invasive)
   - Document any issues or concerns

---

## Known Limitations

1. **Temperature Sensing:** Current implementation uses simulated temperature. Real thermistor calibration required for accurate readings.

2. **Flow Rate:** Pump speed is open-loop PWM control. No flow sensor feedback to detect blockages.

3. **Battery Life:** Not optimized for low power. Deep sleep modes not implemented.

4. **Water Level:** No reservoir level sensing. User must manually monitor water level.

5. **Bluetooth Range:** Limited to ~10 meters for HC-05/HC-06 modules. BLE (HM-10) may offer better range.

6. **Error Recovery:** Manual intervention required for ERROR states. No automatic retry logic.

---

## Future Enhancements

### Hardware
- [ ] Add flow rate sensor for closed-loop control
- [ ] Implement water level sensor (capacitive or float switch)
- [ ] Add vibration motor for alert notifications
- [ ] Upgrade to BLE 5.0 module for better range and power efficiency
- [ ] Design custom PCB to consolidate components

### Firmware
- [ ] Implement PID control for precise temperature regulation
- [ ] Add data logging to EEPROM for session history
- [ ] Implement OTA (Over-The-Air) firmware updates
- [ ] Add low-power sleep modes for battery operation
- [ ] Implement CRC checking for Bluetooth commands
- [ ] Add calibration routine for thermistor

### Software
- [ ] Develop companion mobile app (iOS/Android)
- [ ] Create web-based configuration interface
- [ ] Implement cloud sync for session data
- [ ] Add machine learning for adaptive cooling profiles

---

## References

1. Testicool Preliminary Report (October 8, 2025)
2. Testicool Product Design Specifications (September 18, 2025)
3. Arduino Nano Datasheet: [Arduino.cc](https://docs.arduino.cc/hardware/nano)
4. HC-05 Bluetooth Module Datasheet
5. ISO 10993 Biocompatibility Standards

---

## Support and Contact

**Team Members:**
- Oscar Mullikin (Team Leader): omullikin@wisc.edu
- Luke Rosner (BSAC): lrosner2@wisc.edu
- Murphy Diggins (BPAG): mdiggins@wisc.edu
- Nicholas Grotenhuis (Communicator): ngrotenhuis@wisc.edu
- Pablo Muzquiz (BWIG): jmuzquiz@wisc.edu

**Client:** Dr. Javier Santiago
**Advisor:** Dr. John Puccinelli

**Course:** BME 200/300 Section 301
**Institution:** University of Wisconsin-Madison

---

## License

This firmware is developed as part of an educational capstone project at the University of Wisconsin-Madison. All rights reserved by the project team and client.

For academic use and evaluation purposes only.

---

**Last Updated:** December 2025
**Firmware Version:** 1.0.0
