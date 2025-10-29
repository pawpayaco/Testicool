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

#if USE_SOFTWARE_SERIAL
  #include <SoftwareSerial.h>
  SoftwareSerial BTSerial(BT_RX_PIN, BT_TX_PIN); // RX, TX
  #define BT_SERIAL BTSerial
#else
  #define BT_SERIAL Serial
#endif

// ============================================================================
// FORWARD DECLARATIONS
// ============================================================================

static void processCommand(const char* cmd);

// Forward declarations for temperature functions defined in Testicool.ino
#if !SIMULATE_TEMPERATURE
extern float readWaterTemperature();
extern float readSkinTemperature();
#endif

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
  #if USE_SOFTWARE_SERIAL
    // Using SoftwareSerial (not used with DSD TECH)
    BTSerial.begin(BLUETOOTH_BAUD_RATE);
    // Also initialize hardware Serial for debug output
    #if DEBUG_MODE
      Serial.begin(9600);
      delay(100);
      Serial.println(F(""));
      Serial.println(F("========================================"));
      Serial.println(F("  TESTICOOL BLUETOOTH INITIALIZED"));
      Serial.println(F("========================================"));
      Serial.println(F("Mode: SoftwareSerial (legacy)"));
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
  #else
    // Using hardware Serial on D0/D1 (DSD TECH BLE module)
    Serial.begin(BLUETOOTH_BAUD_RATE);
    delay(100);
    // No debug output available when using hardware Serial for Bluetooth
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
  if (!BT_SERIAL.available()) {
    return false;
  }

  // Read incoming bytes
  while (BT_SERIAL.available()) {
    char inChar = BT_SERIAL.read();

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
    // Note: Arduino's snprintf doesn't support %f, so we use dtostrf
    char waterTempStr[10];
    char skinTempStr[10];
    dtostrf(waterTemp, 4, 1, waterTempStr);
    dtostrf(skinTemp, 4, 1, skinTempStr);

    char tempMsg[64];
    snprintf(tempMsg, sizeof(tempMsg), "TEMP:{Water:%sC,Skin:%sC}", waterTempStr, skinTempStr);
    BT_SERIAL.println(tempMsg);

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

    #if DEBUG_MODE
      Serial.print(F("[BT] Water temp: "));
      Serial.print(waterTemp);
      Serial.print(F("C, Skin temp: "));
      Serial.print(skinTemp);
      Serial.println(F("C"));
    #endif
  #endif

  // Format complete status message with both temperatures
  // Note: Arduino's snprintf doesn't support %f, so we use dtostrf to convert floats
  char waterTempStr[10];
  char skinTempStr[10];
  dtostrf(waterTemp, 4, 1, waterTempStr);  // Convert float to string with 1 decimal place
  dtostrf(skinTemp, 4, 1, skinTempStr);

  char statusMsg[180];
  snprintf(statusMsg, sizeof(statusMsg),
           "STATUS:{%s,WaterTemp:%sC,SkinTemp:%sC}",
           pumpStatus, waterTempStr, skinTempStr);

  BT_SERIAL.println(statusMsg);

  lastStatusSend = millis();
}

void bluetoothSendTemperature(float temperature) {
  // Note: Arduino's snprintf doesn't support %f, so we use dtostrf
  char tempStr[10];
  dtostrf(temperature, 4, 1, tempStr);

  char tempMsg[32];
  snprintf(tempMsg, sizeof(tempMsg), "TEMP:%s", tempStr);
  BT_SERIAL.println(tempMsg);
}

void bluetoothSendOK() {
  BT_SERIAL.println(F("OK"));
}

void bluetoothSendError(const char* errorMsg) {
  BT_SERIAL.print(F("ERROR:"));
  BT_SERIAL.println(errorMsg);
}

void bluetoothSendMessage(const char* message) {
  BT_SERIAL.println(message);
}

bool bluetoothIsConnected() {
  // Simple heuristic: if we're receiving data, assume connected
  // More sophisticated connection detection would require
  // module-specific AT commands or handshaking
  return BT_SERIAL.available() > 0;
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

