/*
 * pump.h
 * Pump control module header for Testicool device
 *
 * This module manages all pump operations including:
 * - Pump initialization
 * - Speed control (PWM)
 * - ON/OFF control
 * - Safety timers and auto-shutoff
 * - Pump state monitoring
 *
 * Team: BME 200/300 Section 301
 */

#ifndef PUMP_H
#define PUMP_H

#include <Arduino.h>

// Pump state enumeration
enum PumpState {
  PUMP_OFF = 0,
  PUMP_ON = 1,
  PUMP_ERROR = 2
};

// ============================================================================
// PUMP CONTROL FUNCTIONS
// ============================================================================

/**
 * Initialize pump hardware and set default state
 * Configures PWM pins, enable pins, and sets pump to OFF
 * Call this function once in setup()
 */
void pumpInit();

/**
 * Turn pump ON at specified speed
 * @param speed: PWM value 0-255 (default uses PUMP_DEFAULT_SPEED from config.h)
 * @return true if pump started successfully, false if error
 */
bool pumpOn(uint8_t speed = 0);

/**
 * Turn pump OFF
 * Immediately stops pump operation and resets timers
 */
void pumpOff();

/**
 * Set pump speed while running
 * @param speed: PWM value 0-255
 * @return true if speed was set, false if pump is off or error
 */
bool pumpSetSpeed(uint8_t speed);

/**
 * Get current pump speed
 * @return current PWM value (0-255), 0 if pump is off
 */
uint8_t pumpGetSpeed();

/**
 * Get current pump state
 * @return PumpState enum value (PUMP_OFF, PUMP_ON, PUMP_ERROR)
 */
PumpState pumpGetState();

/**
 * Get pump runtime in milliseconds
 * @return time since pump was turned on (milliseconds)
 */
unsigned long pumpGetRuntime();

/**
 * Get remaining runtime before auto-shutoff
 * @return milliseconds remaining, 0 if pump is off
 */
unsigned long pumpGetRemainingTime();

/**
 * Check if pump has exceeded maximum runtime
 * Automatically shuts off pump if MAX_RUN_TIME_MS is exceeded
 * Call this function regularly in loop()
 * @return true if pump was auto-stopped due to timeout
 */
bool pumpCheckSafety();

/**
 * Reset pump error state
 * Call after addressing error condition
 */
void pumpResetError();

/**
 * Emergency stop - immediate pump shutoff
 * Used for critical safety situations
 */
void pumpEmergencyStop();

/**
 * Get pump status as formatted string
 * @param buffer: character array to store status string
 * @param bufferSize: size of buffer array
 * @return pointer to buffer
 */
char* pumpGetStatusString(char* buffer, size_t bufferSize);

#endif // PUMP_H
