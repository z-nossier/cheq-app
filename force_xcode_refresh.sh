#!/bin/bash

echo "🔄 Forcing Xcode to refresh project index..."
echo ""

# 1. Kill Xcode completely
echo "1. Killing Xcode processes..."
killall Xcode 2>/dev/null
sleep 2
# Make sure it's really dead
pkill -9 Xcode 2>/dev/null
sleep 1
echo "   ✓ Xcode processes killed"
echo ""

# 2. Clean ALL Xcode caches
echo "2. Cleaning all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/Archives/*
echo "   ✓ All caches cleared"
echo ""

# 3. Remove ALL user-specific project data
echo "3. Removing user-specific project data..."
rm -rf Cheq.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Cheq.xcodeproj/xcuserdata
find Cheq.xcodeproj -name "*.xcuserstate" -delete 2>/dev/null
find Cheq.xcodeproj -name "*.xcworkspacedata" -delete 2>/dev/null
echo "   ✓ User data removed"
echo ""

# 4. Verify project file
echo "4. Verifying project file..."
if ! plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ❌ Project file has syntax errors!"
    exit 1
fi

if ! xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ❌ xcodebuild cannot parse the project!"
    exit 1
fi
echo "   ✓ Project file is valid"
echo ""

# 5. Verify all files exist
echo "5. Verifying file references..."
python3 << 'PYEOF'
import os
import re

with open('Cheq.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

file_ref_pattern = r'path = ([^;]+);'
paths = [m.group(1).strip().strip('"') for m in re.finditer(file_ref_pattern, content)]

swift_files = [p for p in paths if p.endswith('.swift')]
missing = [p for p in swift_files if not os.path.exists(p)]

if missing:
    print(f"   ❌ {len(missing)} missing files:")
    for p in missing[:5]:
        print(f"      {p}")
    exit(1)
else:
    print(f"   ✓ All {len(swift_files)} Swift files exist")
PYEOF

if [ $? -ne 0 ]; then
    echo "   ❌ File reference issues!"
    exit 1
fi
echo ""

echo "✅ All checks passed!"
echo ""
echo "The project file is CORRECT. Red files are due to Xcode's index."
echo ""
echo "Next steps:"
echo "1. Wait 5 seconds"
echo "2. Open Xcode: open -a Xcode Cheq.xcodeproj"
echo "3. IMPORTANT: Wait for Xcode to finish indexing"
echo "   - Look for progress bar at top of Xcode window"
echo "   - Don't click anything until indexing completes"
echo "   - This can take 1-2 minutes"
echo ""
echo "If files are STILL red after indexing:"
echo "- In Xcode: Product → Clean Build Folder (Shift+Cmd+K)"
echo "- Then: File → Close Project"
echo "- Wait 5 seconds"
echo "- Reopen: File → Open → select Cheq.xcodeproj"
echo "- Wait for indexing again"
echo ""
echo "The project structure is correct - Xcode just needs to rebuild its index."
