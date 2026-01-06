#!/bin/bash
set -eo pipefail

# Uzumaki TestFlight Deployment Script
# Usage: ./deploy-testflight.sh [ios|macos|all] [--archive-only]
#
# Prerequisites:
# - Xcode installed and signed in with Apple ID
# - App registered in App Store Connect (com.uzumaki.app)
# - Distribution certificate and provisioning profile (auto-managed by Xcode)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/Uzumaki/Uzumaki.xcodeproj"
SCHEME="Uzumaki"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_DIR="$BUILD_DIR/archives"
EXPORT_DIR="$BUILD_DIR/export"

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

# Parse arguments
PLATFORM="${1:-all}"
ARCHIVE_ONLY=false
if [[ "${2:-}" == "--archive-only" ]]; then
    ARCHIVE_ONLY=true
fi

# Validate platform argument
if [[ ! "$PLATFORM" =~ ^(ios|macos|all)$ ]]; then
    log_error "Invalid platform: $PLATFORM. Use 'ios', 'macos', or 'all'"
    exit 1
fi

# Create build directories
mkdir -p "$ARCHIVE_DIR" "$EXPORT_DIR"

# Get version info from project
get_version() {
    grep -m1 "MARKETING_VERSION" "$XCODE_PROJECT/project.pbxproj" | head -1 | sed 's/.*= \(.*\);/\1/'
}

get_build_number() {
    grep -m1 "CURRENT_PROJECT_VERSION" "$XCODE_PROJECT/project.pbxproj" | head -1 | sed 's/.*= \(.*\);/\1/'
}

VERSION=$(get_version)
BUILD_NUMBER=$(get_build_number)

log_info "Deploying Uzumaki v$VERSION ($BUILD_NUMBER) to TestFlight"
log_info "Platform: $PLATFORM"

# Clean derived data to ensure fresh build
clean_derived_data() {
    log_info "Cleaning derived data..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Uzumaki-* 2>/dev/null || true
}

# Archive function - returns archive path via global variable to avoid tee output capture issues
archive_app() {
    local platform=$1
    local destination=$2
    LAST_ARCHIVE_PATH="$ARCHIVE_DIR/Uzumaki-${platform}-${VERSION}-${BUILD_NUMBER}.xcarchive"

    # Remove old archive if exists
    rm -rf "$LAST_ARCHIVE_PATH" 2>/dev/null || true

    log_info "Archiving for $platform..."

    set +e
    xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "$destination" \
        -archivePath "$LAST_ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        2>&1 | tee "$BUILD_DIR/archive-${platform}.log"
    local result=${PIPESTATUS[0]}
    set -e

    if [[ $result -eq 0 ]] && [[ -d "$LAST_ARCHIVE_PATH" ]]; then
        log_success "Archive created: $LAST_ARCHIVE_PATH"
        return 0
    else
        log_error "Archive failed for $platform. Check $BUILD_DIR/archive-${platform}.log"
        return 1
    fi
}

# Export and upload function
upload_to_testflight() {
    local archive_path=$1
    local platform=$2
    local export_path="$EXPORT_DIR/${platform}"

    log_info "Exporting and uploading $platform build to TestFlight..."

    # Clean export directory
    rm -rf "$export_path" 2>/dev/null || true
    mkdir -p "$export_path"

    # Create export options plist for App Store Connect upload
    local export_options="$BUILD_DIR/ExportOptions-${platform}.plist"
    cat > "$export_options" << 'EXPORTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>upload</string>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EXPORTEOF

    set +e
    xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportOptionsPlist "$export_options" \
        -exportPath "$export_path" \
        -allowProvisioningUpdates \
        2>&1 | tee "$BUILD_DIR/upload-${platform}.log"
    local result=$?
    set -e

    if [[ $result -eq 0 ]]; then
        log_success "$platform build uploaded to TestFlight!"
        return 0
    else
        log_error "Upload failed for $platform. Check $BUILD_DIR/upload-${platform}.log"
        log_info "You can manually upload via: Xcode > Window > Organizer > Archives"
        log_info "Archive location: $archive_path"
        return 1
    fi
}

# Main deployment logic
main() {
    local ios_success=true
    local macos_success=true

    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        log_info "=== iOS Build ==="
        if archive_app "ios" "generic/platform=iOS"; then
            IOS_ARCHIVE="$LAST_ARCHIVE_PATH"
            if [[ "$ARCHIVE_ONLY" == false ]]; then
                upload_to_testflight "$IOS_ARCHIVE" "ios" || ios_success=false
            else
                log_info "Archive only mode - skipping upload"
                log_info "iOS Archive: $IOS_ARCHIVE"
            fi
        else
            ios_success=false
        fi
    fi

    if [[ "$PLATFORM" == "macos" || "$PLATFORM" == "all" ]]; then
        log_info "=== macOS Build ==="
        if archive_app "macos" "generic/platform=macOS"; then
            MACOS_ARCHIVE="$LAST_ARCHIVE_PATH"
            if [[ "$ARCHIVE_ONLY" == false ]]; then
                upload_to_testflight "$MACOS_ARCHIVE" "macos" || macos_success=false
            else
                log_info "Archive only mode - skipping upload"
                log_info "macOS Archive: $MACOS_ARCHIVE"
            fi
        else
            macos_success=false
        fi
    fi

    echo ""
    log_info "=== Summary ==="

    if [[ "$ARCHIVE_ONLY" == true ]]; then
        log_success "Archives created successfully!"
        log_info "To upload manually: Xcode > Window > Organizer > Archives"
    else
        if [[ "$ios_success" == true ]] && [[ "$macos_success" == true ]]; then
            log_success "All builds uploaded to TestFlight!"
            log_info "Builds will be processed by Apple (5-30 minutes)"
            log_info "Check status: https://appstoreconnect.apple.com/apps/6757408848/testflight"
        else
            log_warning "Some uploads failed. Check logs in $BUILD_DIR/"
            log_info "You can upload manually via Xcode Organizer"
        fi
    fi
}

main

