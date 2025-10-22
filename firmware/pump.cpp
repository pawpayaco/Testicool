/*
 * pump.cpp
 * Pump control module implementation for Testicool device
 *
 * Implements all pump control logic, safety features, and state management
 *
 * Team: BME 200/300 Section 301
 */

#include "pump.h"
#include "config.h"

// ============================================================================
// PRIVATE STATE VARIABLES
// ============================================================================

static PumpState currentState = PUMP_OFF;
static uint8_t currentSpeed = 0;
static unsigned long pumpStartTime = 0;
static unsigned long lastSafetyCheck = 0;

// ============================================================================
// PUMP INITIALIZATION
// ============================================================================

void pumpInit() {
  // Configure pump control pins
  pinMode(PUMP_PWM_PIN, OUTPUT);
  pinMode(PUMP_ENABLE_PIN, OUTPUT);

  // Initialize pump to OFF state
  digitalWrite(PUMP_ENABLE_PIN, LOW);
  analogWrite(PUMP_PWM_PIN, 0);

  currentState = PUMP_OFF;
  currentSpeed = 0;
  pumpStartTime = 0;

  #if DEBUG_MODE
    Serial.println(F("[PUMP] Initialized - State: OFF"));
  #endif
}

// ============================================================================
// PUMP CONTROL FUNCTIONS
// ============================================================================

bool pumpOn(uint8_t speed) {
  // Use default speed if not specified (0 means use default)
  if (speed == 0) {
    speed = PUMP_DEFAULT_SPEED;
  }

  // Constrain speed to valid range
  speed = constrain(speed, PUMP_MIN_SPEED, PUMP_MAX_SPEED);

  // Check if already in error state
  if (currentState == PUMP_ERROR) {
    #if DEBUG_MODE
      Serial.println(F("[PUMP] ERROR: Cannot start pump - error state active"));
    #endif
    return false;
  }

  // Enable pump
  digitalWrite(PUMP_ENABLE_PIN, HIGH);
  analogWrite(PUMP_PWM_PIN, speed);

  // Update state
  currentState = PUMP_ON;
  currentSpeed = speed;
  pumpStartTime = millis();

  #if DEBUG_MODE
    Serial.print(F("[PUMP] Started - Speed: "));
    Serial.print(speed);
    Serial.print(F(" ("));
    Serial.print((speed * 100) / 255);
    Serial.println(F("%)"));
  #endif

  return true;
}

void pumpOff() {
  // Disable pump
  digitalWrite(PUMP_ENABLE_PIN, LOW);
  analogWrite(PUMP_PWM_PIN, 0);

  // Update state
  currentState = PUMP_OFF;
  currentSpeed = 0;
  pumpStartTime = 0;

  #if DEBUG_MODE
    Serial.println(F("[PUMP] Stopped"));
  #endif
}

bool pumpSetSpeed(uint8_t speed) {
  // Check if pump is running
  if (currentState != PUMP_ON) {
    #if DEBUG_MODE
      Serial.println(F("[PUMP] ERROR: Cannot set speed - pump is not running"));
    #endif
    return false;
  }

  // Constrain speed to valid range
  speed = constrain(speed, PUMP_MIN_SPEED, PUMP_MAX_SPEED);

  // Update PWM
  analogWrite(PUMP_PWM_PIN, speed);
  currentSpeed = speed;

  #if DEBUG_MODE
    Serial.print(F("[PUMP] Speed changed to: "));
    Serial.print(speed);
    Serial.print(F(" ("));
    Serial.print((speed * 100) / 255);
    Serial.println(F("%)"));
  #endif

  return true;
}

uint8_t pumpGetSpeed() {
  return currentSpeed;
}

PumpState pumpGetState() {
  return currentState;
}

unsigned long pumpGetRuntime() {
  if (currentState == PUMP_ON && pumpStartTime > 0) {
    return millis() - pumpStartTime;
  }
  return 0;
}

unsigned long pumpGetRemainingTime() {
  if (currentState != PUMP_ON) {
    return 0;
  }

  unsigned long runtime = pumpGetRuntime();

  if (runtime >= MAX_RUN_TIME_MS) {
    return 0;
  }

  return MAX_RUN_TIME_MS - runtime;
}

// ============================================================================
// SAFETY FUNCTIONS
// ============================================================================

bool pumpCheckSafety() {
  // Only check if pump is running
  if (currentState != PUMP_ON) {
    return false;
  }

  // Throttle safety checks to avoid excessive checking
  unsigned long currentTime = millis();
  if (currentTime - lastSafetyCheck < 1000) {  // Check once per second
    return false;
  }
  lastSafetyCheck = currentTime;

  // Check maximum runtime
  unsigned long runtime = pumpGetRuntime();

  if (runtime >= MAX_RUN_TIME_MS) {
    #if DEBUG_MODE
      Serial.println(F("[PUMP] SAFETY: Maximum runtime exceeded - auto-stopping"));
      Serial.print(F("[PUMP] Runtime: "));
      Serial.print(runtime / 60000);
      Serial.println(F(" minutes"));
    #endif

    pumpOff();
    currentState = PUMP_ERROR;
    return true;
  }

  // Additional safety checks can be added here:
  // - Temperature sensor readings
  // - Flow sensor readings
  // - Electrical current monitoring

  return false;
}

void pumpResetError() {
  if (currentState == PUMP_ERROR) {
    currentState = PUMP_OFF;

    #if DEBUG_MODE
      Serial.println(F("[PUMP] Error state cleared"));
    #endif
  }
}

void pumpEmergencyStop() {
  #if DEBUG_MODE
    Serial.println(F("[PUMP] EMERGENCY STOP ACTIVATED"));
  #endif

  // Immediate hardware shutoff
  digitalWrite(PUMP_ENABLE_PIN, LOW);
  analogWrite(PUMP_PWM_PIN, 0);

  // Set error state
  currentState = PUMP_ERROR;
  currentSpeed = 0;
}

// ============================================================================
// STATUS REPORTING
// ============================================================================

char* pumpGetStatusString(char* buffer, size_t bufferSize) {
  if (buffer == NULL || bufferSize < 50) {
    return NULL;
  }

  const char* stateStr;
  switch (currentState) {
    case PUMP_OFF:
      stateStr = "OFF";
      break;
    case PUMP_ON:
      stateStr = "ON";
      break;
    case PUMP_ERROR:
      stateStr = "ERROR";
      break;
    default:
      stateStr = "UNKNOWN";
  }

  if (currentState == PUMP_ON) {
    unsigned long runtime = pumpGetRuntime();
    unsigned long remainingTime = pumpGetRemainingTime();

    snprintf(buffer, bufferSize,
             "State:%s,Speed:%d%%,Runtime:%lum,Remaining:%lum",
             stateStr,
             (currentSpeed * 100) / 255,
             runtime / 60000,
             remainingTime / 60000);
  } else {
    snprintf(buffer, bufferSize, "State:%s", stateStr);
  }

  return buffer;
}
