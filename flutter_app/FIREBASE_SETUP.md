# Firebase Setup Guide for Grate Genyen Mobile App

## Prerequisites
- Firebase account
- Flutter development environment
- Android Studio (for Android)
- Xcode (for iOS, Mac only)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Grate Genyen" (or your preferred name)
4. Enable/disable Google Analytics as needed
5. Click "Create project"

## Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android icon
2. **Android package name:** `com.example.raffle_app`
   - To find yours: Check `android/app/build.gradle` → `applicationId`
3. **App nickname:** "Grate Genyen Android" (optional)
4. Click "Register app"

### Download Configuration File
1. Download `google-services.json`
2. Move it to: `flutter_app/android/app/google-services.json`
   - **Important:** Do NOT commit this file to version control
   - A template is provided at `google-services.json.example`

### Update Android Build Files

**File: `android/build.gradle`**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

**File: `android/app/build.gradle`**
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

## Step 3: Add iOS App

1. In Firebase Console, click "Add app" → iOS icon
2. **iOS bundle ID:** `com.example.raffleApp`
   - To find yours: Open Xcode → Runner → General → Bundle Identifier
3. **App nickname:** "Grate Genyen iOS" (optional)
4. Click "Register app"

### Download Configuration File
1. Download `GoogleService-Info.plist`
2. Open Xcode project: `ios/Runner.xcworkspace`
3. Right-click on "Runner" folder → Add Files to "Runner"
4. Select `GoogleService-Info.plist`
5. **Important:** Do NOT commit this file to version control
   - A template is provided at `GoogleService-Info.plist.example`

## Step 4: Enable Firebase Cloud Messaging

1. In Firebase Console, go to Project Settings
2. Click "Cloud Messaging" tab
3. Note your **Sender ID** and **Server Key**
4. Enable Cloud Messaging API (if prompted)

### iOS Additional Setup

1. In Firebase Console → Cloud Messaging → iOS
2. Upload APNs Authentication Key or Certificate
   - **Option A: APNs Authentication Key (Recommended)**
     - Generate in Apple Developer Portal
     - Upload .p8 file
   - **Option B: APNs Certificate**
     - Generate CSR in Keychain Access
     - Create certificate in Apple Developer Portal
     - Upload .p12 file

## Step 5: Update App Configuration

### Update Firebase Config
Edit `lib/config/firebase_config.dart`:

```dart
static FirebaseOptions _getFirebaseOptions() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return const FirebaseOptions(
      apiKey: 'YOUR_ANDROID_API_KEY',           // From google-services.json
      appId: 'YOUR_ANDROID_APP_ID',             // From google-services.json
      messagingSenderId: 'YOUR_SENDER_ID',      // From google-services.json
      projectId: 'YOUR_PROJECT_ID',             // From google-services.json
      storageBucket: 'YOUR_STORAGE_BUCKET',     // From google-services.json
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const FirebaseOptions(
      apiKey: 'YOUR_IOS_API_KEY',               // From GoogleService-Info.plist
      appId: 'YOUR_IOS_APP_ID',                 // From GoogleService-Info.plist
      messagingSenderId: 'YOUR_SENDER_ID',      // From GoogleService-Info.plist
      projectId: 'YOUR_PROJECT_ID',             // From GoogleService-Info.plist
      storageBucket: 'YOUR_STORAGE_BUCKET',     // From GoogleService-Info.plist
      iosBundleId: 'YOUR_IOS_BUNDLE_ID',        // From GoogleService-Info.plist
    );
  }
  throw UnsupportedError('Platform not supported');
}
```

## Step 6: Test Firebase Setup

### Test Android
```bash
cd flutter_app
flutter run -d <android-device>
```

Check logs for:
```
I/Flutter: Firebase initialized successfully
I/Flutter: FCM Token: <your-token>
```

### Test iOS
```bash
cd flutter_app
flutter run -d <ios-device>
```

Check logs for:
```
Flutter: Firebase initialized successfully
Flutter: FCM Token: <your-token>
```

## Step 7: Send Test Notification

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification details:
   - Title: "Test Notification"
   - Text: "Testing Firebase Cloud Messaging"
4. Click "Send test message"
5. Enter FCM token from app logs
6. Click "Test"

You should receive the notification on your device!

## Troubleshooting

### Android Issues

**Error: "google-services.json not found"**
- Ensure file is at `android/app/google-services.json`
- Check file name is exactly `google-services.json`

**Error: "Default FirebaseApp is not initialized"**
- Check `apply plugin: 'com.google.gms.google-services'` is in `android/app/build.gradle`
- Ensure plugin version is correct in root `build.gradle`

**Error: "Failed to get token"**
- Check internet connection
- Verify package name matches Firebase console
- Try clearing app data and reinstalling

### iOS Issues

**Error: "GoogleService-Info.plist not found"**
- Ensure file is added to Xcode project (not just copied to folder)
- Check file is included in Runner target

**Error: "No APNs token"**
- Ensure APNs certificate/key is uploaded to Firebase
- Check Bundle ID matches Firebase console
- Test on real device (not simulator for push notifications)

**Error: "Remote notification registration failed"**
- Enable Push Notifications capability in Xcode
- Check provisioning profile includes push notifications

### General Issues

**Notifications not received**
1. Check FCM token is generated and registered
2. Verify device has internet connection
3. Ensure app has notification permissions
4. Check Firebase Console for delivery status
5. Test with Firebase Console "Send test message" first

**Background notifications not working**
1. Add background mode capabilities (iOS)
2. Implement background message handler
3. Test with app in background/terminated state

## Security Best Practices

1. **Never commit configuration files:**
   - Add to `.gitignore`:
     ```
     android/app/google-services.json
     ios/Runner/GoogleService-Info.plist
     ```

2. **Use environment variables for sensitive data**
   - Store server key securely
   - Use different Firebase projects for dev/prod

3. **Restrict API keys:**
   - In Firebase Console → Project Settings → API Keys
   - Restrict Android key to your app's SHA-1
   - Restrict iOS key to your bundle ID

4. **Monitor usage:**
   - Check Firebase Console regularly
   - Set up billing alerts
   - Monitor for unusual activity

## Production Checklist

Before deploying to production:

- [ ] Firebase project created for production
- [ ] Android app registered with production package name
- [ ] iOS app registered with production bundle ID
- [ ] APNs certificates uploaded (iOS)
- [ ] Configuration files updated with production values
- [ ] API keys restricted
- [ ] Backend endpoints configured for FCM
- [ ] Test notifications working on production build
- [ ] Analytics enabled (optional)
- [ ] Crash reporting enabled (optional)

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Setup Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [APNs Setup Guide](https://firebase.google.com/docs/cloud-messaging/ios/certs)

## Support

For issues specific to this implementation:
- Check `PHASE3_IMPLEMENTATION.md`
- Review sync logs in Debug screen (`/debug/sync`)
- Check Flutter console logs

For Firebase-specific issues:
- [Firebase Support](https://firebase.google.com/support)
- [Stack Overflow - Firebase](https://stackoverflow.com/questions/tagged/firebase)
