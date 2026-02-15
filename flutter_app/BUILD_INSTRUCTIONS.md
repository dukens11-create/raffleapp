# Build Instructions

## Prerequisites

- Flutter SDK 3.10+ (recommended: latest stable version)
- For Android: Android Studio with SDK 21+ (API 21 minimum, API 34 target)
- For iOS: macOS with Xcode 14+

## Local Build Commands

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
