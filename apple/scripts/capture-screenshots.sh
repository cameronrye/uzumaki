#!/bin/bash
# capture-screenshots.sh - Automated App Store screenshot capture for Uzumaki
# Supports iOS, iPad, macOS, watchOS, and tvOS
#
# Usage:
#   ./scripts/capture-screenshots.sh           # Capture all platforms
#   ./scripts/capture-screenshots.sh --ios     # iOS only (iPhone + iPad)
#   ./scripts/capture-screenshots.sh --mac     # macOS only
#   ./scripts/capture-screenshots.sh --watch   # watchOS only
#   ./scripts/capture-screenshots.sh --tv      # tvOS only (Apple TV)
#   ./scripts/capture-screenshots.sh --fastlane # Use fastlane (iOS/iPad only)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"
XCODE_PROJECT="$PROJECT_DIR/Uzumaki/Uzumaki.xcodeproj"
SCHEME="Uzumaki"

# Device definitions
# Using iPhone 14 Plus for 6.5" display (1284x2778) - required by App Store Connect
IPHONE_DEVICE="iPhone 14 Plus"
# iPad Pro 13-inch (M5) for 13" displays - produces 2752x2064 or 2064x2752 screenshots
# App Store Connect accepts: 2064x2752, 2752x2064, 2048x2732, or 2732x2048
IPAD_DEVICE="iPad Pro 13-inch (M5)"
WATCH_DEVICE="Apple Watch Series 11 (46mm)"
WATCH_PAIRED_PHONE="iPhone 17 Pro"
# Apple TV 4K (3rd generation) for 1920x1080 screenshots
TV_DEVICE="Apple TV 4K (3rd generation)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create output directories
setup_directories() {
    log_info "Creating screenshot directories..."
    mkdir -p "$SCREENSHOTS_DIR/iPhone"
    mkdir -p "$SCREENSHOTS_DIR/iPad"
    mkdir -p "$SCREENSHOTS_DIR/Mac"
    mkdir -p "$SCREENSHOTS_DIR/Watch"
    mkdir -p "$SCREENSHOTS_DIR/AppleTV"
    mkdir -p "$SCREENSHOTS_DIR/raw"
}

# Boot a simulator if not already booted
boot_simulator() {
    local device_name="$1"
    log_info "Booting simulator: $device_name"
    
    # Check if already booted
    if xcrun simctl list devices | grep "$device_name" | grep -q "Booted"; then
        log_info "$device_name already booted"
        return 0
    fi
    
    xcrun simctl boot "$device_name" 2>/dev/null || true
    sleep 3
}

# Shutdown a simulator
shutdown_simulator() {
    local device_name="$1"
    log_info "Shutting down simulator: $device_name"
    xcrun simctl shutdown "$device_name" 2>/dev/null || true
}

# Capture iOS screenshots using xcodebuild test
capture_ios() {
    log_info "=== Capturing iOS Screenshots ==="

    boot_simulator "$IPHONE_DEVICE"

    local result_bundle="$SCREENSHOTS_DIR/raw/iphone-results.xcresult"
    rm -rf "$result_bundle"

    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$IPHONE_DEVICE" \
        -testPlan AppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee /tmp/xcodebuild-ios.log || true

    # Extract screenshots from result bundle
    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/iPhone"

    shutdown_simulator "$IPHONE_DEVICE"
    log_success "iOS screenshots captured!"
}

# Capture iPad screenshots
capture_ipad() {
    log_info "=== Capturing iPad Screenshots ==="

    boot_simulator "$IPAD_DEVICE"

    local result_bundle="$SCREENSHOTS_DIR/raw/ipad-results.xcresult"
    rm -rf "$result_bundle"

    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$IPAD_DEVICE" \
        -testPlan AppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee /tmp/xcodebuild-ipad.log || true

    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/iPad"

    shutdown_simulator "$IPAD_DEVICE"
    log_success "iPad screenshots captured!"
}

