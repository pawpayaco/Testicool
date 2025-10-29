# Testicool - Hardware Build Guide

> **This guide will walk you through building the complete Testicool device from scratch.**
> You'll have a working prototype with dual temperature monitoring, Bluetooth control, and manual buttons.

---

## 📦 What You Need

### Required Components

| Part | Specs | Qty | Notes |
|------|-------|-----|-------|
| **Arduino Nano** | ATmega328P, 5V, 16MHz | 1 | Any clone works fine |
| **HM-10 BLE Module** | Bluetooth 4.0 | 1 | Get the 4-pin version |
| **DC Water Pump** | 12V, 1-3 L/min | 1 | Mini submersible pump |
| **NTC Thermistors** | 10kΩ @ 25°C | 2 | One for water, one for skin |
| **Momentary Button** | Tactile switch (4-pin) | 1 | Small momentary push button |
| **Potentiometer** | 10kΩ rotary, 3-pin | 1 | Speed control dial |
| **Resistors** | 10kΩ, 1/4W | 2 | For thermistor voltage dividers |
| **Power Supply** | 12V, 2A minimum | 1 | Battery pack or wall adapter |
| **Breadboard** | Full size | 1 | For prototyping |
| **Jumper Wires** | Male-to-male | 20+ | Various lengths |

### Optional (but Recommended)

| Part | Purpose | Notes |
|------|---------|-------|
| **MOSFET** (IRF520) | Pump driver | If pump draws >500mA |
| **Diode** (1N4007) | Flyback protection | Protects Arduino from pump voltage spikes |
| **LEDs** (2x) | Status indicators | Any color |
| **220Ω Resistors** (2x) | LED current limiting | Standard 1/4W |

---

## 🔌 Quick Pin Reference

Here's where everything connects to the Arduino Nano:

```
Arduino Nano Pinout
┌─────────────────────────────┐
│                             │
│   A0 ← Water Thermistor     │
│   A1 ← Skin Thermistor      │
│   A2 ← Speed Potentiometer  │
│                             │
│   D2 ← Toggle Button        │
│        (momentary tactile)  │
│                             │
│   D8 → Pump Enable          │
│   D9 → Pump PWM (speed)     │
│                             │
│   TX → HM-10 RX             │
│   RX ← HM-10 TX             │
│                             │
│  D12 → Power LED (optional) │
│  D13 → BT LED (built-in)    │
│                             │
│  VIN ← 12V power input      │
│  GND ← Ground (common)      │
│                             │
└─────────────────────────────┘
```

---

## 🛠️ Step-by-Step Build

### Step 1: Set Up Power Supply

**What you're doing:** Powering the Arduino and pump from a single 12V source.

```
12V Power Supply
      │
      ├─────────────→ Arduino Nano VIN pin
      │
      └─────────────→ Pump VCC (+12V)

GND ──┬───┬───────→ Common ground for everything
      │   │
   Arduino Pump
```

**Instructions:**
1. Connect 12V+ to Arduino **VIN** pin (the Arduino has a built-in regulator)
2. Connect 12V+ to pump positive wire
3. **CRITICAL:** Connect all GND pins together (Arduino GND, pump GND, power supply GND)

> **Pro tip:** The Arduino Nano's onboard regulator steps 12V down to 5V for the chip. No external regulator needed!

---

### Step 2: Wire the Water Thermistor (A0)

**What you're doing:** Creating a voltage divider to measure water temperature.

```
     +5V (from Arduino)
       │
     [10kΩ Resistor]  ← Pull-up resistor
       │
       ├──────────→ Arduino A0
       │
     [10kΩ NTC]     ← Thermistor
       │
      GND
```

**Instructions:**
1. Insert 10kΩ resistor on breadboard
2. Connect one end to Arduino **5V** pin
3. Connect other end to a new row on breadboard
4. Connect thermistor lead #1 to same row
5. Connect wire from this row to Arduino **A0**
6. Connect thermistor lead #2 to Arduino **GND**

**What's happening:** As water temperature changes, the thermistor resistance changes, which changes the voltage at A0. Arduino reads this voltage and converts it to temperature.

---

### Step 3: Wire the Skin Thermistor (A1)

**What you're doing:** Same as Step 2, but for skin temperature.

