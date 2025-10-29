#!/bin/bash

# Add files to Xcode project using xcodeproj tool (if installed)
# Requires: gem install xcodeproj

PROJECT="/Users/oscarmullikin/Testicool/TesticoolApp/Testicool.xcodeproj"

if ! command -v xcodeproj &> /dev/null; then
    echo "xcodeproj tool not found. Using manual method instead."
    echo ""
    echo "Please add files manually in Xcode as shown above."
    exit 1
fi

echo "Adding files to Xcode project..."

# This would require the xcodeproj Ruby gem
# Since it's not standard, we'll stick with manual method

echo "Manual addition recommended. See instructions above."
