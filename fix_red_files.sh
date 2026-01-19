#!/bin/bash

echo "🔧 Fixing red files in Xcode..."
echo ""

# 1. Clean derived data
echo "1. Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Cheq-*
rm -rf ~/Library/Developer/Xcode/DerivedData/*/Build/Products/*
echo "   ✓ Derived data cleared"
echo ""

# 2. Clean Xcode caches
echo "2. Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
echo "   ✓ Caches cleared"
echo ""

# 3. Remove user-specific project data
echo "3. Cleaning user-specific project data..."
rm -rf Cheq.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Cheq.xcodeproj/xcuserdata
find Cheq.xcodeproj -name "*.xcuserstate" -delete 2>/dev/null
echo "   ✓ User data cleared"
echo ""

# 4. Verify project file
echo "4. Verifying project file..."
if plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ✓ Project file syntax is valid"
else
    echo "   ❌ Project file has syntax errors!"
    exit 1
fi

if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ xcodebuild can parse the project"
else
    echo "   ❌ xcodebuild cannot parse the project!"
    exit 1
fi
echo ""

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Close Xcode completely (Cmd+Q)"
echo "2. Wait 5 seconds"
echo "3. Open Xcode: open -a Xcode Cheq.xcodeproj"
echo "4. Wait for Xcode to finish indexing (watch progress bar)"
echo ""
echo "If files are still red:"
echo "- Select the red file in Xcode"
echo "- Press Delete"
echo "- Choose 'Remove Reference' (NOT 'Move to Trash')"
echo "- Right-click parent folder → 'Add Files to Cheq...'"
echo "- Select the file and add it back"
