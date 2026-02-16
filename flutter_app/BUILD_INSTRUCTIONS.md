# Build Instructions

## Prerequisites

- Flutter SDK 3.10+ (recommended: latest stable version)
- For Android: Android Studio with SDK 21+ (API 21 minimum, API 34 target)
- For iOS: macOS with Xcode 14+

## Local Build Commands

### Setup Dependencies

Before building, install dependencies and apply necessary patches:

```bash
# Install Flutter dependencies
flutter pub get

# Apply patch for qr_code_scanner package (fixes Android Gradle Plugin 8.0+ compatibility)
./scripts/patch_qr_code_scanner.sh
```

**Note**: The `qr_code_scanner` package (v1.0.1) requires a patch to add the Android `namespace` declaration. This patch is automatically applied in CI/CD builds. For local builds, run the patch script after `flutter pub get`.

**⚠️ Recommendation**: Consider updating to a newer version of `qr_code_scanner` or switching to `mobile_scanner` (already in dependencies) when possible. See `scripts/README.md` for details.

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release AAB (Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build iOS (requires macOS)
flutter build ios --release

# Build IPA
flutter build ipa --release
```

## Codemagic CI/CD

This project uses Codemagic for automated builds. The `codemagic.yaml` file in the root configures:

- **Android Workflow**: Builds APK and AAB
- **iOS Workflow**: Builds IPA
- **Combined Workflow**: Builds both platforms

### Required Environment Variables

Set these in Codemagic dashboard:

**For Android:**
- `CM_KEYSTORE` - Base64-encoded keystore file
- `CM_KEYSTORE_PASSWORD` - Keystore password
- `CM_KEY_PASSWORD` - Key password
- `CM_KEY_ALIAS` - Key alias

**For iOS:**
- `CM_CERTIFICATE` - Base64-encoded .p12 certificate
- `CM_CERTIFICATE_PASSWORD` - Certificate password
- `CM_PROVISIONING_PROFILE` - Base64-encoded provisioning profile

## Troubleshooting

### iOS Build Fails

1. Ensure Xcode is installed: `xcode-select --install`
2. Install CocoaPods: `sudo gem install cocoapods`
3. Run pod install: `cd ios && pod install`

### Android Build Fails

1. Accept licenses: `flutter doctor --android-licenses`
2. Check SDK: `flutter doctor -v`
3. If you get namespace errors for `qr_code_scanner`, ensure you've run the patch script:
   ```bash
   ./scripts/patch_qr_code_scanner.sh
   ```
