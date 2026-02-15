# Flutter App Scripts

This directory contains utility scripts for the Flutter app build process.

## patch_qr_code_scanner.sh

**Purpose**: Patches the cached `qr_code_scanner` package (version 1.0.1) to add the required Android `namespace` declaration.

**Problem**: The `qr_code_scanner` package version 1.0.1 does not include a `namespace` declaration in its Android `build.gradle` file. This causes build errors with Android Gradle Plugin 8.0+ which requires namespace to be explicitly specified for all modules.

**Solution**: This script locates the cached package in the pub cache directory and adds the line:
```gradle
namespace 'com.yourcompany.qr_code_scanner'
```
to the `android/build.gradle` file after the `android {` declaration.

**Usage**:

```bash
# Make sure you've run flutter pub get first
cd flutter_app
flutter pub get

# Then run the patch script
./scripts/patch_qr_code_scanner.sh
```

The script is automatically executed in the CI/CD pipeline (Codemagic) after `flutter pub get`.

**⚠️ Important Note**:

This is a **temporary workaround**. The patch modifies the cached dependency, which is not an ideal long-term solution. 

**Recommended Action**: Update your `pubspec.yaml` to use a newer version of `qr_code_scanner` that includes the namespace declaration natively as soon as one becomes available. You can check for updates at:
- https://pub.dev/packages/qr_code_scanner

Alternatively, consider switching to the `mobile_scanner` package (already included in dependencies), which is actively maintained and includes proper namespace declarations.

## How the Patch Works

1. **Detects pub cache location**: Checks common locations (`$HOME/.pub-cache`, `/Users/builder/.pub-cache`)
2. **Locates the build.gradle**: Finds the file at `<pub-cache>/hosted/pub.dev/qr_code_scanner-1.0.1/android/build.gradle`
3. **Checks if already patched**: Skips patching if namespace already exists
4. **Creates backup**: Saves `.backup` file before making changes
5. **Adds namespace**: Inserts the namespace declaration after the `android {` line
6. **Verifies success**: Confirms the patch was applied

## Troubleshooting

If the script fails:

1. **Package not found**: Run `flutter pub get` first to download dependencies
2. **Permission denied**: Make sure the script is executable: `chmod +x scripts/patch_qr_code_scanner.sh`
3. **Already patched**: The script safely exits if namespace already exists
4. **Backup file exists**: The original file is backed up as `build.gradle.backup`

## Alternative Solutions

1. **Use mobile_scanner instead**: This package is already in your dependencies and is actively maintained
2. **Wait for upstream fix**: Monitor the qr_code_scanner package for updates
3. **Fork and fix**: Create your own fork with the namespace fix and use it in pubspec.yaml