# Capture macOS screenshots
# Uses MacAppStoreScreenshotTests to capture 10 screenshots based on presets
# Resolution options: 1280x800, 1440x900, 2560x1600, 2880x1800 (default: 2560x1600)
capture_mac() {
    log_info "=== Capturing macOS Screenshots ==="
    log_info "Target resolution: 2560x1600 (Retina)"
    log_info "Using 10 presets: Classic Golden, Sunflower, Fractal Dance, Chaos,"
    log_info "  Tight Archimedean, Hypnotic, Wheel of Theodorus, Trumpet, Matrix Rain, Deep Space"

    local result_bundle="$SCREENSHOTS_DIR/raw/mac-results.xcresult"
    rm -rf "$result_bundle"

    # Run macOS-specific screenshot tests using MacAppStoreScreenshotTests
    # These tests resize the window to 2560x1600 and capture all 10 presets
    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=macOS" \
        -only-testing:AppStoreScreenshotTests/MacAppStoreScreenshotTests/testCaptureAppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee /tmp/xcodebuild-mac.log || true

    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/Mac"

    log_info "macOS App Store accepted resolutions:"
    log_info "  - 1280 x 800 px (minimum)"
    log_info "  - 1440 x 900 px"
    log_info "  - 2560 x 1600 px (Retina, captured)"
    log_info "  - 2880 x 1800 px (Retina max)"
    log_warning "Screenshots may need post-processing for corner radius and shadow"
    log_success "macOS screenshots captured!"
}

# Capture watchOS screenshots using UI tests
# Uses swipe gestures to navigate through all 10 presets
capture_watch() {
    log_info "=== Capturing watchOS Screenshots ==="

    # Boot both watch and paired phone (required for watch simulator)
    boot_simulator "$WATCH_PAIRED_PHONE"
    boot_simulator "$WATCH_DEVICE"

    local result_bundle="$SCREENSHOTS_DIR/raw/watch-results.xcresult"
    rm -rf "$result_bundle"

    # Run UI tests on watch app - uses swipe gestures to cycle through presets
    # The test navigates through all 10 presets using swipe left/right
    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "Uzumaki Watch App" \
        -destination "platform=watchOS Simulator,name=$WATCH_DEVICE" \
        -only-testing:WatchAppStoreScreenshotTests/WatchAppStoreScreenshotTests/testCaptureAppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee /tmp/xcodebuild-watch.log || true

    # Extract screenshots from result bundle
    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/Watch"

    shutdown_simulator "$WATCH_DEVICE"
    shutdown_simulator "$WATCH_PAIRED_PHONE"

    log_success "watchOS screenshots captured!"
}

# Capture tvOS screenshots using UI tests
# Uses focus-based navigation to select all 10 presets
capture_tv() {
    log_info "=== Capturing tvOS Screenshots ==="
    log_info "Target resolution: 1920x1080 (1080p HD)"
    log_info "Using 10 presets: Classic Golden, Sunflower, Fractal Dance, Chaos,"
    log_info "  Tight Archimedean, Hypnotic, Wheel of Theodorus, Trumpet, Matrix Rain, Deep Space"

    boot_simulator "$TV_DEVICE"

    local result_bundle="$SCREENSHOTS_DIR/raw/tv-results.xcresult"
    rm -rf "$result_bundle"

    # Run UI tests on Apple TV app - uses focus navigation to select presets
    # The test navigates through all 10 presets using the Presets view
    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=tvOS Simulator,name=$TV_DEVICE" \
        -only-testing:AppStoreScreenshotTests/TVAppStoreScreenshotTests/testCaptureAppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | tee /tmp/xcodebuild-tv.log || true

    # Extract screenshots from result bundle
    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/AppleTV"

    shutdown_simulator "$TV_DEVICE"

    log_info "tvOS App Store accepted resolutions:"
    log_info "  - 1920 x 1080 px (1080p HD)"
    log_info "  - 3840 x 2160 px (4K UHD, optional)"
    log_success "tvOS screenshots captured!"
}

