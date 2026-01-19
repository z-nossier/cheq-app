#!/bin/bash

echo "🔧 Complete Xcode crash fix..."
echo ""

# 1. Clean all Xcode caches
echo "1. Cleaning all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "   ✓ Caches cleared"
echo ""

# 2. Clean user-specific project data
echo "2. Cleaning user-specific project data..."
rm -rf Cheq.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Cheq.xcodeproj/xcuserdata
find Cheq.xcodeproj -name "*.xcuserstate" -delete 2>/dev/null
echo "   ✓ User data cleared"
echo ""

# 3. Verify project file
echo "3. Verifying project file..."
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

# 4. Verify Core Data model
echo "4. Verifying Core Data model..."
if [ -d "Cheq.xcdatamodeld" ] && [ -f "Cheq.xcdatamodeld/Cheq.xcdatamodel/contents" ]; then
    echo "   ✓ Core Data model exists and is valid"
else
    echo "   ❌ Core Data model missing or invalid!"
    exit 1
fi
echo ""

echo "✅ All cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Close Xcode completely (Cmd+Q) - check Activity Monitor if needed"
echo "2. Wait 10 seconds"
echo "3. Try opening: open -a Xcode Cheq.xcodeproj"
echo ""
echo "If it still crashes:"
echo "- Open Console.app and watch for errors while opening"
echo "- Try: Xcode → File → Open → select Cheq.xcodeproj"
echo "- Check if a specific file is causing the crash"
echo "- Consider restarting your Mac"
