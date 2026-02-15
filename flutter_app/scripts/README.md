# Flutter App Scripts

This directory contains utility scripts for the Flutter app build process.

## patch_qr_code_scanner.sh

**⚠️ DEPRECATED - NO LONGER NEEDED**

This script was previously used to patch the `qr_code_scanner` package, but the plugin has now been vendored locally in `local_plugins/qr_code_scanner` with the necessary fixes already applied.

**Historical Context**: The script was created to patch the cached `qr_code_scanner` package (version 1.0.1) to add the required Android `namespace` declaration in the `build.gradle` file.

**Current Solution**: As of February 2026, the `qr_code_scanner` plugin is vendored locally in the repository at `local_plugins/qr_code_scanner/` with all necessary Android compatibility fixes already applied. See `local_plugins/README.md` for details.

The patch script is kept for backwards compatibility with existing CI/CD configurations but will have no effect since the local plugin is now used instead of the pub.dev version.

---

### Original Documentation (For Historical Reference)

**Problem**: The `qr_code_scanner` package version 1.0.1 does not include a `namespace` declaration in its Android `build.gradle` file. This causes build errors with Android Gradle Plugin 8.0+ which requires namespace to be explicitly specified for all modules.

**Solution**: This script locates the cached package in the pub cache directory and adds the line:
```gradle
namespace 'com.yourcompany.qr_code_scanner'
```
to the `android/build.gradle` file after the `android {` declaration.
