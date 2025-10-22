/*
 * bluetooth.cpp
 * Bluetooth communication module implementation for Testicool device
 *
 * Implements serial command parsing and response formatting for
 * wireless communication with mobile app
 *
 * Team: BME 200/300 Section 301
 */

#include "bluetooth.h"
#include "config.h"
#include "pump.h"

// ============================================================================
// PRIVATE VARIABLES
// ============================================================================

static char commandBuffer[64];     // Buffer for incoming commands
static uint8_t bufferIndex = 0;    // Current position in buffer
static unsigned long lastStatusSend = 0;

// ============================================================================
// BLUETOOTH INITIALIZATION
// ============================================================================

void bluetoothInit() {
  // Initialize serial communication for Bluetooth module
  // For Arduino Nano, this uses hardware Serial (TX=D1, RX=D0)
  Serial.begin(BLUETOOTH_BAUD_RATE);

  // Wait for serial port to be ready
  delay(100);

  #if DEBUG_MODE
    Serial.println(F(""));
    Serial.println(F("========================================"));
    Serial.println(F("  TESTICOOL BLUETOOTH INITIALIZED"));
    Serial.println(F("========================================"));
    Serial.print(F("Device: "));
    Serial.println(F(DEVICE_NAME));
    Serial.print(F("Version: "));
    Serial.println(F(FIRMWARE_VERSION));
    Serial.print(F("Baud Rate: "));
    Serial.println(BLUETOOTH_BAUD_RATE);
    Serial.println(F("========================================"));
    Serial.println(F("Ready for commands..."));
    Serial.println(F(""));
  #endif

  // Clear buffer
  memset(commandBuffer, 0, sizeof(commandBuffer));
  bufferIndex = 0;
}

// ============================================================================
// COMMAND PROCESSING
// ============================================================================

bool bluetoothProcessCommands() {
  // Check if data is available
  if (!Serial.available()) {
    return false;
  }

  // Read incoming bytes
  while (Serial.available()) {
    char inChar = Serial.read();

    // Check for command terminator (newline or carriage return)
    if (inChar == '\n' || inChar == '\r') {
      if (bufferIndex > 0) {
        commandBuffer[bufferIndex] = '\0';  // Null-terminate string

        // Process the command
        processCommand(commandBuffer);

        // Clear buffer for next command
        memset(commandBuffer, 0, sizeof(commandBuffer));
        bufferIndex = 0;

        return true;
      }
    }
    // Add character to buffer if there's space
    else if (bufferIndex < sizeof(commandBuffer) - 1) {
      commandBuffer[bufferIndex++] = inChar;
    }
    // Buffer overflow protection
    else {
      #if DEBUG_MODE
        Serial.println(F("[BT] ERROR: Command buffer overflow"));
      #endif
      memset(commandBuffer, 0, sizeof(commandBuffer));
      bufferIndex = 0;
      bluetoothSendError("CMD_TOO_LONG");
      return false;
    }
  }

  return false;
}

// ============================================================================
// PRIVATE HELPER: COMMAND PARSER
// ============================================================================

