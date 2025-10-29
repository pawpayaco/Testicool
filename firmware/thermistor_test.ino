/*
 * Thermistor Test & Calibration Tool
 *
 * This sketch helps diagnose and calibrate NTC thermistors
 * Connect thermistors to A0 and A1 with 10kΩ pull-up resistors
 */

#define WATER_PIN A0
#define SKIN_PIN A1

// Thermistor parameters
#define SERIES_RESISTOR 10000.0  // 10kΩ pull-up resistor
#define THERMISTOR_NOMINAL 10000.0  // 10kΩ thermistor at 25°C
#define TEMPERATURE_NOMINAL 25.0  // Nominal temperature (°C)
#define B_COEFFICIENT 3950.0  // Beta coefficient (typical for 10kΩ NTC)

void setup() {
  Serial.begin(9600);
  Serial.println("========================================");
  Serial.println("  Thermistor Test & Calibration");
  Serial.println("========================================");
  Serial.println();
  delay(1000);
}

void loop() {
  // Read ADC values
  int waterADC = analogRead(WATER_PIN);
  int skinADC = analogRead(SKIN_PIN);

  // Calculate resistances
  float waterResistance = calculateResistance(waterADC);
  float skinResistance = calculateResistance(skinADC);

  // Calculate temperatures using Steinhart-Hart equation
  float waterTemp = calculateTemperature(waterResistance);
  float skinTemp = calculateTemperature(skinResistance);

  // Display results
  Serial.println("========================================");
  Serial.println("WATER THERMISTOR (A0):");
  Serial.print("  ADC Value: ");
  Serial.println(waterADC);
  Serial.print("  Resistance: ");
  Serial.print(waterResistance, 0);
  Serial.println(" Ω");
  Serial.print("  Temperature: ");
  Serial.print(waterTemp, 1);
  Serial.println(" °C");

  Serial.println();
  Serial.println("SKIN THERMISTOR (A1):");
  Serial.print("  ADC Value: ");
  Serial.println(skinADC);
  Serial.print("  Resistance: ");
  Serial.print(skinResistance, 0);
  Serial.println(" Ω");
  Serial.print("  Temperature: ");
  Serial.print(skinTemp, 1);
  Serial.println(" °C");

  Serial.println("========================================");
  Serial.println();

  // Diagnostics
  if (waterADC < 50) {
    Serial.println("⚠️  WATER: ADC too low - check for short to GND");
  } else if (waterADC > 950) {
    Serial.println("⚠️  WATER: ADC too high - check pull-up resistor or thermistor connection");
  }

  if (skinADC < 50) {
    Serial.println("⚠️  SKIN: ADC too low - check for short to GND");
  } else if (skinADC > 950) {
    Serial.println("⚠️  SKIN: ADC too high - check pull-up resistor or thermistor connection");
  }

  // Expected room temperature range
  if (waterTemp < 15.0 || waterTemp > 30.0) {
    Serial.println("⚠️  WATER: Temperature outside room temp range (15-30°C)");
    Serial.println("    → Check resistor value or thermistor type");
  }

  if (skinTemp < 15.0 || skinTemp > 30.0) {
    Serial.println("⚠️  SKIN: Temperature outside room temp range (15-30°C)");
    Serial.println("    → Check resistor value or thermistor type");
  }

  Serial.println();
  Serial.println("📝 CALIBRATION TIPS:");
  Serial.println("  - Room temp should read 20-25°C");
  Serial.println("  - ADC should be 400-600 at room temp");
  Serial.println("  - Resistance should be ~10kΩ at 25°C");
  Serial.println("  - Touch thermistor → temp should rise to 30-35°C");
  Serial.println();

  delay(2000);  // Update every 2 seconds
}

float calculateResistance(int adc) {
  if (adc == 0) return 0;
  if (adc >= 1023) return 999999;

  // Voltage divider: R_thermistor = R_series * (1023/ADC - 1)
  float resistance = SERIES_RESISTOR * ((1023.0 / (float)adc) - 1.0);
  return resistance;
}

float calculateTemperature(float resistance) {
  if (resistance <= 0) return -999;

  // Steinhart-Hart equation (simplified B-parameter equation)
  float steinhart;
  steinhart = resistance / THERMISTOR_NOMINAL;  // (R/Ro)
  steinhart = log(steinhart);  // ln(R/Ro)
  steinhart /= B_COEFFICIENT;  // 1/B * ln(R/Ro)
  steinhart += 1.0 / (TEMPERATURE_NOMINAL + 273.15);  // + (1/To)
  steinhart = 1.0 / steinhart;  // Invert
  steinhart -= 273.15;  // Convert to Celsius

  return steinhart;
}
