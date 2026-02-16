#!/bin/bash
# Script to patch qr_code_scanner package in pub cache
# This adds the required 'namespace' declaration to the Android build.gradle file
# to resolve build errors with Android Gradle Plugin 8.0+

set -e

echo "Patching qr_code_scanner package..."

# Determine the pub cache directory
if [ -z "$PUB_CACHE" ]; then
    if [ -d "$HOME/.pub-cache" ]; then
        PUB_CACHE="$HOME/.pub-cache"
    elif [ -d "/Users/builder/.pub-cache" ]; then
        PUB_CACHE="/Users/builder/.pub-cache"
    else
        echo "Error: Could not find pub cache directory"
        exit 1
    fi
fi

# Path to the qr_code_scanner build.gradle file
QR_SCANNER_BUILD_GRADLE="$PUB_CACHE/hosted/pub.dev/qr_code_scanner-1.0.1/android/build.gradle"

# Check if the file exists
if [ ! -f "$QR_SCANNER_BUILD_GRADLE" ]; then
    echo "Warning: qr_code_scanner-1.0.1 build.gradle not found at: $QR_SCANNER_BUILD_GRADLE"
    echo "Package may not be cached yet. Run 'flutter pub get' first."
    exit 0
fi

# Check if namespace is already present
if grep -q "namespace" "$QR_SCANNER_BUILD_GRADLE"; then
    echo "Namespace already present in qr_code_scanner build.gradle. No patching needed."
    exit 0
fi

echo "Adding namespace to qr_code_scanner build.gradle..."

# Create a backup
cp "$QR_SCANNER_BUILD_GRADLE" "$QR_SCANNER_BUILD_GRADLE.backup"

# Add namespace after the 'android {' line
# This uses sed to insert the namespace line after the first occurrence of 'android {'
sed -i.tmp '/^android {/a\
    namespace '\''com.yourcompany.qr_code_scanner'\''
' "$QR_SCANNER_BUILD_GRADLE"

# Remove the temporary file created by sed
rm -f "$QR_SCANNER_BUILD_GRADLE.tmp"

echo "✅ Successfully patched qr_code_scanner build.gradle"
echo "   Added: namespace 'com.yourcompany.qr_code_scanner'"
echo ""
echo "⚠️  IMPORTANT: This is a temporary workaround."
echo "   Please update pubspec.yaml to use a newer version of qr_code_scanner"
echo "   that includes the namespace declaration natively as soon as available."
