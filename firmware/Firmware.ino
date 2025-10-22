/*
 * Firmware.ino
 * Main firmware file for Testicool scrotal cooling device
 *
 * DEVICE OVERVIEW:
 * Testicool is a wearable scrotal cooling device designed for use in
 * 80-100°C sauna environments. It maintains scrotal temperature at
 * 34-35°C using a liquid cooling system with pump control.
 *
 * CONTROL MODES:
 * 1. MANUAL: Physical buttons on water bottle lid (ON/OFF)
 * 2. WIRELESS: Bluetooth app control via smartphone
 *
 * HARDWARE:
 * - Arduino Nano (ATmega328P)
 * - DC water pump (12V, PWM controlled)
 * - HC-05/HC-06 Bluetooth module OR HM-10 BLE module
 * - Push buttons (x2) for manual control
 * - Optional: NTC thermistor for temperature monitoring
 * - 946 mL water reservoir with silicone tubing
 *
 * SAFETY FEATURES:
 * - Maximum 30-minute runtime with auto-shutoff
 * - Temperature monitoring (when sensor installed)
 * - Emergency stop capability
 * - Button debouncing
 *
 * Team: BME 200/300 Section 301
 * Client: Dr. Javier Santiago
 * Advisor: Dr. John Puccinelli
 */

#include "config.h"
#include "pump.h"
#include "bluetooth.h"

// ============================================================================
// GLOBAL STATE VARIABLES
// ============================================================================

// Button state tracking for debouncing
static unsigned long lastButtonPressOn = 0;
static unsigned long lastButtonPressOff = 0;
static bool lastButtonStateOn = HIGH;
static bool lastButtonStateOff = HIGH;

// Timing variables for non-blocking operation
static unsigned long lastStatusUpdate = 0;
static unsigned long lastTempRead = 0;

// ============================================================================
// ARDUINO SETUP FUNCTION
// ============================================================================

void setup() {
  // Initialize serial communication for Bluetooth
  bluetoothInit();

  // Initialize pump hardware
  pumpInit();

  // Configure manual control button pins
  pinMode(BUTTON_ON_PIN, INPUT_PULLUP);   // Internal pull-up resistor
  pinMode(BUTTON_OFF_PIN, INPUT_PULLUP);  // Internal pull-up resistor

  // Configure optional status LED pins
  #ifdef LED_POWER_PIN
    pinMode(LED_POWER_PIN, OUTPUT);
    digitalWrite(LED_POWER_PIN, HIGH);  // Power LED on
  #endif

  #ifdef LED_BLUETOOTH_PIN
    pinMode(LED_BLUETOOTH_PIN, OUTPUT);
    digitalWrite(LED_BLUETOOTH_PIN, LOW);
  #endif

  // Configure temperature sensor pins (if used)
  #if !SIMULATE_TEMPERATURE
    pinMode(TEMP_SENSOR_WATER_PIN, INPUT);
    pinMode(TEMP_SENSOR_SKIN_PIN, INPUT);
  #endif

  #if DEBUG_MODE
    Serial.println(F("[SETUP] Testicool initialization complete"));
    Serial.println(F("[SETUP] System ready - awaiting commands"));
    Serial.println(F(""));
  #endif

  // Brief startup indication
  blinkLED(LED_BLUETOOTH_PIN, 3, 200);  // 3 blinks to indicate ready
}

// ============================================================================
// ARDUINO MAIN LOOP
// ============================================================================

