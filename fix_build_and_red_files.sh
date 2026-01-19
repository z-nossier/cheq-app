#!/bin/bash

echo "🔧 Fixing build errors and red files..."
echo ""

# 1. Kill Xcode
echo "1. Killing Xcode..."
killall Xcode 2>/dev/null
sleep 2
pkill -9 Xcode 2>/dev/null
sleep 1
echo "   ✓ Xcode killed"
echo ""

# 2. Clean ALL derived data
echo "2. Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "   ✓ Derived data cleared"
echo ""

# 3. Clean Swift Package Manager cache
echo "3. Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
rm -rf .build
rm -rf .swiftpm
echo "   ✓ SPM cache cleared"
echo ""

# 4. Clean Xcode caches
echo "4. Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "   ✓ Xcode caches cleared"
echo ""

# 5. Remove user-specific project data
echo "5. Removing user-specific project data..."
rm -rf Cheq.xcodeproj/project.xcworkspace/xcuserdata
rm -rf Cheq.xcodeproj/xcuserdata
find Cheq.xcodeproj -name "*.xcuserstate" -delete 2>/dev/null
find Cheq.xcodeproj -name "*.xcworkspacedata" -delete 2>/dev/null
echo "   ✓ User data removed"
echo ""

# 6. Verify project file
echo "6. Verifying project file..."
if ! plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ❌ Project file has syntax errors!"
    exit 1
fi
echo "   ✓ Project file syntax is valid"
echo ""

# 7. Resolve package dependencies
echo "7. Resolving Swift Package dependencies..."
if xcodebuild -resolvePackageDependencies -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ Package dependencies resolved"
else
    echo "   ⚠️ Package resolution had issues (may need to resolve in Xcode)"
fi
echo ""

# 8. Verify all files exist
echo "8. Verifying file references..."
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

echo "✅ All cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Wait 5 seconds"
echo "2. Open Xcode: open -a Xcode Cheq.xcodeproj"
echo "3. Wait for Xcode to:"
echo "   - Resolve packages (if prompted, click 'Resolve')"
echo "   - Finish indexing (progress bar at top)"
echo "4. If packages don't resolve automatically:"
echo "   - File → Packages → Reset Package Caches"
echo "   - File → Packages → Resolve Package Versions"
echo "5. Try building: Product → Build (Cmd+B)"
echo ""
echo "The build errors were due to corrupted Swift Package Manager cache."
echo "Red files should disappear after Xcode finishes indexing."
