#!/bin/bash

echo "🔧 Fixing red files in Xcode..."
echo ""

# 1. Clean all Xcode caches
echo "1. Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "   ✓ Caches cleared"
echo ""

# 2. Remove user-specific project data
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
    plutil -lint Cheq.xcodeproj/project.pbxproj
    exit 1
fi

if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ xcodebuild can parse the project"
else
    echo "   ❌ xcodebuild cannot parse the project!"
    exit 1
fi
echo ""

# 4. Verify all files exist
echo "4. Verifying file references..."
python3 << 'PYEOF'
import os
import re

with open('Cheq.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

file_ref_pattern = r'path = ([^;]+);'
paths = [m.group(1).strip().strip('"') for m in re.finditer(file_ref_pattern, content)]

missing = []
for path in paths:
    if path and path.endswith('.swift') and not os.path.exists(path):
        if path not in ['<group>', 'Cheq', 'Products']:
            missing.append(path)

if missing:
    print(f"   ❌ {len(missing)} missing files:")
    for p in missing[:5]:
        print(f"      {p}")
    exit(1)
else:
    print(f"   ✓ All {len([p for p in paths if p.endswith('.swift')])} Swift file references are valid")
PYEOF

if [ $? -ne 0 ]; then
    echo "   ❌ File reference issues found!"
    exit 1
fi
echo ""

echo "✅ All checks passed!"
echo ""
echo "The project file is correct. Red files in Xcode are likely due to:"
echo "  1. Stale Xcode index"
echo "  2. Xcode cache issues"
echo ""
echo "Next steps:"
echo "1. Close Xcode completely (Cmd+Q) - check Activity Monitor if needed"
echo "2. Wait 10 seconds"
echo "3. Open Xcode: open -a Xcode Cheq.xcodeproj"
echo "4. Wait for Xcode to finish indexing (watch progress bar at top)"
echo ""
echo "If files are STILL red after indexing:"
echo "- In Xcode, go to: Product → Clean Build Folder (Shift+Cmd+K)"
echo "- Then: File → Close Project"
echo "- Reopen: File → Open → select Cheq.xcodeproj"
echo ""
echo "The project file is correct - this is just Xcode's index that needs refreshing."
