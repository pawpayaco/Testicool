/*
 * bluetooth.h
 * Bluetooth communication module header for Testicool device
 *
 * This module manages wireless communication with mobile app via:
 * - KS-03 / JDY-31 Classic Bluetooth SPP modules (HM-10 clones)
 * - HC-05 / HC-06 Classic Bluetooth modules
 * - Any other UART-based Bluetooth SPP module
 *
 * Communication is done via UART (SoftwareSerial or hardware Serial)
 * using simple ASCII protocol over Bluetooth Serial Port Profile (SPP)
 *
 * Command Protocol:
 *   FROM APP -> DEVICE:
 *     "ON"              - Turn pump ON
 *     "OFF"             - Turn pump OFF
 *     "SPEED:<value>"   - Set pump speed (0-255)
 *     "STATUS"          - Request status update
 *     "TEMP"            - Request temperature reading
 *
 *   FROM DEVICE -> APP:
 *     "OK"              - Command acknowledged
 *     "ERROR:<msg>"     - Error occurred
 *     "STATUS:<data>"   - Status data
 *     "TEMP:<value>"    - Temperature value in Celsius
 *
 * Team: BME 200/300 Section 301
 */

#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include <Arduino.h>

// ============================================================================
// BLUETOOTH CONTROL FUNCTIONS
// ============================================================================

/**
 * Initialize Bluetooth module
 * Sets up serial communication at configured baud rate
 * Call this function once in setup()
 */
void bluetoothInit();

/**
 * Process incoming Bluetooth commands
 * Reads and parses commands from Bluetooth serial buffer
 * Call this function regularly in loop()
 * @return true if a command was processed
 */
bool bluetoothProcessCommands();

/**
 * Send status update via Bluetooth
 * Transmits current pump state, speed, runtime, and temperature
 */
void bluetoothSendStatus();

/**
 * Send temperature reading via Bluetooth
 * @param temperature: temperature value in Celsius
 */
void bluetoothSendTemperature(float temperature);

/**
 * Send acknowledgment response
 */
void bluetoothSendOK();

/**
 * Send error message via Bluetooth
 * @param errorMsg: error message string
 */
void bluetoothSendError(const char* errorMsg);

/**
 * Send custom message via Bluetooth
 * @param message: message string to send
 */
void bluetoothSendMessage(const char* message);

/**
 * Check if Bluetooth module is connected
 * @return true if data is available (device likely connected)
 */
bool bluetoothIsConnected();

/**
 * Get formatted device info string
 * @param buffer: character array to store info string
 * @param bufferSize: size of buffer array
 * @return pointer to buffer
 */
char* bluetoothGetDeviceInfo(char* buffer, size_t bufferSize);

#endif // BLUETOOTH_H
