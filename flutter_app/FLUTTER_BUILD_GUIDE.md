# Flutter App Build Guide

This guide provides instructions for building and deploying the Flutter mobile application for the Grate Genyen raffle ticket management system.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [Development](#development)
- [Building for Production](#building-for-production)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

#### All Platforms
- **Flutter SDK** (3.0.0 or higher)
  - Download from: https://flutter.dev/docs/get-started/install
  - Verify installation: `flutter doctor`
- **Git**
- **VS Code** or **Android Studio** (recommended IDEs)

#### For Android Development
- **Android Studio** (latest version)
- **Android SDK** (API 21 or higher, recommended API 33+)
- **Java JDK** (11 or higher)
- **Android Emulator** or physical Android device

#### For iOS Development (macOS only)
- **macOS** (Big Sur or later)
- **Xcode** (14 or later)
- **CocoaPods**: `sudo gem install cocoapods`
- **iOS Simulator** or physical iOS device
- **Apple Developer Account** (for distribution)

## Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/dukens11-create/raffleapp.git
cd raffleapp/flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Backend API

Edit `lib/config/api_config.dart` and set your backend API URL:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://YOUR_BACKEND_URL:3000',
);
```

For local development:
- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator: `http://localhost:3000`
- Physical device: Use your computer's local IP (e.g., `http://192.168.1.100:3000`)

### 4. Generate Platform Files (if needed)

```bash
# Create Android and iOS folders
flutter create .

# Or create them separately
flutter create --platforms=android .
flutter create --platforms=ios .
```

## Development

### Run on Emulator/Simulator

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run in debug mode (default)
flutter run

# Run in profile mode (performance testing)
flutter run --profile

# Run with custom API URL
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Hot Reload

While the app is running:
- Press `r` to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Enable Debugging

```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Building for Production

### Android

#### Build APK (for testing)

```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build APK with custom API URL
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.com
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

#### Build App Bundle (for Google Play Store)

```bash
# Build release app bundle
flutter build appbundle --release

# Build with custom API URL
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api.com
```

The App Bundle will be located at: `build/app/outputs/bundle/release/app-release.aab`

#### Sign the App

1. Create a keystore (first time only):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties`:
```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=upload
storeFile=<path_to_keystore>
```

3. Update `android/app/build.gradle` to use the keystore (already configured in Flutter projects)

### iOS

#### Prerequisites
- macOS with Xcode installed
- Apple Developer Account

#### Build for iOS

```bash
# Build iOS app
flutter build ios --release

# Build with custom API URL
flutter build ios --release --dart-define=API_BASE_URL=https://your-api.com
```

#### Configure Xcode

1. Open the iOS project in Xcode:
```bash
open ios/Runner.xcworkspace
```

2. In Xcode:
   - Select the `Runner` project
   - Go to `Signing & Capabilities`
   - Select your team
   - Configure bundle identifier (e.g., `com.grategenyen.raffle`)

3. Archive and upload to App Store:
   - Product → Archive
   - Once archived, click "Distribute App"
   - Follow the prompts to upload to App Store Connect

## Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests on device
flutter test integration_test
```

## App Configuration

### App Name and Bundle Identifier

#### Android
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Grate Genyen"
    ...>
```

Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.grategenyen.raffle"
    ...
}
```

#### iOS
Open `ios/Runner.xcworkspace` in Xcode and:
- Update Display Name
- Update Bundle Identifier

### App Icons

Place your app icons in:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Or use the `flutter_launcher_icons` package:
```yaml
# Add to pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

Then run:
```bash
flutter pub run flutter_launcher_icons
```

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
flutter doctor -v
```
Follow the recommendations to fix any issues.

#### Gradle Build Fails (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### CocoaPods Issues (iOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### App Crashes on Startup
- Check backend API URL configuration
- Ensure backend server is running
- Check device logs:
  - Android: `adb logcat`
  - iOS: Use Xcode Console

#### Network Issues
- For Android emulator, use `10.0.2.2` to access localhost
- For iOS simulator, use `localhost`
- For physical devices, use your computer's local IP address
- Ensure backend has proper CORS configuration

### Performance Issues

#### Check Performance Metrics
```bash
flutter run --profile
# Open DevTools and check performance tab
```

#### Reduce App Size
```bash
# Use --split-per-abi for Android
flutter build apk --split-per-abi --release
```

## Deployment

### Google Play Store

1. Build app bundle:
```bash
flutter build appbundle --release
```

2. Go to [Google Play Console](https://play.google.com/console)
3. Create a new app
4. Upload the app bundle from `build/app/outputs/bundle/release/app-release.aab`
5. Fill in store listing details
6. Submit for review

### Apple App Store

1. Build and archive in Xcode
2. Upload to App Store Connect
3. Go to [App Store Connect](https://appstoreconnect.apple.com)
4. Fill in app information
5. Submit for review

## Environment Variables

Use `--dart-define` to pass environment variables:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Access in code:
```dart
const apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
```

## Backend Requirements

The Flutter app requires the backend API to be running. Ensure:
- Backend is accessible from mobile devices
- CORS is properly configured
- API endpoints match the configuration in `lib/config/api_config.dart`
- HTTPS is used for production deployments

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Android Publishing Guide](https://developer.android.com/studio/publish)
- [iOS Publishing Guide](https://developer.apple.com/app-store/submitting/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter documentation
3. Open an issue in the repository

## License

This project is licensed under the MIT License. See the main repository README for details.