# Extract screenshots from xcresult bundle using proper name extraction
extract_screenshots() {
    local result_bundle="$1"
    local output_dir="$2"

    if [ ! -d "$result_bundle" ]; then
        log_warning "Result bundle not found: $result_bundle"
        return 1
    fi

    log_info "Extracting screenshots from $result_bundle..."

    # Use the dedicated extraction script if available
    if [ -x "$SCRIPT_DIR/extract_screenshots.sh" ]; then
        "$SCRIPT_DIR/extract_screenshots.sh" "$result_bundle" "$output_dir"
        local result=$?
        # Clean up the xcresult bundle
        log_info "Cleaning up $result_bundle..."
        rm -rf "$result_bundle"
        return $result
    fi

    # Fallback: Use xcresulttool to extract screenshots with proper names
    python3 << PYEOF
import json
import subprocess
import os

xcresult = "$result_bundle"
output_dir = "$output_dir"

def get_json(ref_id=None):
    cmd = ["xcrun", "xcresulttool", "get", "--path", xcresult, "--format", "json", "--legacy"]
    if ref_id:
        cmd.extend(["--id", ref_id])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return json.loads(result.stdout)

def find_summary_refs(node, refs=None):
    if refs is None:
        refs = []
    if isinstance(node, dict):
        if 'summaryRef' in node:
            ref_id = node['summaryRef'].get('id', {}).get('_value', '')
            if ref_id:
                refs.append(ref_id)
        for value in node.values():
            find_summary_refs(value, refs)
    elif isinstance(node, list):
        for item in node:
            find_summary_refs(item, refs)
    return refs

def find_attachments(node, attachments=None):
    if attachments is None:
        attachments = []
    if isinstance(node, dict):
        if 'attachments' in node and '_values' in node['attachments']:
            for att in node['attachments']['_values']:
                name = att.get('name', {}).get('_value', 'unknown')
                payload_ref = att.get('payloadRef', {}).get('id', {}).get('_value', '')
                uti = att.get('uniformTypeIdentifier', {}).get('_value', '')
                if payload_ref and 'png' in uti.lower():
                    attachments.append((name, payload_ref))
        for value in node.values():
            find_attachments(value, attachments)
    elif isinstance(node, list):
        for item in node:
            find_attachments(item, attachments)
    return attachments

# Get root data
root_data = get_json()
if not root_data:
    print("Failed to read xcresult bundle")
    exit(1)

tests_ref_id = root_data["actions"]["_values"][0]["actionResult"]["testsRef"]["id"]["_value"]

# Get test plan summaries
tests_data = get_json(tests_ref_id)

# Find all summary refs
summary_refs = find_summary_refs(tests_data)

# Get attachments from each summary
all_attachments = []
for ref_id in summary_refs:
    summary_data = get_json(ref_id)
    if summary_data:
        attachments = find_attachments(summary_data)
        all_attachments.extend(attachments)

print(f"Found {len(all_attachments)} PNG attachments")

# Extract each attachment
for name, ref_id in all_attachments:
    safe_name = name if name.endswith('.png') else f"{name}.png"
    output_path = os.path.join(output_dir, safe_name)

    cmd = ["xcrun", "xcresulttool", "get", "--path", xcresult, "--id", ref_id, "--legacy"]
    with open(output_path, 'wb') as f:
        result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)

    if result.returncode == 0 and os.path.exists(output_path) and os.path.getsize(output_path) > 0:
        size = os.path.getsize(output_path)
        print(f"Extracted: {safe_name} ({size} bytes)")
    else:
        print(f"Failed: {name}")
        if os.path.exists(output_path):
            os.remove(output_path)

print(f"Screenshots saved to {output_dir}")
PYEOF

    # Clean up the xcresult bundle
    log_info "Cleaning up $result_bundle..."
    rm -rf "$result_bundle"
}

# Use fastlane for iOS/iPad screenshots
capture_fastlane() {
    log_info "=== Using Fastlane for Screenshots ==="

    if ! command -v fastlane &> /dev/null; then
        log_error "Fastlane not installed. Install with: brew install fastlane"
        exit 1
    fi

    cd "$PROJECT_DIR"
    fastlane snapshot

    log_success "Fastlane screenshots complete!"
}

# Main entry point
main() {
    cd "$PROJECT_DIR"

    case "${1:-all}" in
        --ios)
            setup_directories
            capture_ios
            capture_ipad
            ;;
        --iphone)
            setup_directories
            capture_ios
            ;;
        --ipad)
            setup_directories
            capture_ipad
            ;;
        --mac)
            setup_directories
            capture_mac
            ;;
        --watch)
            setup_directories
            capture_watch
            ;;
        --tv)
            setup_directories
            capture_tv
            ;;
        --fastlane)
            capture_fastlane
            ;;
        all|--all)
            setup_directories
            capture_ios
            capture_ipad
            capture_mac
            capture_watch
            capture_tv
            log_success "All screenshots captured!"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --ios       Capture iPhone and iPad screenshots"
            echo "  --iphone    Capture iPhone screenshots only"
            echo "  --ipad      Capture iPad screenshots only"
            echo "  --mac       Capture macOS screenshots"
            echo "  --watch     Capture watchOS screenshots"
            echo "  --tv        Capture tvOS (Apple TV) screenshots"
            echo "  --fastlane  Use fastlane for iOS/iPad"
            echo "  --all       Capture all platforms (default)"
            echo "  --help      Show this help"
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"

