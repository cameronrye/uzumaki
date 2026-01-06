#!/bin/bash
# capture-screenshots.sh - Automated App Store screenshot capture for Uzumaki
# Supports iOS, iPad, macOS, and watchOS
#
# Usage:
#   ./scripts/capture-screenshots.sh           # Capture all platforms
#   ./scripts/capture-screenshots.sh --ios     # iOS only (iPhone + iPad)
#   ./scripts/capture-screenshots.sh --mac     # macOS only
#   ./scripts/capture-screenshots.sh --watch   # watchOS only
#   ./scripts/capture-screenshots.sh --fastlane # Use fastlane (iOS/iPad only)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"
XCODE_PROJECT="$PROJECT_DIR/Uzumaki/Uzumaki.xcodeproj"
SCHEME="Uzumaki"

# Device definitions
IPHONE_DEVICE="iPhone 17 Pro Max"
IPAD_DEVICE="iPad Pro 13-inch (M5)"
WATCH_DEVICE="Apple Watch Series 11 (46mm)"
WATCH_PAIRED_PHONE="iPhone 17 Pro"

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
        2>&1 | xcbeautify || true
    
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
        2>&1 | xcbeautify || true
    
    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/iPad"
    
    shutdown_simulator "$IPAD_DEVICE"
    log_success "iPad screenshots captured!"
}

# Capture macOS screenshots
capture_mac() {
    log_info "=== Capturing macOS Screenshots ==="
    
    local result_bundle="$SCREENSHOTS_DIR/raw/mac-results.xcresult"
    rm -rf "$result_bundle"
    
    xcodebuild test \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=macOS" \
        -testPlan AppStoreScreenshots \
        -resultBundlePath "$result_bundle" \
        2>&1 | xcbeautify || true
    
    extract_screenshots "$result_bundle" "$SCREENSHOTS_DIR/Mac"
    
    log_warning "macOS screenshots may need post-processing (corner radius, shadow)"
    log_success "macOS screenshots captured!"
}

# Capture watchOS screenshots
capture_watch() {
    log_info "=== Capturing watchOS Screenshots ==="

    # Boot both watch and paired phone
    boot_simulator "$WATCH_PAIRED_PHONE"
    boot_simulator "$WATCH_DEVICE"

    # For watchOS, we use simctl directly since test support is limited
    log_info "Launching watch app..."
    xcrun simctl launch "$WATCH_DEVICE" com.uzumaki.app.watchkitapp || true
    sleep 3

    # Capture screenshots via simctl
    local timestamp=$(date +%Y%m%d_%H%M%S)
    xcrun simctl io "$WATCH_DEVICE" screenshot "$SCREENSHOTS_DIR/Watch/watch-01-$timestamp.png"

    shutdown_simulator "$WATCH_DEVICE"
    shutdown_simulator "$WATCH_PAIRED_PHONE"

    log_success "watchOS screenshots captured!"
}

# Extract screenshots from xcresult bundle
extract_screenshots() {
    local result_bundle="$1"
    local output_dir="$2"

    if [ ! -d "$result_bundle" ]; then
        log_warning "Result bundle not found: $result_bundle"
        return 1
    fi

    log_info "Extracting screenshots from $result_bundle..."

    # Extract PNG files directly from the xcresult Data directory
    local data_dir="$result_bundle/Data"
    if [ ! -d "$data_dir" ]; then
        log_warning "Data directory not found in result bundle"
        return 1
    fi

    local count=1
    for f in "$data_dir"/data.0~*; do
        [ -f "$f" ] || continue
        # Check if file is a PNG image
        if file "$f" 2>/dev/null | grep -q "PNG image"; then
            cp "$f" "$output_dir/screenshot-$count.png"
            log_info "Extracted: screenshot-$count.png"
            count=$((count + 1))
        fi
    done

    if [ $count -eq 1 ]; then
        log_warning "No screenshots found in result bundle"
        return 1
    fi

    log_success "Extracted $((count - 1)) screenshots to $output_dir"

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
        --fastlane)
            capture_fastlane
            ;;
        all|--all)
            setup_directories
            capture_ios
            capture_ipad
            capture_mac
            capture_watch
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