```
     +5V
       │
     [10kΩ Resistor]
       │
       ├──────────→ Arduino A1
       │
     [10kΩ NTC]
       │
      GND
```

**Instructions:**
1. Repeat Step 2 exactly, but connect to **A1** instead of A0
2. Use a separate row on the breadboard for the second voltage divider
3. Keep the thermistors physically separate (one will go in water, one on skin)

> **Build tip:** Label the thermistors! Use tape or markers: "WATER" and "SKIN"

---

### Step 4: Wire the Manual Button

**What you're doing:** Adding a single momentary tactile switch that toggles the pump ON/OFF.

```
    D2 ──┬───[Momentary Button]───┬── GND
         │                        │
    (Internal pull-up             │
     enabled in code)             │

     Press once = ON
     Press again = OFF
```

**Instructions:**
1. Take your tactile momentary switch (like the one in the photo - small 4-pin switch)
2. Connect one leg to Arduino **D2**
3. Connect opposite leg to **GND**
4. The button has 4 pins but only 2 are needed (pins on opposite corners)

**How it works:**
- Press button → Pump turns ON
- Press button again → Pump turns OFF
- Each press toggles the state

> **No resistors needed!** The Arduino firmware enables an internal pull-up resistor on D2. When you press the button, it connects D2 to GND, and the firmware detects this as a button press.

---

### Step 5: Wire the Speed Control Potentiometer

**What you're doing:** Adding a rotary dial to manually control pump speed from the bottle lid.

```
         +5V (from Arduino)
          │
          │
    Potentiometer (3-pin)
          │
    ┌─────┼─────┐
    │     │     │
   Pin1  Pin2  Pin3
    │     │     │
   +5V   A2    GND
```

**Instructions:**
1. Your potentiometer has 3 pins (terminals)
2. Connect **outer pin #1** → Arduino **5V**
3. Connect **middle pin (wiper)** → Arduino **A2**
4. Connect **outer pin #3** → Arduino **GND**

**How it works:**
- Turn dial fully counterclockwise → Minimum speed (or off)
- Turn dial fully clockwise → Maximum speed (100%)
- The wiper (middle pin) outputs a voltage between 0-5V
- Arduino reads this voltage and converts it to PWM (0-255)
- Works alongside app slider - either can control speed!

> **Note:** The potentiometer creates a voltage divider. As you turn the dial, the wiper voltage changes from 0V to 5V, which the Arduino maps to pump speed.

---

### Step 6: Wire the HM-10 Bluetooth Module

**What you're doing:** Connecting the Bluetooth module for wireless app control.

```
HM-10          Arduino Nano
┌────────┐     ┌────────┐
│ VCC    │─────│ 5V     │
│ GND    │─────│ GND    │
│ TX     │─────│ RX (D0)│  ← Cross these!
│ RX     │─────│ TX (D1)│  ← TX goes to RX
└────────┘     └────────┘
```

**Instructions:**
1. Connect HM-10 **VCC** → Arduino **5V**
2. Connect HM-10 **GND** → Arduino **GND**
3. Connect HM-10 **TX** → Arduino **RX (D0)**
4. Connect HM-10 **RX** → Arduino **TX (D1)**

> **Remember:** TX (transmit) always connects to RX (receive) on the other device!