void loop() {
  // Get current time for non-blocking timing
  unsigned long currentMillis = millis();

  // ========== 1. CHECK MANUAL BUTTONS ==========
  checkManualButtons();

  // ========== 2. PROCESS BLUETOOTH COMMANDS ==========
  if (bluetoothProcessCommands()) {
    // Command was processed - blink BT LED
    #ifdef LED_BLUETOOTH_PIN
      digitalWrite(LED_BLUETOOTH_PIN, HIGH);
      delay(50);
      digitalWrite(LED_BLUETOOTH_PIN, LOW);
    #endif
  }

  // ========== 3. SAFETY CHECK ==========
  // Check pump safety conditions (max runtime, etc.)
  if (pumpCheckSafety()) {
    // Safety shutoff occurred - notify via Bluetooth
    bluetoothSendError("SAFETY_SHUTOFF");
    bluetoothSendMessage("Maximum runtime exceeded");

    #if DEBUG_MODE
      Serial.println(F("[MAIN] Safety shutoff triggered"));
    #endif
  }

  // ========== 4. PERIODIC STATUS UPDATES ==========
  // Send status update every STATUS_UPDATE_INTERVAL_MS
  if (currentMillis - lastStatusUpdate >= STATUS_UPDATE_INTERVAL_MS) {
    lastStatusUpdate = currentMillis;

    // Only send automatic updates if pump is running
    if (pumpGetState() == PUMP_ON) {
      #if DEBUG_MODE
        Serial.println(F("[MAIN] Sending periodic status update"));
      #endif
      bluetoothSendStatus();
    }
  }

  // ========== 5. TEMPERATURE MONITORING ==========
  #if !SIMULATE_TEMPERATURE
  if (currentMillis - lastTempRead >= TEMP_READ_INTERVAL_MS) {
    lastTempRead = currentMillis;

    float waterTemp = readWaterTemperature();
    float skinTemp = readSkinTemperature();

    // Check for temperature-based safety conditions
    if (skinTemp > OVERHEAT_TEMP_C && pumpGetState() == PUMP_ON) {
      pumpEmergencyStop();
      bluetoothSendError("OVERHEAT");
      char msg[64];
      snprintf(msg, sizeof(msg), "Skin temperature too high: %.1fC", skinTemp);
      bluetoothSendMessage(msg);

      #if DEBUG_MODE
        Serial.print(F("[MAIN] OVERHEAT DETECTED: "));
        Serial.print(skinTemp);
        Serial.println(F("C"));
      #endif
    }

    // Optional: Check if water is too warm (not cooling effectively)
    if (waterTemp > 30.0 && pumpGetState() == PUMP_ON) {
      #if DEBUG_MODE
        Serial.print(F("[WARNING] Water temp: "));
        Serial.print(waterTemp);
        Serial.println(F("C - may not cool effectively"));
      #endif
    }
  }
  #endif

  // ========== 6. LED STATUS INDICATION ==========
  updateStatusLEDs();

  // Small delay for loop stability (non-blocking)
  delay(LOOP_DELAY_MS);
}

// ============================================================================
// MANUAL BUTTON HANDLING
// ============================================================================

void checkManualButtons() {
  unsigned long currentMillis = millis();

  // ========== ON BUTTON ==========
  bool buttonStateOn = digitalRead(BUTTON_ON_PIN);

  // Check for button press (LOW = pressed with pull-up resistor)
  if (buttonStateOn == LOW && lastButtonStateOn == HIGH) {
    // Debounce check
    if (currentMillis - lastButtonPressOn > BUTTON_DEBOUNCE_MS) {
      lastButtonPressOn = currentMillis;

      // Turn pump ON
      if (pumpOn()) {
        bluetoothSendMessage("MANUAL:ON");
        #if DEBUG_MODE
          Serial.println(F("[BUTTON] Manual ON pressed"));
        #endif
      }
    }
  }

  lastButtonStateOn = buttonStateOn;

  // ========== OFF BUTTON ==========
  bool buttonStateOff = digitalRead(BUTTON_OFF_PIN);

  // Check for button press (LOW = pressed with pull-up resistor)
  if (buttonStateOff == LOW && lastButtonStateOff == HIGH) {
    // Debounce check
    if (currentMillis - lastButtonPressOff > BUTTON_DEBOUNCE_MS) {
      lastButtonPressOff = currentMillis;

      // Turn pump OFF
      pumpOff();
      bluetoothSendMessage("MANUAL:OFF");

      #if DEBUG_MODE
        Serial.println(F("[BUTTON] Manual OFF pressed"));
      #endif
    }
  }

  lastButtonStateOff = buttonStateOff;
}

