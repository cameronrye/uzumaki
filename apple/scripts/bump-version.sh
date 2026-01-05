#!/bin/bash
set -euo pipefail

# Bump version or build number for Uzumaki
# Usage: ./bump-version.sh [major|minor|patch|build]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$SCRIPT_DIR/../Uzumaki/Uzumaki.xcodeproj/project.pbxproj"

BUMP_TYPE="${1:-build}"

# Get current values
CURRENT_VERSION=$(grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/\1/')
CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | sed 's/.*= \(.*\);/\1/')

echo "Current: v$CURRENT_VERSION (build $CURRENT_BUILD)"

# Parse version components
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]:-0}"
MINOR="${VERSION_PARTS[1]:-0}"
PATCH="${VERSION_PARTS[2]:-0}"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_BUILD=1
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_BUILD=1
        ;;
    patch)
        PATCH=$((PATCH + 1))
        NEW_BUILD=1
        ;;
    build)
        NEW_BUILD=$((CURRENT_BUILD + 1))
        ;;
    *)
        echo "Usage: $0 [major|minor|patch|build]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update project file
if [[ "$BUMP_TYPE" != "build" ]]; then
    sed -i '' "s/MARKETING_VERSION = $CURRENT_VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" "$PROJECT_FILE"
fi
sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT_FILE"

echo "Updated: v$NEW_VERSION (build $NEW_BUILD)"

