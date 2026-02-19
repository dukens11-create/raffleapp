#!/bin/bash
# Post-build tasks script
# Performs cleanup and reporting after building

set -e  # Exit on error

echo "=== Post-Build Tasks ==="
echo ""

# Navigate to flutter_app directory
cd "$(dirname "$0")/.." || exit 1

echo "✓ Checking build artifacts..."

# Check Android artifacts
if [ -d "build/app/outputs/flutter-apk" ]; then
    echo "✓ Android APK found:"
    ls -lh build/app/outputs/flutter-apk/*.apk
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "  APK Size: $APK_SIZE"
fi

if [ -d "build/app/outputs/bundle/release" ]; then
    echo "✓ Android App Bundle found:"
    ls -lh build/app/outputs/bundle/release/*.aab
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo "  AAB Size: $AAB_SIZE"
fi

# Check iOS artifacts
if [ -d "build/ios" ]; then
    echo "✓ iOS build artifacts found"
fi

echo ""
echo "✓ Generating build report..."
BUILD_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BUILD_REPORT="build/build_report.txt"

mkdir -p build

cat > "$BUILD_REPORT" << EOF
Build Report
============
Date: $BUILD_DATE
Flutter Version: $(flutter --version | head -n 1)

Artifacts:
EOF

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "- APK: $APK_SIZE" >> "$BUILD_REPORT"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "- AAB: $AAB_SIZE" >> "$BUILD_REPORT"
fi

echo ""
echo "✓ Build report saved to: $BUILD_REPORT"

echo ""
echo "✓ Cleaning up temporary files..."
# Clean up build cache if needed
# flutter clean --suppress-analytics

echo ""
echo "=== Post-Build Tasks Complete ==="
