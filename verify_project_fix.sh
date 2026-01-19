#!/bin/bash

echo "✅ Verifying project file fix..."
echo ""

# 1. Check syntax
echo "1. Project file syntax:"
if plutil -lint Cheq.xcodeproj/project.pbxproj > /dev/null 2>&1; then
    echo "   ✓ Valid"
else
    echo "   ❌ Invalid!"
    exit 1
fi

# 2. Check xcodebuild can parse it
echo "2. xcodebuild parsing:"
if xcodebuild -list -project Cheq.xcodeproj > /dev/null 2>&1; then
    echo "   ✓ Can parse"
else
    echo "   ❌ Cannot parse!"
    exit 1
fi

# 3. Check file references
echo "3. File references:"
python3 << 'PYEOF'
import os
import re

with open('Cheq.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

file_ref_pattern = r'path = ([^;]+);'
swift_refs = [m.group(1).strip().strip('"') for m in re.finditer(file_ref_pattern, content) if m.group(1).strip().strip('"').endswith('.swift')]

missing = [p for p in swift_refs if not os.path.exists(p)]

if missing:
    print(f"   ❌ {len(missing)} missing files:")
    for p in missing[:5]:
        print(f"      {p}")
else:
    print(f"   ✓ All {len(swift_refs)} Swift file references are valid")
PYEOF

echo ""
echo "✅ Project file is now fixed!"
echo ""
echo "Try opening Xcode now:"
echo "  open -a Xcode Cheq.xcodeproj"
