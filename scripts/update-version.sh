#!/bin/bash

# Script to update Info.plist with git version
# Can be run locally or in CI/CD

set -e

# Get the git version tag
GIT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "$GIT_VERSION" ]; then
    echo "No git tags found, skipping version update"
    exit 0
fi

# Remove 'v' prefix if present (e.g., v0.0.2 -> 0.0.2)
VERSION=${GIT_VERSION#v}

# Path to Info.plist
INFO_PLIST="Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Info.plist not found at $INFO_PLIST"
    exit 1
fi

# Update the version in Info.plist
echo "Updating Info.plist version to: $VERSION"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST"

# Also update the build number to commit count for uniqueness
BUILD_NUMBER=$(git rev-list --count HEAD)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFO_PLIST"

echo "Updated version to $VERSION (Build $BUILD_NUMBER)"