#!/bin/bash
# capture-app-preview.sh - Record App Preview videos for App Store
# 
# App Preview Requirements:
#   - Duration: 15-30 seconds
#   - Format: H.264 codec, .mp4 or .mov
#   - Frame rate: 30 fps
#   - Resolution: Device-specific (see below)
#
# Usage:
#   ./scripts/capture-app-preview.sh --iphone    # iPhone 6.9" preview
#   ./scripts/capture-app-preview.sh --ipad      # iPad 13" preview
#   ./scripts/capture-app-preview.sh --mac       # Mac preview

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PREVIEWS_DIR="$PROJECT_DIR/previews"
BUNDLE_ID="com.uzumaki.app"

# Device definitions
IPHONE_DEVICE="iPhone 16 Pro Max"
IPAD_DEVICE="iPad Pro 13-inch (M4)"

# Video specifications per device
# iPhone 6.9": 1290x2796 or 886x1920 (portrait)
# iPhone 6.5": 1242x2688 or 886x1920 (portrait)
# iPad 13": 2048x2732 or 1200x1600 (portrait)
# Mac: 1920x1080

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

# Setup directories
setup() {
    mkdir -p "$PREVIEWS_DIR/raw"
    mkdir -p "$PREVIEWS_DIR/final"
}

# Boot simulator
boot_simulator() {
    local device="$1"
    log_info "Booting $device..."
    xcrun simctl boot "$device" 2>/dev/null || true
    sleep 3
}

# Record video from simulator
record_simulator() {
    local device="$1"
    local output="$2"
    local duration="${3:-30}"
    
    log_info "Recording video: $output"
    log_info "Duration: ${duration}s (Press Ctrl+C to stop early)"
    log_warning "Interact with the app to create your preview content"
    
    # Launch the app
    xcrun simctl launch "$device" "$BUNDLE_ID" 2>/dev/null || true
    sleep 2
    
    # Start recording with H.264 codec (required for App Store)
    # Use timeout to auto-stop after duration
    timeout "${duration}s" xcrun simctl io "$device" recordVideo \
        --codec=h264 \
        --force \
        "$output" 2>/dev/null || true
    
    log_success "Recording saved: $output"
}

# Process video to App Store specs
process_video() {
    local input="$1"
    local output="$2"
    local width="$3"
    local height="$4"
    
    if ! command -v ffmpeg &> /dev/null; then
        log_warning "ffmpeg not found. Install with: brew install ffmpeg"
        log_info "Skipping video processing. Raw video saved."
        return 1
    fi
    
    log_info "Processing video to App Store specs..."
    
    ffmpeg -y -i "$input" \
        -vf "scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2,fps=30" \
        -c:v libx264 \
        -preset slow \
        -crf 18 \
        -an \
        "$output" 2>/dev/null
    
    log_success "Processed video: $output"
}

# Capture iPhone App Preview
capture_iphone() {
    log_info "=== Recording iPhone App Preview ==="
    
    boot_simulator "$IPHONE_DEVICE"
    
    local raw_file="$PREVIEWS_DIR/raw/iphone-preview-raw.mp4"
    local final_file="$PREVIEWS_DIR/final/iphone-6.9-preview.mp4"
    
    record_simulator "$IPHONE_DEVICE" "$raw_file" 30
    process_video "$raw_file" "$final_file" 1290 2796
    
    xcrun simctl shutdown "$IPHONE_DEVICE" 2>/dev/null || true
}

# Capture iPad App Preview
capture_ipad() {
    log_info "=== Recording iPad App Preview ==="
    
    boot_simulator "$IPAD_DEVICE"
    
    local raw_file="$PREVIEWS_DIR/raw/ipad-preview-raw.mp4"
    local final_file="$PREVIEWS_DIR/final/ipad-13-preview.mp4"
    
    record_simulator "$IPAD_DEVICE" "$raw_file" 30
    process_video "$raw_file" "$final_file" 2048 2732
    
    xcrun simctl shutdown "$IPAD_DEVICE" 2>/dev/null || true
}

# Capture Mac App Preview (screen recording)
capture_mac() {
    log_info "=== Recording Mac App Preview ==="
    log_warning "Mac preview requires manual screen recording"
    echo ""
    echo "Steps for Mac App Preview:"
    echo "1. Open the Uzumaki app"
    echo "2. Press Cmd+Shift+5 to open screen recording"
    echo "3. Select 'Record Selected Portion'"
    echo "4. Set area to 1920x1080"
    echo "5. Record for 15-30 seconds"
    echo "6. Save to: $PREVIEWS_DIR/final/mac-preview.mov"
    echo ""
    log_info "Opening Uzumaki..."
    open -a "Uzumaki" 2>/dev/null || log_warning "Could not open app. Build and run first."
}

# Main
main() {
    setup
    
    case "${1:-}" in
        --iphone) capture_iphone ;;
        --ipad) capture_ipad ;;
        --mac) capture_mac ;;
        --all) capture_iphone; capture_ipad; capture_mac ;;
        *)
            echo "Usage: $0 [--iphone|--ipad|--mac|--all]"
            echo ""
            echo "Records App Preview videos for App Store submission"
            ;;
    esac
}

main "$@"
