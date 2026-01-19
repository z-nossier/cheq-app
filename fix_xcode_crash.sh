#!/bin/bash

echo "🔧 Fixing Xcode crash issues..."
echo ""

# 1. Clean derived data
echo "1. Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "   ✓ Derived data cleared"
echo ""

# 2. Clean Xcode caches
echo "2. Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
echo "   ✓ Xcode caches cleared"
echo ""

# 3. Clean module cache
echo "3. Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "   ✓ Module cache cleared"
echo ""

# 4. Verify project file syntax
echo "4. Verifying project file..."
if plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ✓ Project file syntax is valid"
else
    echo "   ❌ Project file has syntax errors!"
    exit 1
fi
echo ""

# 5. Verify Core Data model exists
echo "5. Verifying Core Data model..."
if [ -d "Cheq.xcdatamodeld" ]; then
    echo "   ✓ Core Data model found"
else
    echo "   ❌ Core Data model not found!"
    exit 1
fi
echo ""

# 6. Test project with xcodebuild
echo "6. Testing project with xcodebuild..."
if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ Project can be parsed by xcodebuild"
else
    echo "   ❌ Project cannot be parsed!"
    exit 1
fi
echo ""

echo "✅ All checks passed!"
echo ""
echo "Next steps:"
echo "1. Close Xcode completely (Cmd+Q) - make sure it's not running"
echo "2. Wait 5 seconds"
echo "3. Open the project: open Cheq.xcodeproj"
echo "4. Wait for Xcode to index (watch the progress bar at the top)"
echo ""
echo "If Xcode still crashes:"
echo "- Try opening Xcode first, then File → Open → select Cheq.xcodeproj"
echo "- Check Console.app for crash logs: /Applications/Utilities/Console.app"
echo "- Look for errors related to 'Cheq.xcodeproj' or 'Core Data'"
