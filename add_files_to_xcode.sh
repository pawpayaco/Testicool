#!/bin/bash

# Quick script to add new files to the Xcode project
# Usage: ./add_files_to_xcode.sh

echo "🔄 Rebuilding Xcode project to include all files..."

# Just re-run the auto setup script
cd "$(dirname "$0")"
./auto_setup_xcode.sh

echo ""
echo "✅ Done! All files in TesticoolApp/ are now referenced in Xcode."
echo ""
echo "💡 Tip: You can edit files in TesticoolApp/ directly"
echo "   and they'll update in Xcode automatically!"
