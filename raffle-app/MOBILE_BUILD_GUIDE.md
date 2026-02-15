# Mobile App Build Guide

This guide shows how to build native Android and iOS apps from this web application using **Capacitor**.

> **Note:** This app uses **Capacitor**, not Flutter or React Native. Capacitor wraps the existing web application (HTML/CSS/JavaScript) into native mobile apps without requiring a rewrite in another framework.

## Prerequisites

### For Android:
- ✅ Java JDK 11 or higher
- ✅ Android Studio (latest version)
- ✅ Android SDK (API 33+)
- ✅ Gradle

### For iOS:
- ✅ macOS computer
- ✅ Xcode 14+ (from Mac App Store)
- ✅ Apple Developer Account ($99/year)
- ✅ CocoaPods (`sudo gem install cocoapods`)

---

## Setup Steps

### 1. Install Dependencies

```bash
cd raffle-app
npm install
```

### 2. Initialize Capacitor

```bash
npm run cap:init
# When prompted:
# App name: Grate Genyen
# App ID: com.grategenyen.raffle
# Web directory: www
```

### 3. Prepare Web Files

```bash
npm run build
# This copies public/* to www/
```

### 4. Add Platforms

**Note:** The `npm run android:build` and `npm run ios:build` scripts are only usable after you've added the respective platforms.

```bash
# Add Android
npm run cap:add:android

# Add iOS (macOS only)
npm run cap:add:ios
```

### 5. Sync Files

```bash
npm run cap:sync
```

---

## Android Build

### Development Build (APK)

```bash
# Open in Android Studio
npm run cap:open:android

# In Android Studio:
# 1. Build > Build Bundle(s) / APK(s) > Build APK(s)
# 2. Find APK in: android/app/build/outputs/apk/debug/app-debug.apk
```

### Production Build (AAB for Play Store)

```bash
# 1. Generate signing key (first time only)
cd android
keytool -genkey -v -keystore release-key.keystore -alias raffle-key -keyalg RSA -keysize 2048 -validity 10000

# 2. Build AAB
./gradlew bundleRelease

# 3. Find AAB in: android/app/build/outputs/bundle/release/app-release.aab
```

### Sign APK Manually

```bash
cd android/app/build/outputs/apk/release

# Align
zipalign -v -p 4 app-release-unsigned.apk app-release-unsigned-aligned.apk

# Sign
apksigner sign --ks ~/release-key.keystore --out app-release.apk app-release-unsigned-aligned.apk
```

---

## iOS Build

### Development Build

```bash
# Open in Xcode
npm run cap:open:ios

# In Xcode:
# 1. Select "App" scheme
# 2. Select your device or simulator
# 3. Product > Build (Cmd+B)
# 4. Product > Run (Cmd+R)
```

### Production Build (for App Store)

```bash
# In Xcode:
# 1. Product > Archive
# 2. Window > Organizer
# 3. Select archive > Distribute App
# 4. Choose "App Store Connect"
# 5. Follow prompts to upload
```

---

## Configuration

### Update Server URL

Edit `capacitor.config.json`:

```json
{
  "server": {
    "url": "https://your-production-domain.com"
  }
}
```

### Update App Icons

Replace icons in:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- iOS: `ios/App/App/Assets.xcassets/AppIcon.appiconset/`

Use the icon generation script:

```bash
node scripts/generate-icons.js
```

