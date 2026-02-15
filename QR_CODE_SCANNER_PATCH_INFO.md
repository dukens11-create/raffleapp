# QR Code Scanner Package - Local Vendoring Information

## ✅ Current Solution (February 2026)

The `qr_code_scanner` package has been **vendored locally** in the repository to resolve Android build compatibility issues. The plugin is now located at:

```
local_plugins/qr_code_scanner/
```

### Changes Made:

1. **Vendored the plugin locally**: The entire `qr_code_scanner` v1.0.1 package from pub.dev has been copied into `local_plugins/qr_code_scanner/`

2. **Fixed AndroidManifest.xml**: Removed the deprecated `package` attribute from `android/src/main/AndroidManifest.xml`
   - **Before**: `<manifest package="net.touchcapture.qr.flutterqr" ...>`
   - **After**: `<manifest xmlns:tools="http://schemas.android.com/tools">`

3. **Updated pubspec.yaml**: Changed from pub.dev dependency to local path dependency:
   ```yaml
   qr_code_scanner:
     path: ../local_plugins/qr_code_scanner
   ```

4. **Added documentation**: Created `local_plugins/README.md` explaining the vendoring and modifications

## 🐛 Problems Solved

### Primary Issue (Current)
**Error**: "Incorrect package='net.touchcapture.qr.flutterqr' found in source AndroidManifest.xml. Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported."

**Root Cause**: Modern Android Gradle Plugin versions no longer allow setting the package namespace via the `package` attribute in AndroidManifest.xml. The namespace must be declared in the module's `build.gradle` file instead.

### Secondary Issue (Previously Addressed)
The package also had issues with missing `namespace` declaration in `build.gradle`, which was previously addressed by a patch script. This is now handled automatically as part of the vendored plugin.

## 📋 How to Build

Building the app now works seamlessly:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter build apk --release  # or other build commands
```

No additional patch scripts or manual steps are required. The local plugin is automatically used.

## 🔍 Technical Details

The vendored plugin includes:
- All Dart source files from the original package
- Android implementation (Kotlin)
- iOS implementation (Swift/Objective-C)
- Modified AndroidManifest.xml without the deprecated `package` attribute
- Original pubspec.yaml, LICENSE, README, and CHANGELOG

The Android build.gradle in the vendored plugin has been updated to include the required namespace configuration (`namespace 'net.touchcapture.qr.flutterqr'`) as required by Android Gradle Plugin 7.0+.

## ⚠️ Migration Path

This is a **temporary solution** until:

1. The upstream `qr_code_scanner` package is updated to fix these compatibility issues
2. The project migrates to an alternative package like `mobile_scanner` (already a dependency)

To check for updates:
- https://pub.dev/packages/qr_code_scanner

When a fixed version is available, you can switch back by updating `pubspec.yaml`:
```yaml
qr_code_scanner: ^1.0.2  # or newer fixed version
```

And removing the `local_plugins/qr_code_scanner` directory.

---

## 📜 Historical Information

The previous approach used a patch script (`flutter_app/scripts/patch_qr_code_scanner.sh`) to modify the cached pub.dev package. This approach had limitations:
- Required running the patch script after every `flutter pub get` or cache clear
- Modified cached dependencies, which is not a sustainable solution
- Patch needed to be maintained and coordinated with CI/CD

The local vendoring approach is more reliable and requires no runtime patches.
