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

#define BLUETOOTH_BAUD_RATE 9600   // Standard baud rate for HC-05/HC-06 modules
                                    // For BLE modules (HM-10), also typically 9600

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

#define DEBUG_MODE          true    // Set to false to disable debug serial prints
#define SERIAL_BAUD_RATE    9600    // Serial monitor baud rate (same as Bluetooth for simplicity)

// ============================================================================
// SIMULATED SENSOR VALUES (for prototype testing without hardware sensors)
// ============================================================================

#define SIMULATE_TEMPERATURE     true   // Set to true to use simulated temp readings
#define SIMULATED_WATER_TEMP_C   10.0   // Simulated water temperature in Celsius (cold)
#define SIMULATED_SKIN_TEMP_C    34.5   // Simulated skin temperature in Celsius (body temp)

// ============================================================================
// VERSION INFORMATION
// ============================================================================

#define FIRMWARE_VERSION    "1.0.0"
#define DEVICE_NAME         "Testicool_Prototype"

#endif // CONFIG_H
