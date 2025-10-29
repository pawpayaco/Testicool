#!/bin/bash

# Automated script to add SPP Swift files to Xcode project

PROJECT_DIR="/Users/oscarmullikin/Testicool/TesticoolApp"
cd "$PROJECT_DIR"

echo "================================================"
echo "Adding SPP files to Testicool Xcode project"
echo "================================================"
echo ""

# Files to add
FILES=(
    "Managers/SPPBluetoothManager.swift"
    "Managers/PumpController.swift"
    "Managers/SessionManager.swift"
    "Views/SPPMainView.swift"
)

echo "Files to be added:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file (exists)"
    else
        echo "  ✗ $file (missing!)"
    fi
done

echo ""
echo "================================================"
echo "MANUAL STEPS REQUIRED:"
echo "================================================"
echo ""
echo "Since Xcode project files are binary/complex, please:"
echo ""
echo "1. Open Testicool.xcodeproj in Xcode"
echo ""
echo "2. In the Project Navigator (left sidebar):"
echo "   - Right-click on 'Managers' folder"
echo "   - Select 'Add Files to \"Testicool\"...'"
echo "   - Navigate to TesticoolApp/Managers/"
echo "   - Hold Command (⌘) and select:"
echo "     • SPPBluetoothManager.swift"
echo "     • PumpController.swift"
echo "     • SessionManager.swift"
echo "   - UNCHECK 'Copy items if needed'"
echo "   - CHECK 'Testicool' target"
echo "   - Click 'Add'"
echo ""
echo "3. Repeat for Views:"
echo "   - Right-click on 'Views' folder"
echo "   - Select 'Add Files to \"Testicool\"...'"
echo "   - Navigate to TesticoolApp/Views/"
echo "   - Select:"
echo "     • SPPMainView.swift"
echo "   - UNCHECK 'Copy items if needed'"
echo "   - CHECK 'Testicool' target"
echo "   - Click 'Add'"
echo ""
echo "4. Build the project (⌘B)"
echo ""
echo "================================================"
echo ""
