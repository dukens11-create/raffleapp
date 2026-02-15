# Flutter Scratch Tickets - Build Guide

## Overview

This guide provides comprehensive instructions for building the Flutter Scratch Tickets mobile application for both Android and iOS platforms.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android Development** (for Android builds)
   - Android Studio
   - Android SDK (API level 21 or higher)
   - Java JDK 11 or higher

3. **iOS Development** (for iOS builds - macOS only)
   - Xcode 14 or higher
   - CocoaPods
   - Valid Apple Developer Account

### Environment Setup

1. Install Flutter SDK:
   ```bash
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. Run Flutter doctor to verify installation:
   ```bash
   flutter doctor -v
   ```

3. Accept Android licenses (if not already done):
   ```bash
   flutter doctor --android-licenses
   ```

## Project Setup

### 1. Install Dependencies

Navigate to the flutter_app directory and install dependencies:

```bash
cd flutter_app
flutter pub get
```

### 2. Verify Project Structure

Ensure the following directories exist:
- `android/` - Android platform files
- `ios/` - iOS platform files
- `lib/` - Dart source code
- `assets/` - Static assets

## Building for Android

### Debug Build (APK)

Build a debug APK for testing:

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build (APK)

Build a release APK for distribution:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (AAB) for Google Play Store

Build an Android App Bundle:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Signing Configuration (Production)

For production releases, configure signing:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. Update `android/app/build.gradle` to use the keystore (already configured in the template).

### Build Commands Summary

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for sideloading)
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release

# Split APKs by ABI (smaller file sizes)
flutter build apk --split-per-abi --release
```

## Building for iOS

**Note: iOS builds require macOS with Xcode installed.**

### 1. Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

### 2. Configure Signing

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Select the "Runner" project
   - Go to "Signing & Capabilities"
   - Select your development team
   - Configure the bundle identifier: `com.grategenyen.raffleapp`

### 3. Build Commands

#### Debug Build

```bash
flutter build ios --debug
```

#### Release Build

```bash
flutter build ios --release
```

#### Create IPA for Distribution

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/raffle_app.ipa`

### 4. TestFlight/App Store Deployment

1. Build the IPA:
   ```bash
   flutter build ipa --release
   ```

2. Upload to App Store Connect using Xcode or Application Loader:
   ```bash
   open build/ios/archive/*.xcarchive
   ```

3. In Xcode Organizer:
   - Select the archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow the prompts

## Running the App

### On Physical Device

#### Android
```bash
# Connect device via USB with USB debugging enabled
flutter devices
flutter run --release
```

#### iOS
```bash
# Connect device via USB
flutter devices
flutter run --release
```

### On Emulator/Simulator

#### Android Emulator
```bash
# Start emulator from Android Studio or:
emulator -avd <emulator-name>
flutter run
```

#### iOS Simulator
```bash
# List simulators
xcrun simctl list devices
# Boot simulator
open -a Simulator
flutter run
```

## Testing Scratch Tickets Feature

### Run Standalone Scratch App

The app includes a standalone entry point for testing scratch tickets:

```bash
flutter run -t lib/main_scratch.dart
```

This will launch the app directly to the scratch tickets gallery.

### Test All 6 Ticket Types

The app includes 6 ticket types:
1. **Basic** (50 HTG) - Green sparkle theme
2. **Premium** (100 HTG) - Purple cosmic theme
3. **Bronze** (250 HTG) - Bronze/orange gradient
4. **Silver** (500 HTG) - Silver holographic
5. **Gold** (1000 HTG) - Golden sunburst
6. **Diamond** (5000 HTG) - Blue icy diamonds

### Verify Features

- ✅ Ticket gallery display
- ✅ Scratch-off functionality
- ✅ Prize probability distributions
- ✅ Visual themes and gradients
- ✅ Prize reveal animations
- ✅ Play again functionality

## Build Optimization

### Reduce APK Size

```bash
# Split by ABI
flutter build apk --split-per-abi --release

# With obfuscation
flutter build apk --release --obfuscate --split-debug-info=/<project-name>/<directory>
```

### Performance Optimization

```bash
# Profile mode for performance testing
flutter run --profile

# Release mode with performance overlay
flutter run --release --profile
```

## Troubleshooting

### Common Issues

1. **Gradle build fails**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **iOS pod installation fails**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

3. **Flutter SDK not found**
   ```bash
   flutter doctor -v
   # Check PATH configuration
   ```

4. **License errors (Android)**
   ```bash
   flutter doctor --android-licenses
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: cd flutter_app && flutter pub get
      - run: cd flutter_app && flutter build apk --release
      - uses: actions/upload-artifact@v2
        with:
          name: release-apk
          path: flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

## Next Steps

1. Test on multiple devices and screen sizes
2. Configure analytics tracking
3. Implement backend integration
4. Set up crash reporting (Firebase Crashlytics)
5. Prepare store listings (screenshots, descriptions)
6. Submit to app stores

## Support

For issues or questions:
- Check Flutter documentation: https://docs.flutter.dev
- Review existing issues in the repository
- Contact the development team

## Version Information

- Flutter SDK: 3.0.0+
- Minimum Android SDK: 21 (Android 5.0)
- Minimum iOS: 12.0
- Target Android SDK: 34
- App Version: 1.0.0+1
