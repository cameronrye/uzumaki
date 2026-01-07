#!/bin/bash
# capture-mac-screenshots.sh - Capture macOS App Store screenshots outside of XCUITest sandbox
#
# This script launches the app directly and uses AppleScript to:
# 1. Resize the window to the correct dimensions
# 2. Select each preset from the menu
# 3. Capture screenshots using screencapture
#
# Requirements:
# - Terminal must have Accessibility permissions (System Settings > Privacy & Security > Accessibility)
# - App must be built first
#
# Usage:
#   ./scripts/capture-mac-screenshots.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots/Mac"
APP_BUNDLE_ID="com.uzumaki.app"

# Target window size in points (will produce 2560x1600 pixels on 2x Retina)
WINDOW_WIDTH=1280
WINDOW_HEIGHT=800

# Presets to capture (must match SpiralPreset.allPresets order)
PRESETS=(
    "Classic Golden"
    "Sunflower"
    "Fractal Dance"
    "Chaos"
    "Tight Archimedean"
    "Hypnotic"
    "Wheel of Theodorus"
    "Trumpet"
    "Matrix Rain"
    "Deep Space"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for Accessibility permissions
check_permissions() {
    log_info "Checking Accessibility permissions..."
    if ! osascript -e 'tell application "System Events" to return name of first process' &>/dev/null; then
        log_error "Terminal does not have Accessibility permissions!"
        echo ""
        echo "Please grant permissions:"
        echo "1. Open System Settings > Privacy & Security > Accessibility"
        echo "2. Click + and add Terminal (or your terminal app)"
        echo "3. Make sure it's toggled ON"
        echo "4. Re-run this script"
        exit 1
    fi
    log_success "Accessibility permissions OK"
}

# Build and launch the app
launch_app() {
    log_info "Building and launching Uzumaki..."
    
    # Build the app
    cd "$PROJECT_DIR/Uzumaki"
    xcodebuild -project Uzumaki.xcodeproj -scheme Uzumaki -configuration Release build 2>&1 | tail -5
    
    # Find and launch the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Uzumaki.app" -path "*/Release/*" -type d 2>/dev/null | head -1)
    
    if [ -z "$APP_PATH" ]; then
        log_error "Could not find built app. Build failed?"
        exit 1
    fi
    
    log_info "Launching: $APP_PATH"
    open "$APP_PATH"
    sleep 2
}

# Resize window using AppleScript
resize_window() {
    log_info "Resizing window to ${WINDOW_WIDTH}x${WINDOW_HEIGHT} points..."
    osascript <<EOF
tell application "System Events"
    set targetApp to first process whose bundle identifier is "$APP_BUNDLE_ID"
    tell targetApp
        set frontWindow to first window
        set position of frontWindow to {100, 100}
        set size of frontWindow to {$WINDOW_WIDTH, $WINDOW_HEIGHT}
    end tell
end tell
EOF
    sleep 0.5
}

# Select a preset from the menu
select_preset() {
    local preset_name="$1"
    log_info "Selecting preset: $preset_name"
    osascript <<EOF
tell application "System Events"
    tell process "Uzumaki"
        click menu bar item "Presets" of menu bar 1
        delay 0.3
        click menu item "$preset_name" of menu "Presets" of menu bar item "Presets" of menu bar 1
    end tell
end tell
EOF
    sleep 1  # Wait for spiral to render
}

# Capture screenshot of the app window
capture_screenshot() {
    local filename="$1"
    local filepath="$SCREENSHOTS_DIR/$filename"

    # Get CGWindowID using Quartz (required for screencapture -l)
    local window_id=$(python3 -c "
import Quartz
windows = Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID)
for w in windows:
    if w.get('kCGWindowOwnerName') == 'Uzumaki':
        print(w.get('kCGWindowNumber'))
        break
" 2>/dev/null)

    if [ -n "$window_id" ]; then
        # Capture specific window by CGWindowID (no interaction needed)
        screencapture -l "$window_id" -o "$filepath"
        log_success "Captured: $filename"
    else
        log_error "Could not find Uzumaki window"
    fi
}

# Main
main() {
    log_info "=== macOS App Store Screenshot Capture ==="
    
    mkdir -p "$SCREENSHOTS_DIR"
    
    check_permissions
    launch_app
    resize_window
    
    # Capture each preset
    local index=1
    for preset in "${PRESETS[@]}"; do
        local padded_index=$(printf "%02d" $index)
        local safe_name=$(echo "$preset" | tr ' ' '-')
        local filename="Mac-${padded_index}-${safe_name}.png"
        
        select_preset "$preset"
        capture_screenshot "$filename"
        
        ((index++))
    done
    
    log_info "Verifying screenshot dimensions..."
    for f in "$SCREENSHOTS_DIR"/*.png; do
        local dims=$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | grep pixel | awk '{printf $2"x"}' | sed 's/x$//')
        echo "  $(basename "$f"): $dims"
    done
    
    log_success "All screenshots captured to: $SCREENSHOTS_DIR"
}

main "$@"

