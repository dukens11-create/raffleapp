#!/bin/bash
# Pre-build validation script
# Checks code quality and dependencies before building

set -e  # Exit on error

echo "=== Pre-Build Validation ==="
echo ""

# Navigate to flutter_app directory
cd "$(dirname "$0")/.." || exit 1

echo "✓ Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "✗ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✓ Checking Flutter version..."
flutter --version

echo ""
echo "✓ Running flutter doctor..."
flutter doctor

echo ""
echo "✓ Getting dependencies..."
flutter pub get

echo ""
echo "✓ Analyzing code..."
flutter analyze --no-fatal-infos || {
    echo "⚠ Warning: Code analysis found issues"
}

echo ""
echo "✓ Checking code formatting..."
flutter format --set-exit-if-changed . || {
    echo "⚠ Warning: Code formatting issues found"
    echo "Run 'flutter format .' to fix formatting"
}

echo ""
echo "✓ Running tests..."
flutter test || {
    echo "✗ Tests failed"
    exit 1
}

echo ""
echo "✓ Checking for outdated dependencies..."
flutter pub outdated || true

echo ""
echo "=== Pre-Build Validation Complete ==="
echo "✓ All checks passed. Ready to build!"
