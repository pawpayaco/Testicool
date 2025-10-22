# Testicool iOS App - Quick Start Guide

## ✨ Your Xcode Project is Ready!

The complete iOS app has been created at:
```
/Users/oscarmullikin/Testicool/TesticoolApp/Testicool.xcodeproj
```

---

## 🚀 Open in Xcode

The project should already be open in Xcode. If not, run:

```bash
open /Users/oscarmullikin/Testicool/TesticoolApp/Testicool.xcodeproj
```

---

## 📱 How to See the App Preview

### Option 1: Live Preview in Xcode (Fastest)

1. In Xcode, open any View file from the left sidebar:
   - `ContentView.swift`
   - `Views/PumpControlView.swift`
   - `Views/StatusView.swift`

2. Look for the canvas on the right side
   - If you don't see it, go to **Editor → Canvas** (⌘⌥↩)

3. Click the **"Resume"** button in the canvas
   - This will show a live preview of the UI
   - You can interact with it!

4. Try different views to see all the screens

### Option 2: Run in Simulator

1. At the top of Xcode, click the device selector (next to the Play button)

2. Choose any iPhone simulator (e.g., "iPhone 15 Pro")

3. Click the **Play button** (▶) or press **⌘R**

4. The simulator will launch and show your app!

**Note:** Bluetooth won't work in the simulator, but you can see the full UI.

### Option 3: Run on Your iPhone (for Full Testing)

1. Connect your iPhone via USB

2. Select your iPhone from the device selector

3. Go to **Testicool (project) → Signing & Capabilities**

4. Choose your development team

5. Click Play (▶)

6. The app will install on your iPhone!

---

## 🎨 What You'll See

### Connection Screen
- Clean white interface with Testicool logo
- Big "Connect to Device" button
- Connection status indicator

### Control Screen (after connecting)
- **Large ON/OFF button** - Giant circular button (green when off, red when on)
- **Speed slider** - Adjust pump speed 0-100%
- **Status card** - Circular progress ring showing session time
- **Temperature display** - Real-time temperature with color-coded status
- **Runtime tracking** - Shows elapsed time and remaining time

### Settings Screen
- Device information
- Safety guidelines
- Usage instructions
- About page with team credits

---

## 🔧 Project Structure

```
TesticoolApp/
├── Testicool.xcodeproj          ← Open this in Xcode
├── Testicool/
│   ├── TesticoolApp.swift       ← App entry point
│   ├── ContentView.swift        ← Main view
│   ├── Info.plist               ← Bluetooth permissions
│   ├── Managers/
│   │   └── BluetoothManager.swift  ← Handles all Bluetooth
│   ├── Models/
│   │   ├── DeviceState.swift      ← Device state model
│   │   └── StatusParser.swift     ← Parses firmware responses
│   └── Views/
│       ├── PumpControlView.swift  ← Main control UI
│       ├── StatusView.swift       ← Session timer
│       └── SettingsView.swift     ← Settings screen
└── README.md                    ← Full documentation
```

---

## ✅ Testing Checklist

### In Simulator (No Hardware Needed)
- [x] App launches
- [x] Connection screen displays
- [x] UI looks clean and minimal
- [x] All buttons and sliders visible
- [x] Dark mode works (toggle in simulator)

### With Arduino Device
- [ ] Discovers "Testicool_Prototype" device
- [ ] Connects successfully
- [ ] ON button starts pump
- [ ] OFF button stops pump
- [ ] Speed slider adjusts pump speed
- [ ] Temperature updates every 5 seconds
- [ ] Manual button presses show in app
- [ ] Safety shutoff alerts display

---

## 🐛 Common Issues

### "No such module CoreBluetooth"
- **Fix:** Clean build folder (⌘⇧K) and rebuild

### Preview not showing
- **Fix:** Click "Resume" in the canvas area
- Or: Restart Xcode

### Can't find devices
- **Fix:** You MUST use a real iPhone (simulator can't do Bluetooth)
- Ensure Arduino is powered on
- Check that Bluetooth permissions are granted

### Build errors
- **Fix:** Make sure all files are added to the Testicool target
- Check Signing & Capabilities has a team selected

---

## 📖 Key Features

### ✨ Dual Control Mode
The app seamlessly handles both:
- **App Control** - Control from your iPhone
- **Manual Control** - Physical buttons on device
- The app automatically detects which is being used!

### 🔄 Auto-Sync
- App requests status every 5 seconds
- Always stays in sync with device
- Works even if someone else uses manual buttons

### 🛡️ Safety Features
- Displays safety shutoff alerts
- Shows overheat warnings
- Visual countdown timer
- Warning when < 5 minutes remaining

### 🎨 Beautiful UI
- Clean, minimal design
- Smooth animations
- Dark mode support
- Haptic feedback (on device)
- Color-coded temperature indicators

---

## 🔌 Bluetooth Protocol

The app uses these commands (all defined in firmware README):

**Sending to Device:**
- `ON` - Turn pump on
- `OFF` - Turn pump off
- `SPEED:180` - Set speed (0-255)
- `STATUS` - Request status
- `TEMP` - Request temperature

**Receiving from Device:**
- `STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,Temp:34.5C}`
- `PUMP:ON` / `PUMP:OFF`
- `MANUAL:ON` / `MANUAL:OFF`
- `ERROR:SAFETY_SHUTOFF`
- `TEMP:34.5`

---

## 🎯 Next Steps

1. **Open Xcode** - Project is already open!

2. **Preview the UI** - Open `ContentView.swift` and click "Resume" in canvas

3. **Run in Simulator** - Press ⌘R to see the full app

4. **Test with Hardware** - Connect your iPhone and deploy

5. **Customize** - All code is fully commented and easy to modify

---

## 📚 Documentation

- **Full README:** `TesticoolApp/README.md`
- **Firmware Docs:** `firmware/README.md`
- **Project Docs:** `Project_Docs/`
- **Arduino Docs:** `Arduino_Nano_Docs/`

---

## 💡 Tips for Xcode

### Keyboard Shortcuts
- **⌘R** - Build and run
- **⌘B** - Build only
- **⌘.** - Stop running
- **⌘K** - Clear console
- **⌘⇧K** - Clean build folder
- **⌘⌥↩** - Show/hide canvas

### Useful Panels
- **Navigator** (⌘1) - File browser
- **Inspector** (⌥⌘0) - Properties panel
- **Console** (⌘⇧Y) - Debug output
- **Canvas** (⌥⌘↩) - SwiftUI preview

### Preview Tips
- Click "Resume" to start preview
- Click 📱 icon to switch device sizes
- Click 🌙 icon to toggle dark mode
- Preview updates live as you type!

---

## 🎓 Learning Resources

Want to understand the code better?

1. **SwiftUI Basics**
   - All UI is declarative SwiftUI
   - Views automatically update when data changes
   - `@Published` properties trigger UI updates

2. **CoreBluetooth**
   - `BluetoothManager.swift` has extensive comments
   - Shows scanning, connecting, reading, and writing

3. **MVVM Architecture**
   - Models: `DeviceState`, `StatusParser`
   - Views: All SwiftUI files
   - ViewModel: `BluetoothManager`

---

## ✉️ Support

**Team Leader:** Oscar Mullikin - omullikin@wisc.edu

**Project:** BME 200/300 Section 301
**Institution:** University of Wisconsin-Madison

---

**Built with ❄️ by the Testicool Team**

Enjoy your Xcode project! 🎉
