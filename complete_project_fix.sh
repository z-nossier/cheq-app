#!/bin/bash

echo "🔧 Complete project file fix..."
echo ""

# Backup current project
echo "1. Backing up project file..."
cp Cheq.xcodeproj/project.pbxproj Cheq.xcodeproj/project.pbxproj.backup
echo "   ✓ Backup created"
echo ""

# Clean all caches again
echo "2. Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf Cheq.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Cheq.xcodeproj/xcuserdata
echo "   ✓ Caches cleared"
echo ""

# Verify project file
echo "3. Verifying project file..."
if plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ✓ Syntax valid"
else
    echo "   ❌ Syntax errors!"
    exit 1
fi

if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ xcodebuild can parse"
else
    echo "   ❌ xcodebuild cannot parse!"
    exit 1
fi
echo ""

# Check for missing files
echo "4. Checking file references..."
python3 << 'PYEOF'
import os
import re

with open('Cheq.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

paths = [p.strip().strip('"') for p in re.findall(r'path = ([^;]+);', content) if p.strip().strip('"').endswith('.swift')]
missing = [p for p in paths if not os.path.exists(p)]

if missing:
    print(f"   ❌ {len(missing)} missing Swift files:")
    for p in missing[:5]:
        print(f"      {p}")
    exit(1)
else:
    print(f"   ✓ All {len(paths)} Swift files exist")
PYEOF

if [ $? -ne 0 ]; then
    echo "   ❌ File reference issues found!"
    exit 1
fi
echo ""

echo "✅ Project file is ready!"
echo ""
echo "Try opening Xcode:"
echo "  open -a Xcode Cheq.xcodeproj"
echo ""
echo "If it still crashes, check Console.app for detailed errors"
