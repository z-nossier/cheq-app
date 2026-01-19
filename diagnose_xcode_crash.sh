#!/bin/bash

echo "🔍 Diagnosing Xcode crash issue..."
echo ""

# Check Xcode version
echo "1. Xcode version:"
xcodebuild -version
echo ""

# Check if project can be validated
echo "2. Project file validation:"
if plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ✓ Project file syntax is valid"
else
    echo "   ❌ Project file has syntax errors!"
    plutil -lint Cheq.xcodeproj/project.pbxproj
fi
echo ""

# Check Core Data model
echo "3. Core Data model:"
if [ -d "Cheq.xcdatamodeld" ]; then
    echo "   ✓ Core Data model directory exists"
    if [ -f "Cheq.xcdatamodeld/Cheq.xcdatamodel/contents" ]; then
        echo "   ✓ Core Data model contents file exists"
    else
        echo "   ❌ Core Data model contents file missing!"
    fi
else
    echo "   ❌ Core Data model directory missing!"
fi
echo ""

# Try to open with xcodebuild (non-UI)
echo "4. Testing with xcodebuild (command line):"
if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ xcodebuild can parse the project"
    echo "   This suggests the issue is with Xcode UI, not the project file itself"
else
    echo "   ❌ xcodebuild cannot parse the project"
    xcodebuild -list -project Cheq.xcodeproj
fi
echo ""

# Check for recent crash logs
echo "5. Recent Xcode crash logs:"
CRASH_LOG=$(find ~/Library/Logs/DiagnosticReports -name "Xcode*.crash" -mtime -1 2>/dev/null | head -1)
if [ -n "$CRASH_LOG" ]; then
    echo "   Found crash log: $CRASH_LOG"
    echo "   Last few lines:"
    tail -20 "$CRASH_LOG" | grep -A 5 -B 5 "Cheq\|Core Data\|xcdatamodel" || echo "   (No relevant errors found)"
else
    echo "   No recent crash logs found"
fi
echo ""

# Check workspace file
echo "6. Workspace file:"
if [ -f "Cheq.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    echo "   ✓ Workspace file exists"
    if plutil -lint Cheq.xcodeproj/project.xcworkspace/contents.xcworkspacedata > /dev/null 2>&1; then
        echo "   ✓ Workspace file syntax is valid"
    else
        echo "   ⚠️ Workspace file may have issues (plutil doesn't recognize Xcode XML)"
    fi
else
    echo "   ❌ Workspace file missing!"
fi
echo ""

echo "✅ Diagnosis complete!"
echo ""
echo "If xcodebuild works but Xcode UI crashes, try:"
echo "1. Delete ~/Library/Developer/Xcode/DerivedData/Cheq-*"
echo "2. Delete ~/Library/Caches/com.apple.dt.Xcode/*"
echo "3. Restart your Mac"
echo "4. Try opening Xcode first, then File → Open"
echo ""
echo "If it still crashes, check Console.app for detailed error messages"