static void processCommand(const char* cmd) {
  #if DEBUG_MODE
    Serial.print(F("[BT] Received command: "));
    Serial.println(cmd);
  #endif

  // Convert command to uppercase for case-insensitive comparison
  char upperCmd[64];
  strncpy(upperCmd, cmd, sizeof(upperCmd) - 1);
  upperCmd[sizeof(upperCmd) - 1] = '\0';

  for (int i = 0; upperCmd[i]; i++) {
    upperCmd[i] = toupper(upperCmd[i]);
  }

  // ========== ON COMMAND ==========
  if (strcmp(upperCmd, "ON") == 0) {
    if (pumpOn()) {
      bluetoothSendOK();
      bluetoothSendMessage("PUMP:ON");
      #if DEBUG_MODE
        Serial.println(F("[BT] Command: Pump turned ON"));
      #endif
    } else {
      bluetoothSendError("PUMP_START_FAILED");
    }
  }

  // ========== OFF COMMAND ==========
  else if (strcmp(upperCmd, "OFF") == 0) {
    pumpOff();
    bluetoothSendOK();
    bluetoothSendMessage("PUMP:OFF");
    #if DEBUG_MODE
      Serial.println(F("[BT] Command: Pump turned OFF"));
    #endif
  }

  // ========== STATUS COMMAND ==========
  else if (strcmp(upperCmd, "STATUS") == 0) {
    bluetoothSendStatus();
    #if DEBUG_MODE
      Serial.println(F("[BT] Command: Status requested"));
    #endif
  }

  // ========== TEMP COMMAND ==========
  else if (strcmp(upperCmd, "TEMP") == 0) {
    #if SIMULATE_TEMPERATURE
      float waterTemp = SIMULATED_WATER_TEMP_C;
      float skinTemp = SIMULATED_SKIN_TEMP_C;
    #else
      float waterTemp = readWaterTemperature();
      float skinTemp = readSkinTemperature();
    #endif

    // Send both temperatures
    char tempMsg[64];
    snprintf(tempMsg, sizeof(tempMsg), "TEMP:{Water:%.1fC,Skin:%.1fC}", waterTemp, skinTemp);
    Serial.println(tempMsg);

    #if DEBUG_MODE
      Serial.println(F("[BT] Command: Temperature requested"));
    #endif
  }

  // ========== SPEED COMMAND ==========
  else if (strncmp(upperCmd, "SPEED:", 6) == 0) {
    // Parse speed value
    int speed = atoi(upperCmd + 6);

    if (speed >= 0 && speed <= 255) {
      if (pumpSetSpeed((uint8_t)speed)) {
        bluetoothSendOK();
        char msg[32];
        snprintf(msg, sizeof(msg), "SPEED:%d", speed);
        bluetoothSendMessage(msg);
        #if DEBUG_MODE
          Serial.print(F("[BT] Command: Speed set to "));
          Serial.println(speed);
        #endif
      } else {
        bluetoothSendError("PUMP_NOT_RUNNING");
      }
    } else {
      bluetoothSendError("INVALID_SPEED_VALUE");
    }
  }

  // ========== UNKNOWN COMMAND ==========
  else {
    bluetoothSendError("UNKNOWN_COMMAND");
    #if DEBUG_MODE
      Serial.print(F("[BT] ERROR: Unknown command: "));
      Serial.println(cmd);
    #endif
  }
}

// ============================================================================
// RESPONSE FUNCTIONS
// ============================================================================

void bluetoothSendStatus() {
  // Get pump status
  char pumpStatus[100];
  pumpGetStatusString(pumpStatus, sizeof(pumpStatus));

  // Get both temperatures
  #if SIMULATE_TEMPERATURE
    float waterTemp = SIMULATED_WATER_TEMP_C;
    float skinTemp = SIMULATED_SKIN_TEMP_C;
  #else
    float waterTemp = readWaterTemperature();
    float skinTemp = readSkinTemperature();
  #endif

  // Format complete status message with both temperatures
  char statusMsg[180];
  snprintf(statusMsg, sizeof(statusMsg),
           "STATUS:{%s,WaterTemp:%.1fC,SkinTemp:%.1fC}",
           pumpStatus, waterTemp, skinTemp);

  Serial.println(statusMsg);

  lastStatusSend = millis();
}

void bluetoothSendTemperature(float temperature) {
  char tempMsg[32];
  snprintf(tempMsg, sizeof(tempMsg), "TEMP:%.1f", temperature);
  Serial.println(tempMsg);
}

void bluetoothSendOK() {
  Serial.println(F("OK"));
}

void bluetoothSendError(const char* errorMsg) {
  Serial.print(F("ERROR:"));
  Serial.println(errorMsg);
}

void bluetoothSendMessage(const char* message) {
  Serial.println(message);
}

bool bluetoothIsConnected() {
  // Simple heuristic: if we're receiving data, assume connected
  // More sophisticated connection detection would require
  // module-specific AT commands or handshaking
  return Serial.available() > 0;
}

char* bluetoothGetDeviceInfo(char* buffer, size_t bufferSize) {
  if (buffer == NULL || bufferSize < 50) {
    return NULL;
  }

  snprintf(buffer, bufferSize,
           "Device:%s,FW:%s,Baud:%d",
           DEVICE_NAME, FIRMWARE_VERSION, BLUETOOTH_BAUD_RATE);

  return buffer;
}

// ============================================================================
// EXTERNAL TEMPERATURE READING FUNCTIONS
// ============================================================================

// Temperature reading functions are defined in Firmware.ino
// These forward declarations allow bluetooth.cpp to call them
#if !SIMULATE_TEMPERATURE
extern float readWaterTemperature();
extern float readSkinTemperature();
#endif
