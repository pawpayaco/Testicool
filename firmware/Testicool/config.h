/*
 * config.h
 * Configuration file for Testicool scrotal cooling device
 *
 * This file contains all system constants, pin assignments, and
 * configurable parameters for the device.
 *
 * Team: BME 200/300 Section 301
 * Device: Arduino Nano (ATmega328P)
 */

#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// HARDWARE PIN DEFINITIONS
// ============================================================================

// Pump Control Pins
#define PUMP_PWM_PIN        9      // PWM output to control pump speed (must be PWM-capable pin)
#define PUMP_ENABLE_PIN     8      // Digital pin to enable/disable pump
#define PUMP_DIRECTION_PIN  7      // Optional: for bidirectional pumps (not used in single-direction setup)

// Manual Control Button (single momentary tactile switch on bottle lid)
#define BUTTON_TOGGLE_PIN   2      // Toggle button - press to turn ON/OFF (interrupt-capable pin)
#define BUTTON_DEBOUNCE_MS  50     // Button debounce delay in milliseconds

// Manual Speed Control (rotary potentiometer on bottle lid)
#define SPEED_POT_PIN       A2     // Potentiometer for manual speed control (0-5V = 0-255 PWM)
#define SPEED_READ_INTERVAL_MS  100  // Read potentiometer every 100ms

// Temperature Sensors (dual thermistor setup)
#define TEMP_SENSOR_WATER_PIN  A0  // Water temperature sensor (thermistor in reservoir)
#define TEMP_SENSOR_SKIN_PIN   A1  // Skin temperature sensor (thermistor on user)

// LED Status Indicators (optional)
#define LED_POWER_PIN       12     // Power/status LED
#define LED_BLUETOOTH_PIN   13     // Bluetooth connection LED (Arduino Nano onboard LED)

// ============================================================================
// PUMP CONFIGURATION
// ============================================================================

#define PUMP_MIN_SPEED      0      // Minimum PWM value (0-255, pump off)
#define PUMP_MAX_SPEED      255    // Maximum PWM value (0-255, full speed)
#define PUMP_DEFAULT_SPEED  180    // Default operating speed (70% power for quieter operation)

// Flow rate assumptions:
// Typical mini DC pumps: 1-3 L/min at 12V
// For 946mL reservoir with tubing loop ~1-2 meters, circulation time ~30-60 seconds

// ============================================================================
// SAFETY PARAMETERS
// ============================================================================

#define MAX_RUN_TIME_MS     1800000L  // 30 minutes max continuous operation (30 * 60 * 1000)
#define OVERHEAT_TEMP_C     40.0      // Simulated overtemperature cutoff (°C)
#define UNDERCOOL_TEMP_C    30.0      // Simulated under-temperature cutoff (°C)
#define TARGET_TEMP_MIN_C   34.0      // Target scrotal temperature minimum (°C)
#define TARGET_TEMP_MAX_C   35.0      // Target scrotal temperature maximum (°C)

// ============================================================================
// BLUETOOTH CONFIGURATION
// ============================================================================

// DSD TECH BLE module uses hardware Serial on D0/D1
// CURRENT WIRING: DSD TECH on D0/D1 (hardware Serial)
//   - Bluetooth RX → Arduino TX (D1)
//   - Bluetooth TX → Arduino RX (D0)
//   - VCC → 5V
//   - GND → GND
// NOTE: When using hardware Serial, disconnect BT RX from D0 before uploading firmware
#define USE_SOFTWARE_SERIAL false  // false = use hardware Serial on D0/D1

// Legacy pins (not used with DSD TECH, kept for reference)
#define BT_RX_PIN           0      // Hardware Serial RX (D0)
#define BT_TX_PIN           1      // Hardware Serial TX (D1)

#define BLUETOOTH_BAUD_RATE 9600   // Standard baud rate for KS-03/JDY-31/HC-05/HC-06
                                    // KS-03 and JDY-31 default to 9600 baud

// Debug echo: Set to true to echo all Bluetooth traffic to Serial Monitor
#define BT_DEBUG_ECHO       true   // Set false in production to reduce Serial overhead

// Command Protocol:
// Commands are sent as simple ASCII strings terminated by newline
// Valid commands: "ON", "OFF", "STATUS", "SPEED:<value>", "TEMP"

// ============================================================================
// SYSTEM TIMING
// ============================================================================

#define STATUS_UPDATE_INTERVAL_MS  5000    // Send status updates every 5 seconds
#define TEMP_READ_INTERVAL_MS      2000    // Read temperature every 2 seconds
#define LOOP_DELAY_MS              100     // Main loop delay for non-blocking operation

// ============================================================================
// SERIAL DEBUG CONFIGURATION
// ============================================================================

#define DEBUG_MODE          false   // Set to false to disable debug serial prints
#define SERIAL_BAUD_RATE    9600    // Serial monitor baud rate (same as Bluetooth for simplicity)

// ============================================================================
// SIMULATED SENSOR VALUES (for prototype testing without hardware sensors)
// ============================================================================

#define SIMULATE_TEMPERATURE     false  // Set to true to use simulated temp readings
#define SIMULATED_WATER_TEMP_C   12.0   // Simulated water temperature in Celsius (cold)
#define SIMULATED_SKIN_TEMP_C    34.0   // Simulated skin temperature in Celsius (body temp)

// ============================================================================
// VERSION INFORMATION
// ============================================================================

#define FIRMWARE_VERSION    "1.0.0"
#define DEVICE_NAME         "Testicool_Prototype"

#endif // CONFIG_H