**First-time setup (one-time only):**
If the HM-10 is brand new, you may need to configure it:
1. Upload a blank sketch to Arduino (or don't upload anything yet)
2. Open Serial Monitor (9600 baud)
3. Type: `AT` → should reply `OK`
4. Type: `AT+NAMETesticool_Prototype` → sets the device name
5. Done! The firmware will handle the rest.

---

### Step 7: Wire the Pump (Simple Method)

**What you're doing:** Connecting the pump to be controlled by the Arduino.

#### Option A: Direct Connection (for pumps <500mA)

```
Arduino D8 ────→ Pump Enable wire (if it has one)
Arduino D9 ────→ Pump Speed wire (PWM)
Pump GND ──────→ Arduino GND
Pump VCC ──────→ 12V supply
```

Most mini DC pumps just have 2 wires (+/-). For those:

```
Pump + wire ──→ 12V supply
Pump - wire ──→ Arduino GND
Arduino D8 ──→ (not used, code still works)
Arduino D9 ──→ (not used, code still works)
```

> **Note:** Many simple pumps are just ON/OFF. The firmware will still work, you just won't get speed control. That's fine for testing!

#### Option B: MOSFET Driver (for pumps >500mA or for PWM speed control)

```
Arduino D8 ───[220Ω]───→ MOSFET Gate
Arduino D9 (PWM) ───────→ (same gate for speed control)

MOSFET:
  Gate   ← from Arduino D8/D9
  Drain  ← Pump negative wire
  Source ← GND

Pump + ──→ 12V supply
Pump - ──→ MOSFET Drain

[1N4007 Diode across pump: cathode to +12V, anode to pump-]
```

**MOSFET Instructions:**
1. Insert IRF520 MOSFET on breadboard
2. Connect Arduino **D8** → 220Ω resistor → MOSFET **Gate** pin
3. Connect MOSFET **Source** pin → **GND**
4. Connect MOSFET **Drain** pin → Pump negative wire
5. Connect Pump positive wire → 12V supply
6. Optional: Add 1N4007 diode across pump terminals (protects from voltage spikes)

---

### Step 8: Add Status LEDs (Optional)

**What you're doing:** Adding visual indicators for power and Bluetooth status.

```
Arduino D12 ──[220Ω]──┬──[LED+]─┬── GND    (Power LED)
                      │         │
Arduino D13 ──[220Ω]──┬──[LED+]─┬── GND    (Bluetooth LED)
                      │         │
```

**Instructions:**
1. **Power LED (D12):**
   - Connect D12 → 220Ω resistor → LED anode (+, longer leg) → LED cathode (-, shorter leg) → GND
2. **Bluetooth LED (D13):**
   - D13 already has a built-in LED on the Arduino Nano, but you can add an external one the same way

> **LED tip:** If your LED doesn't light up, flip it around (polarity matters!)

---

## ⚡ Final Assembly Checklist

Before powering on, verify all connections:

### Power Connections
- [ ] 12V supply connected to Arduino VIN
- [ ] 12V supply connected to pump
- [ ] All GND pins connected together (Arduino, pump, power supply, HM-10)

### Temperature Sensors
- [ ] Water thermistor: 10kΩ pull-up to 5V, thermistor to GND, junction to A0
- [ ] Skin thermistor: 10kΩ pull-up to 5V, thermistor to GND, junction to A1
- [ ] Thermistors labeled "WATER" and "SKIN"

### Manual Controls
- [ ] Toggle button: D2 to GND (momentary tactile switch)
- [ ] Potentiometer: Outer pins to 5V and GND, wiper (middle) to A2

### Bluetooth
- [ ] HM-10 VCC to 5V
- [ ] HM-10 GND to GND
- [ ] HM-10 TX to Arduino RX
- [ ] HM-10 RX to Arduino TX

### Pump
- [ ] Pump power connected (12V+, GND, or via MOSFET)
- [ ] D8 connected to pump enable (if using MOSFET)
- [ ] D9 connected to pump PWM (if using MOSFET)

---

## 🚀 Upload Firmware & Test

### 1. Upload Firmware

1. Connect Arduino to computer via USB
2. Open Arduino IDE
3. Select **Board:** `Arduino Nano`
4. Select **Processor:** `ATmega328P (Old Bootloader)` (try this first, if upload fails, try without "Old Bootloader")
5. Select correct **Port**
6. Open `firmware/Firmware.ino`
7. Click **Upload** (→ button)

**Expected output:**
```
Compiling sketch...
Uploading...
Done uploading.
```

### 2. Test with Serial Monitor

1. Open **Serial Monitor** (top-right icon in Arduino IDE)
2. Set baud rate to **9600**
3. You should see:
   ```
   [SETUP] Testicool initialization complete
   [SETUP] System ready - awaiting commands
   ```

**Test commands:**
```
STATUS   → Should show: STATUS:{State:OFF,Speed:70%,Runtime:0m,Remaining:30m,WaterTemp:10.0C,SkinTemp:34.5C}
ON       → Pump should turn on, reply: OK
OFF      → Pump should turn off, reply: OK
TEMP     → Should show: TEMP:{Water:10.0C,Skin:34.5C}
```

> **Note:** If you're seeing simulated temperatures (10.0C and 34.5C), that's normal! The firmware is in simulation mode. Real temps will show once you power cycle and the thermistors warm up.

### 3. Test Manual Button

1. Press the **toggle button** (D2)
   - Pump should start
   - Serial monitor shows: `[BUTTON] Toggle button pressed - Pump ON`

2. Press the **toggle button** again (D2)
   - Pump should stop
   - Serial monitor shows: `[BUTTON] Toggle button pressed - Pump OFF`

3. Press repeatedly to verify toggle works reliably

### 4. Test Bluetooth Connection

1. Open the Testicool iOS app
2. Tap "Connect to Device"
3. Look for "Testicool_Prototype" in the list
4. Tap to connect
5. You should see the main control screen
6. Try turning pump ON/OFF from app
7. Check that both temperatures are displayed

---

## 🧪 Temperature Sensor Testing

### Verify Thermistors Are Working

**Water thermistor test:**
1. Disconnect power
2. Place water thermistor in a cup of ice water (0°C)
3. Reconnect power and open Serial Monitor
4. Type `TEMP`
5. Water temp should read close to 0°C (might show 2-5°C, that's fine)

**Skin thermistor test:**
1. Hold skin thermistor in your hand for 30 seconds
2. Type `TEMP` in Serial Monitor
3. Skin temp should read 30-35°C (body temperature)

**If temps show 0.0C or strange values:**
- Check that 10kΩ pull-up resistors are connected to **5V** (not 3.3V)
- Check that thermistors are connected to correct pins (A0 and A1)
- Measure voltage at A0 and A1 with multimeter (should be 2-3V at room temp)

---

## 🔧 Troubleshooting

### Pump Won't Turn On

**Check:**
- [ ] 12V power supply is connected and working
- [ ] Pump is getting 12V (measure with multimeter)
- [ ] If using MOSFET: check Gate, Drain, Source connections
- [ ] If using MOSFET: check that 220Ω resistor is between Arduino and Gate
- [ ] Try connecting pump directly to 12V to verify pump works

### Bluetooth Won't Connect

**Check:**
- [ ] HM-10 LED is blinking (means it's powered and searching)
- [ ] HM-10 VCC connected to 5V (not 3.3V)
- [ ] TX/RX are crossed (Arduino TX → HM-10 RX)
- [ ] Bluetooth is enabled on your phone
- [ ] Try running AT commands to verify HM-10 is responding

### Temperature Shows 0.0°C

**Check:**
- [ ] 10kΩ resistors connected between 5V and A0/A1
- [ ] Thermistors connected between A0/A1 and GND
- [ ] Measure voltage at A0 and A1 (should be 2-3V, not 0V or 5V)
- [ ] Try swapping thermistors to see if problem follows the sensor

### Serial Monitor Shows Garbage Characters

**Check:**
- [ ] Baud rate set to 9600 in Serial Monitor
- [ ] Correct board and processor selected in Arduino IDE
- [ ] USB cable is data-capable (not charge-only)

### App Shows "No devices found"

**Check:**
- [ ] HM-10 is powered (LED blinking)
- [ ] Phone Bluetooth is ON
- [ ] You're not already connected to the HM-10 from Settings app (disconnect it)
- [ ] Try putting phone in Airplane mode, then turn Bluetooth back on
- [ ] HM-10 name is set correctly (use AT+NAME? to check)

---

## 📊 Component Testing Table

Use this table to verify each component individually:

| Component | Test Method | Expected Result | Status |
|-----------|-------------|-----------------|--------|
| Arduino | Connect USB, open Serial Monitor | "System ready" message | ⬜ |
| HM-10 | Send "AT" command | Replies "OK" | ⬜ |
| Water Thermistor | Type "TEMP" in Serial Monitor | Shows reasonable temp (10-30°C) | ⬜ |
| Skin Thermistor | Type "TEMP" in Serial Monitor | Shows reasonable temp (20-35°C) | ⬜ |
| Toggle Button | Press once | Pump turns ON, Serial shows message | ⬜ |
| Toggle Button | Press again | Pump turns OFF, Serial shows message | ⬜ |
| Pump | Send "ON" command | Pump runs | ⬜ |
| Speed Control | Send "SPEED:255" | Pump runs at full speed | ⬜ |
| Bluetooth App | Connect from app | App shows "Connected" | ⬜ |
| Safety Shutoff | Let pump run 30 min | Auto-shutoff occurs | ⬜ |

---

## 🎯 Next Steps: Making It Wearable

Once everything works on breadboard:

### 1. Physical Assembly
- Mount Arduino in waterproof case
- Put water thermistor in water reservoir (946mL bottle)
- Attach skin thermistor to flexible sensor pad for scrotal contact
- Mount ON/OFF buttons on bottle cap
- Secure all wiring with heat shrink or tape

### 2. Thermistor Placement
- **Water thermistor:** Submerge in water reservoir, waterproof with heat shrink
- **Skin thermistor:** Embed in medical-grade silicone pad, place against skin

### 3. Tube Routing
- Connect pump output to cooling garment/wrap
- Route tubing back to reservoir
- Ensure no kinks in tubing
- Test flow rate (should complete circuit in 30-60 seconds)

### 4. Power Options
- **Portable:** Use 12V battery pack (2200mAh = ~2 hours runtime)
- **Stationary:** Use 12V wall adapter (2A minimum)

### 5. Final Testing
- Test in safe environment first (not in sauna yet!)
- Verify both temperatures read correctly
- Check for leaks
- Test full 30-minute session
- Verify safety shutoff works

---

## 📝 Configuration Notes

### Firmware Settings (firmware/config.h)

You can customize these if needed:

```cpp
// Safety limits
#define MAX_RUN_TIME_MS     1800000L  // 30 min (change if needed)
#define OVERHEAT_TEMP_C     40.0      // Skin temp shutoff threshold

// Temperature targets
#define TARGET_TEMP_MIN_C   34.0      // Ideal scrotal temp min
#define TARGET_TEMP_MAX_C   35.0      // Ideal scrotal temp max

// Pump settings
#define PUMP_DEFAULT_SPEED  180       // Default speed (0-255)

// Demo mode (for testing without hardware)
#define SIMULATE_TEMPERATURE     true   // Set to false when sensors working
#define SIMULATED_WATER_TEMP_C   10.0   // Fake water temp
#define SIMULATED_SKIN_TEMP_C    34.5   // Fake skin temp
```

**To disable simulation mode:**
1. Open `firmware/config.h`
2. Change `#define SIMULATE_TEMPERATURE true` to `false`
3. Re-upload firmware
4. Now it will read real sensors!

---

## ✅ Build Complete!

You should now have a fully functional Testicool prototype with:
- ✅ Dual temperature monitoring (water + skin)
- ✅ Bluetooth app control
- ✅ Manual button control
- ✅ PWM pump speed control
- ✅ Safety features (30-min shutoff, overheat protection)

**Time to test it in action!** Start with Demo Mode in the app, then connect to the real device.

---

## 🆘 Still Having Issues?

**Common mistakes:**
1. **Forgot common ground** - All GND must connect together
2. **TX/RX not crossed** - Arduino TX goes to HM-10 RX (and vice versa)
3. **Wrong Arduino board selected** - Try "Old Bootloader" option
4. **Thermistor pull-up to 3.3V instead of 5V** - Must use 5V pin
5. **Pump needs more current** - Use MOSFET driver instead of direct connection

**Debug tips:**
- Test each component individually before connecting everything
- Use Serial Monitor to verify firmware is running
- Measure voltages with multimeter (A0 and A1 should be 2-3V)
- Check HM-10 with AT commands before integrating
- Try the app in Demo Mode first to verify app works

**Check the firmware terminal output:**
The Serial Monitor will show you exactly what's happening:
```
[SETUP] Testicool initialization complete
[BT] Command: Pump turned ON
[BUTTON] Manual ON pressed
[MAIN] Safety shutoff triggered
```

---

## 📐 Complete System Wiring Diagram

Here's the full schematic showing how all components connect together:

```
                           TESTICOOL COMPLETE WIRING DIAGRAM
                           =================================

                              12V POWER SUPPLY (2A min)
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                   12V+                                12V+
                    │                                   │
                    │                              ┌────┴────┐
                    │                              │  PUMP   │
                    │                              │  12V DC │
                    │                              │ 1-3L/min│
    ┌───────────────┴───────────────┐              └────┬────┘
    │      ARDUINO NANO              │                   │
    │      ATmega328P                │                  Pump-
    │                                │                   │
    │  VIN ← 12V                     │              ┌────┴────┐
    │  GND ← Common Ground           │              │ MOSFET  │ (Optional: for >500mA pumps)
    │                                │              │ IRF520  │
    │  ┌─────────────────────────┐   │              │         │
    │  │   ANALOG INPUTS         │   │         Gate├─[220Ω]─┤ D8 (Pump Enable)
    │  │                         │   │        Drain├─────────┤ Pump-
    │  │   A0 ← Water Thermistor │   │       Source└─────────┤ GND
    │  │   A1 ← Skin Thermistor  │   │                       │
    │  │   A2 ← Speed Pot (wiper)│   │                      D9 (PWM Speed - can go to Gate too)
    │  └─────────────────────────┘   │
    │                                │
    │  ┌─────────────────────────┐   │
    │  │   DIGITAL I/O           │   │              ┌──────────────┐
    │  │                         │   │              │   HM-10 BLE  │
    │  │   D2 ← Toggle Button    │   │              │              │
    │  │        (momentary)      │   │         VCC ─┤ 5V           │
    │  │                         │   │         GND ─┤ GND          │
    │  │   D8 → Pump Enable      │   │          TX ─┤ RX (D0)      │
    │  │   D9 → Pump PWM         │   │          RX ─┤ TX (D1)      │
    │  │                         │   │              └──────────────┘
    │  │  D12 → Power LED (opt)  │   │
    │  │  D13 → BT LED (built-in)│   │
    │  │                         │   │
    │  │   TX → HM-10 RX         │   │
    │  │   RX ← HM-10 TX         │   │
    │  │                         │   │
    │  │   5V → Sensors, HM-10   │   │
    │  │  GND → Common Ground    │   │
    │  └─────────────────────────┘   │
    └────────────────────────────────┘
                    │
                   GND
                    │
    ┌───────────────┴──────────────────────────────────────┐
    │                                                       │
    │              COMMON GROUND (CRITICAL!)                │
    │         All GND pins must connect together            │
    │                                                       │
    └───┬──────┬────────┬──────────┬──────────┬───────────┘
        │      │        │          │          │
    Arduino  HM-10   Pump    12V Supply  Buttons/Sensors


    WATER THERMISTOR (A0)              SKIN THERMISTOR (A1)
    =====================              =====================

         +5V                                +5V
          │                                  │
          │                                  │
        ┌─┴─┐                              ┌─┴─┐
        │10k│ Pull-up                      │10k│ Pull-up
        │Ω  │ Resistor                     │Ω  │ Resistor
        └─┬─┘                              └─┬─┘
          │                                  │
          ├───────→ A0                       ├───────→ A1
          │                                  │
        ┌─┴─┐                              ┌─┴─┐
        │10k│ NTC                          │10k│ NTC
        │Ω  │ Thermistor                   │Ω  │ Thermistor
        └─┬─┘ (@25°C)                      └─┬─┘ (@25°C)
          │                                  │
         GND                                GND


    TOGGLE BUTTON (Momentary)          STATUS LEDS (Optional)
    =========================          ======================

    Single toggle button:              Power LED:
    D2 ──┬──[Button]──┬── GND         D12 ──[220Ω]──[LED+|−]── GND
         │            │
    (Internal pull-up)│               Bluetooth LED:
                                      D13 ──[220Ω]──[LED+|−]── GND
    Press once = ON                   (D13 has built-in LED too)
    Press again = OFF


    MOSFET PUMP DRIVER (Optional - for >500mA pumps)
    =================================================

                    Arduino D8 ──[220Ω]──┐
                    Arduino D9 (PWM) ────┤
                                         │
                                    ┌────▼────┐
                                    │ IRF520  │
                                    │ MOSFET  │
                                    │         │
                              Gate ─┤   G     │
                                    │         │
        12V+ ─────────────── Pump+ ─┤   D     │── Pump-
                                    │         │
                              GND ──┤   S     │
                                    └─────────┘

        Flyback Protection Diode (1N4007):
        Place across pump terminals:
        Cathode (stripe) → Pump+
        Anode → Pump-


    SIMPLE PUMP CONNECTION (for <500mA pumps)
    ==========================================

        12V+ ────────────── Pump+

        Pump- ──────────────┬──── GND
                            │
        (D8, D9 not used)   └──── Arduino GND


    PIN SUMMARY
    ===========

    Arduino Nano Connections:
    ├─ Power:
    │  ├─ VIN ← 12V+ from power supply
    │  ├─ GND ← Common ground
    │  └─ 5V → HM-10 VCC, thermistor pull-ups
    │
    ├─ Analog Inputs:
    │  ├─ A0 ← Water thermistor (voltage divider)
    │  └─ A1 ← Skin thermistor (voltage divider)
    │
    ├─ Digital Inputs:
    │  └─ D2 ← Toggle button (momentary tactile, to GND)
    │
    ├─ Digital Outputs:
    │  ├─ D8 → Pump enable (MOSFET gate via 220Ω)
    │  ├─ D9 → Pump PWM speed control
    │  ├─ D12 → Power LED (optional, via 220Ω)
    │  └─ D13 → Bluetooth LED (built-in LED)
    │
    └─ Serial (UART):
       ├─ TX (D1) → HM-10 RX
       └─ RX (D0) ← HM-10 TX


    COMPONENT VALUES
    ================

    Resistors:
    - 10kΩ (×2) - Thermistor pull-ups
    - 220Ω (×3) - MOSFET gate, LED current limiting

    Thermistors:
    - 10kΩ NTC @ 25°C (×2)
    - B-coefficient: 3950K (typical)

    MOSFET:
    - IRF520 or similar N-channel
    - Vds: 100V, Id: 9.2A

    Diode:
    - 1N4007 (flyback protection)
    - 1A, 1000V

    Power:
    - 12V DC, 2A minimum
    - Current draw: ~1.5A (pump) + 0.1A (Arduino/HM-10)


    VOLTAGE MEASUREMENTS (for troubleshooting)
    ==========================================

    Expected voltages at room temperature (~25°C):

    A0 pin: 2.5V - 3.0V (varies with water temp)
    A1 pin: 2.5V - 3.0V (varies with skin temp)

    D8 pin: 0V (pump off), 5V (pump on)
    D9 pin: 0V to 5V PWM (varies with speed)

    HM-10 VCC: 5.0V ±0.1V
    HM-10 TX: 3.3V or 5V (when transmitting)

    MOSFET Gate: 0V (off), 5V (on)
    MOSFET Drain: 12V (off), ~0V (on)

    Pump voltage: 12V ±0.5V


    CRITICAL CONNECTIONS CHECKLIST
    ===============================

    Before powering on, verify:

    Power:
    ☐ 12V+ connected to Arduino VIN
    ☐ 12V+ connected to pump positive
    ☐ ALL grounds connected together (Arduino, HM-10, pump, power supply)

    Thermistors:
    ☐ Water: 10kΩ pull-up to 5V, thermistor to GND, junction to A0
    ☐ Skin: 10kΩ pull-up to 5V, thermistor to GND, junction to A1

    Bluetooth:
    ☐ HM-10 VCC to Arduino 5V
    ☐ HM-10 GND to Arduino GND
    ☐ HM-10 TX crosses to Arduino RX
    ☐ HM-10 RX crosses to Arduino TX

    Button:
    ☐ Toggle button: D2 to GND (momentary tactile switch)

    Pump:
    ☐ Pump+ to 12V supply
    ☐ Pump- to MOSFET drain (or directly to GND if <500mA)
    ☐ D8 to MOSFET gate via 220Ω resistor
    ☐ MOSFET source to GND


    WIRE COLOR SUGGESTIONS
    ======================

    Use consistent colors to make troubleshooting easier:

    RED:    +12V power
    BLACK:  Ground (GND)
    ORANGE: +5V regulated
    YELLOW: Analog signals (A0, A1)
    GREEN:  Digital input (D2 toggle button)
    BLUE:   Serial communication (TX, RX)
    WHITE:  PWM signals (D8, D9)
    PURPLE: LED outputs (D12, D13)


    PHYSICAL LAYOUT TIPS
    ====================

    1. Place Arduino in center of breadboard
    2. Power supply connections on one side
    3. HM-10 module near Arduino TX/RX pins
    4. Thermistor circuits on opposite sides (keep separated)
    5. Buttons on edge for easy access
    6. MOSFET near power supply connections
    7. Keep high-current pump wires short and thick
    8. Bundle signal wires together, separate from power wires
```

---

Good luck building! 🛠️

**Pro tip:** Print this diagram and check off each connection as you make it. Take a photo of your completed breadboard layout for reference when troubleshooting.