Or use a tool like [App Icon Generator](https://www.appicon.co/)

### Update Splash Screen

Replace splash in:
- Android: `android/app/src/main/res/drawable/splash.png`
- iOS: `ios/App/App/Assets.xcassets/Splash.imageset/splash.png`

---

## Testing

### Android Emulator

```bash
# Create emulator in Android Studio
# Tools > Device Manager > Create Device

# Run app
npm run cap:open:android
# Then click Run in Android Studio
```

### iOS Simulator

```bash
npm run cap:open:ios
# Then click Run in Xcode
```

### Real Device Testing

#### Android:
1. Enable USB Debugging on device
2. Connect device
3. Select device in Android Studio
4. Click Run

#### iOS:
1. Register device UDID in Apple Developer
2. Create provisioning profile
3. Select device in Xcode
4. Click Run

---

## Publishing

### Google Play Store (Android)

1. **Create App in Play Console**
   - Go to https://play.google.com/console
   - Create application
   - Fill in app details

2. **Upload AAB**
   - Production > Create new release
   - Upload `app-release.aab`
   - Set version code and name

3. **Complete Store Listing**
   - Add screenshots (phone, tablet)
   - Add app icon (512x512px)
   - Write description
   - Set content rating
   - Set target audience
   - Add privacy policy URL

4. **Submit for Review**
   - Review typically takes 1-3 days

### Apple App Store (iOS)

1. **Create App in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - My Apps > + > New App
   - Fill in app information

2. **Upload Build**
   - Use Xcode Organizer (Product > Archive > Distribute)
   - Or use Transporter app

3. **Complete App Information**
   - Add screenshots (required sizes for all devices)
   - Add app preview videos (optional)
   - Write description
   - Set pricing
   - Set age rating
   - Add privacy policy

4. **Submit for Review**
   - Review typically takes 1-2 days
   - More strict than Google

---

## Permissions Configuration

### Android Permissions

The generated `android/app/src/main/AndroidManifest.xml` will need these permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS Permissions

Add to `ios/App/App/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan barcodes and verify tickets.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photos to select ticket images.</string>
```

---

## Troubleshooting

### Android Build Fails

```bash
# Clean build
cd android
./gradlew clean

# Rebuild
./gradlew assembleRelease
```

### iOS Build Fails

```bash
# Clean
cd ios/App
xcodebuild clean

# Update pods
pod install --repo-update
```

### App Crashes on Launch

1. Check `capacitor.config.json` server URL
2. Verify API endpoints are accessible
3. Check console logs in Xcode/Android Studio
4. Ensure CORS is properly configured on server

### Gradle Build Issues

If you encounter Gradle wrapper permission issues:

```bash
cd android
chmod +x gradlew
```

### CocoaPods Issues

If CocoaPods installation fails:

```bash
cd ios/App
pod repo update
pod install
```

---

## Updates

### Over-The-Air (OTA) Updates

Consider Capacitor Live Updates for instant updates without app store:
- https://capacitorjs.com/docs/guides/live-updates

### Version Updates

1. Update `version` in `package.json`
2. Update `versionCode`/`versionName` in `android/app/build.gradle`
3. Update `CFBundleShortVersionString` in `ios/App/App/Info.plist`
4. Rebuild and redistribute

---

## App Store Requirements

### Google Play Store:
- ✅ App name: "Grate Genyen"
- ✅ Package: com.grategenyen.raffle
- ✅ Screenshots: 2-8 (phone & tablet)
- ✅ Feature graphic: 1024x500px
- ✅ App icon: 512x512px
- ✅ Privacy policy URL
- ✅ Content rating
- ✅ Target API 33+

### Apple App Store:
- ✅ App name: "Grate Genyen"
- ✅ Bundle ID: com.grategenyen.raffle
- ✅ Screenshots: All device sizes
- ✅ App icon: 1024x1024px
- ✅ Privacy policy
- ✅ Age rating
- ✅ Apple Developer Account ($99/year)
- ✅ App Review Guidelines compliance

---

## Testing Checklist

- [ ] Android APK installs and runs
- [ ] iOS app runs on simulator
- [ ] Camera barcode scanning works (if implemented)
- [ ] All pages load correctly
- [ ] Login and authentication work
- [ ] Scratch tickets function smoothly
- [ ] Admin features accessible
- [ ] Network connectivity handling
- [ ] App icons display correctly
- [ ] Splash screen shows
- [ ] Performance is smooth (60fps)
- [ ] Push notifications work (if implemented)
- [ ] Back button works on Android

---

## Timeline Estimate

- **Setup & Configuration**: 2-4 hours
- **Android Build & Test**: 4-6 hours
- **iOS Build & Test**: 4-6 hours
- **App Store Assets**: 2-3 hours
- **Submission & Review**: 1-3 days (Google) / 1-2 days (Apple)

**Total**: 2-3 days to first submission

---

## Resources

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Android Publishing Guide](https://developer.android.com/studio/publish)
- [iOS Publishing Guide](https://developer.apple.com/app-store/submitting/)
- [App Icon Generator](https://www.appicon.co/)
- [Screenshot Generator](https://www.screely.com/)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)

---

## Additional Notes

### Server Configuration

When running as a mobile app, the app will connect to the server URL specified in `capacitor.config.json`. Make sure:

1. Your server has proper CORS configuration
2. HTTPS is enabled for production
3. API endpoints are accessible from mobile devices
4. Session management works across mobile clients

### Development vs Production

For development, you can point the app to localhost:

```json
{
  "server": {
    "url": "http://192.168.1.x:3000",
    "cleartext": true
  }
}
```

Replace `192.168.1.x` with your local machine's IP address.

For production, always use HTTPS:

```json
{
  "server": {
    "url": "https://your-production-domain.com"
  }
}
```

### Native Features

The app is configured to use:
- **Camera**: For barcode scanning
- **Push Notifications**: For alerts
- **Network Status**: To detect offline mode
- **Splash Screen**: For professional startup
- **Status Bar**: For proper mobile UI

These features require additional implementation in your JavaScript code. Refer to Capacitor documentation for specific plugin usage.