// ============================================================================
// LED STATUS INDICATION
// ============================================================================

void updateStatusLEDs() {
  #ifdef LED_POWER_PIN
    // Power LED always on
    digitalWrite(LED_POWER_PIN, HIGH);
  #endif

  #ifdef LED_BLUETOOTH_PIN
    // Bluetooth LED indicates pump state
    PumpState state = pumpGetState();

    if (state == PUMP_ON) {
      // Solid on when pump running
      digitalWrite(LED_BLUETOOTH_PIN, HIGH);
    } else if (state == PUMP_ERROR) {
      // Fast blink when error
      digitalWrite(LED_BLUETOOTH_PIN, (millis() / 200) % 2);
    } else {
      // Off when pump off
      digitalWrite(LED_BLUETOOTH_PIN, LOW);
    }
  #endif
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void blinkLED(uint8_t pin, uint8_t times, unsigned int delayMs) {
  #ifdef LED_BLUETOOTH_PIN
    for (uint8_t i = 0; i < times; i++) {
      digitalWrite(pin, HIGH);
      delay(delayMs);
      digitalWrite(pin, LOW);
      delay(delayMs);
    }
  #endif
}

#if !SIMULATE_TEMPERATURE
// Helper function to read temperature from a thermistor on any analog pin
float readThermistorTemperature(int pin) {
  // Read analog value from thermistor
  int rawValue = analogRead(pin);

  // Avoid division by zero
  if (rawValue == 0) rawValue = 1;

  // Convert ADC reading to temperature using Steinhart-Hart equation
  // This is for a 10K NTC thermistor with 10K series resistor
  // Adjust coefficients for your specific thermistor

  float resistance = 10000.0 * ((1023.0 / rawValue) - 1.0);

  // Simplified Steinhart-Hart equation
  float steinhart;
  steinhart = resistance / 10000.0;           // (R/Ro)
  steinhart = log(steinhart);                 // ln(R/Ro)
  steinhart /= 3950.0;                        // 1/B * ln(R/Ro), B=3950 typical
  steinhart += 1.0 / (25.0 + 273.15);         // + (1/To)
  steinhart = 1.0 / steinhart;                // Invert
  steinhart -= 273.15;                        // Convert to Celsius

  return steinhart;
}

float readWaterTemperature() {
  return readThermistorTemperature(TEMP_SENSOR_WATER_PIN);
}

float readSkinTemperature() {
  return readThermistorTemperature(TEMP_SENSOR_SKIN_PIN);
}
#endif

// ============================================================================
// INTERRUPT SERVICE ROUTINES (Optional Enhancement)
// ============================================================================

// Uncomment and modify if you want to use hardware interrupts for buttons
// This provides faster, more reliable button response

/*
void buttonOnISR() {
  static unsigned long lastInterrupt = 0;
  unsigned long currentTime = millis();

  // Debounce
  if (currentTime - lastInterrupt > BUTTON_DEBOUNCE_MS) {
    lastInterrupt = currentTime;
    pumpOn();
  }
}

void buttonOffISR() {
  static unsigned long lastInterrupt = 0;
  unsigned long currentTime = millis();

  // Debounce
  if (currentTime - lastInterrupt > BUTTON_DEBOUNCE_MS) {
    lastInterrupt = currentTime;
    pumpOff();
  }
}

// In setup(), add:
// attachInterrupt(digitalPinToInterrupt(BUTTON_ON_PIN), buttonOnISR, FALLING);
// attachInterrupt(digitalPinToInterrupt(BUTTON_OFF_PIN), buttonOffISR, FALLING);
*/
