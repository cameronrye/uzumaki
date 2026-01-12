#!/bin/bash
# Extract App Store screenshots from xcresult bundle to project Screenshots folder
#
# Usage: ./extract-screenshots.sh [xcresult_path]
#
# If no xcresult_path is provided, uses the most recent test result from DerivedData.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APPLE_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$APPLE_DIR/Screenshots"

# Find xcresult path
if [ -n "$1" ]; then
    XCRESULT_PATH="$1"
else
    # Find most recent xcresult in DerivedData for Uzumaki
    DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
    XCRESULT_PATH=$(find "$DERIVED_DATA" -path "*Uzumaki*" -name "*.xcresult" -type d -print0 2>/dev/null | \
        xargs -0 ls -dt 2>/dev/null | head -1)
fi

if [ -z "$XCRESULT_PATH" ] || [ ! -d "$XCRESULT_PATH" ]; then
    echo "Error: No xcresult bundle found"
    echo ""
    echo "Usage: $0 [path/to/test.xcresult]"
    echo ""
    echo "Run the screenshot tests first:"
    echo "  xcodebuild test -project Uzumaki/Uzumaki.xcodeproj -scheme Uzumaki \\"
    echo "    -destination 'platform=macOS' \\"
    echo "    -only-testing:AppStoreScreenshotTests/MacAppStoreScreenshotTests"
    exit 1
fi

echo "Extracting from: $XCRESULT_PATH"
echo ""

# Create temp directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Export all attachments using xcresulttool
xcrun xcresulttool export attachments --path "$XCRESULT_PATH" --output-path "$TEMP_DIR" 2>/dev/null

if [ ! -f "$TEMP_DIR/manifest.json" ]; then
    echo "Error: Failed to export attachments"
    exit 1
fi

COPIED=0

# Parse manifest and copy screenshots with proper names
# Using Python for JSON parsing (available on macOS)
python3 << EOF
import json
import shutil
import os

temp_dir = "$TEMP_DIR"
screenshots_dir = "$SCREENSHOTS_DIR"

with open(os.path.join(temp_dir, "manifest.json")) as f:
    manifest = json.load(f)

for test in manifest:
    for attachment in test.get("attachments", []):
        exported_name = attachment.get("exportedFileName", "")
        suggested_name = attachment.get("suggestedHumanReadableName", "")

        # Only process PNG files with our naming convention
        if not exported_name.endswith(".png"):
            continue

        # Extract the base name (e.g., "Mac-01-Classic-Golden" from suggested name)
        # Format: "Mac-01-Classic-Golden_0_UUID.png"
        if not any(suggested_name.startswith(prefix) for prefix in ["Mac-", "iPhone-", "iPad-", "Watch-", "AppleTV-"]):
            continue

        # Extract the base name before the _0_ suffix
        parts = suggested_name.split("_0_")
        if len(parts) >= 1:
            base_name = parts[0]
        else:
            continue

        # Determine destination folder
        if base_name.startswith("Mac-"):
            dest_folder = "Mac"
        elif base_name.startswith("Watch-"):
            dest_folder = "Watch"
        elif base_name.startswith("iPad-"):
            dest_folder = "iPad"
        elif base_name.startswith("iPhone-"):
            dest_folder = "iPhone"
        elif base_name.startswith("AppleTV-"):
            dest_folder = "AppleTV"
        else:
            continue

        dest_dir = os.path.join(screenshots_dir, dest_folder)
        os.makedirs(dest_dir, exist_ok=True)

        src_path = os.path.join(temp_dir, exported_name)
        dest_path = os.path.join(dest_dir, base_name + ".png")

        if os.path.exists(src_path):
            shutil.copy2(src_path, dest_path)
            print(f"  Copied: {dest_folder}/{base_name}.png")
EOF

# Count copied files
COPIED=$(find "$SCREENSHOTS_DIR" \( -name "Mac-*.png" -o -name "AppleTV-*.png" -o -name "iPhone-*.png" -o -name "iPad-*.png" -o -name "Watch-*.png" \) -newer "$TEMP_DIR/manifest.json" 2>/dev/null | wc -l | tr -d ' ')

echo ""
if [ "$COPIED" -gt 0 ]; then
    echo "Successfully extracted screenshots to $SCREENSHOTS_DIR"
else
    echo "No new screenshots were extracted."
fi

