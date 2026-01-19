#!/bin/bash

echo "🚀 Attempting to open Xcode with project..."
echo ""

# Method 1: Try opening Xcode first, then project
echo "Method 1: Opening Xcode first..."
open -a Xcode
sleep 3
echo "   Then opening project..."
osascript << 'APPLESCRIPT'
tell application "Xcode"
    activate
    open POSIX file "/Users/zosman/cheq/Cheq.xcodeproj"
end tell
APPLESCRIPT

echo ""
echo "If that doesn't work, try:"
echo "  1. Open Xcode manually"
echo "  2. File → Open → select Cheq.xcodeproj"
echo ""
echo "Or check Console.app for crash details:"
echo "  open /Applications/Utilities/Console.app"
