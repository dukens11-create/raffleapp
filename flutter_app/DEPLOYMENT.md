# Deployment Guide

This guide covers the deployment process for the Grate Genyen Flutter mobile app.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build Configurations](#build-configurations)
3. [Android Deployment](#android-deployment)
4. [iOS Deployment](#ios-deployment)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [App Store Submission](#app-store-submission)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- Flutter SDK 3.16.0+
- Android Studio (for Android)
- Xcode 15+ (for iOS, macOS only)
- Firebase account (for Firebase integration)
- Google Play Console account
- Apple Developer account

### Required Credentials

- **Android**:
  - Keystore file
  - Key alias and passwords
  - Google Play service account JSON

- **iOS**:
  - Apple Developer certificate
  - Provisioning profiles
  - App Store Connect API key

## Build Configurations

### Environment Variables

Create environment-specific configurations:

```dart
// lib/config/environment.dart
enum Environment { dev, staging, production }

class AppConfig {
  static Environment env = Environment.production;
  
  static String get apiUrl {
    switch (env) {
      case Environment.dev:
        return 'http://localhost:3000';
      case Environment.staging:
        return 'https://staging.grategenyen.com';
      case Environment.production:
        return 'https://grategenyen.com';
    }
  }
}
```

### Build Flavors

Configure build flavors in build files:

**Android** (`android/app/build.gradle`):
```gradle
flavorDimensions "environment"
productFlavors {
    dev {
        dimension "environment"
        applicationIdSuffix ".dev"
        versionNameSuffix "-dev"
    }
    staging {
        dimension "environment"
        applicationIdSuffix ".staging"
        versionNameSuffix "-staging"
    }
    production {
        dimension "environment"
    }
}
```

**iOS** (Xcode schemes)
- Create schemes for dev, staging, production
- Configure different bundle identifiers

## Android Deployment

### Step 1: Generate Signing Key

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### Step 2: Configure Signing

Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore>
```

Update `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 3: Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK by ABI (smaller size)
flutter build apk --split-per-abi --release
```

### Step 4: Build App Bundle (AAB)

```bash
# Recommended for Play Store
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 5: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to "Release" → "Production"
4. Click "Create new release"
5. Upload the AAB file
6. Fill in release notes
7. Review and rollout

### Play Store Listing Requirements

- **App name**: Max 30 characters
- **Short description**: Max 80 characters
- **Full description**: Max 4000 characters
- **Screenshots**: At least 2, up to 8 per device type
- **Feature graphic**: 1024 x 500 px
- **App icon**: 512 x 512 px
- **Privacy policy URL**: Required
- **Content rating**: Complete questionnaire

## iOS Deployment

### Step 1: Configure Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" project
3. Update:
   - Display Name
   - Bundle Identifier
   - Version and Build number
   - Team and signing

### Step 2: Configure Signing

1. Select Runner target
2. Go to "Signing & Capabilities"
3. Check "Automatically manage signing"
4. Select your team
5. Verify provisioning profile

### Step 3: Build for Release

```bash
# Build iOS app
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release
```

Output: `build/ios/ipa/raffle_app.ipa`

### Step 4: Upload to App Store Connect

**Option 1: Xcode**
1. Open Xcode
2. Product → Archive
3. Window → Organizer
4. Select archive
5. Click "Distribute App"
6. Follow wizard

**Option 2: Transporter App**
1. Download Transporter from Mac App Store
2. Sign in with Apple ID
3. Drag and drop IPA file
4. Click "Deliver"

**Option 3: Command Line**
```bash
xcrun altool --upload-app -f build/ios/ipa/raffle_app.ipa \
  --type ios \
  -u "your-apple-id@email.com" \
  -p "@keychain:AC_PASSWORD"
```

### Step 5: Submit for Review

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Click "+" to create new version
4. Fill in:
   - What's New in This Version
   - Screenshots (all required sizes)
   - App description
   - Keywords
   - Support URL
   - Privacy Policy URL
5. Select the build
6. Submit for review

### App Store Listing Requirements

- **Screenshots**: Required sizes for all device types
  - iPhone 6.7": 1290 x 2796 px
  - iPhone 6.5": 1284 x 2778 px
  - iPhone 5.5": 1242 x 2208 px
  - iPad Pro 12.9": 2048 x 2732 px
- **App icon**: 1024 x 1024 px
- **Description**: Max 4000 characters
- **Keywords**: Max 100 characters
- **Privacy Policy**: URL required
- **App category**: Select appropriate category

## CI/CD Pipeline

### GitHub Actions

Workflows are configured in `.github/workflows/`:

**Test Workflow** (`test.yml`):
- Runs on every push and PR
- Executes unit and widget tests
- Reports coverage

**Build Workflow** (`build.yml`):
- Builds Android APK/AAB
- Builds iOS IPA
- Uploads artifacts

### Codemagic

Configuration in `codemagic.yaml`:

**Triggers:**
- Push to main/develop branches
- Manual trigger via Codemagic dashboard

**Android Workflow:**
```bash
# Set environment variables in Codemagic UI
FCI_KEYSTORE
FCI_KEYSTORE_PASSWORD
FCI_KEY_ALIAS
FCI_KEY_PASSWORD
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
```

**iOS Workflow:**
```bash
# Set environment variables
APP_STORE_CONNECT_KEY_IDENTIFIER
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_PRIVATE_KEY
CERTIFICATE_PRIVATE_KEY
```

### Automated Deployment

Enable automated deployment in `codemagic.yaml`:

```yaml
publishing:
  google_play:
    credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
    track: internal
  
  app_store_connect:
    api_key: $APP_STORE_CONNECT_PRIVATE_KEY
    key_id: $APP_STORE_CONNECT_KEY_IDENTIFIER
    issuer_id: $APP_STORE_CONNECT_ISSUER_ID
    submit_to_testflight: true
```

## App Store Submission

### Pre-Submission Checklist

- [ ] App tested on multiple devices
- [ ] All features working
- [ ] No crashes or critical bugs
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Screenshots prepared
- [ ] App description written
- [ ] Content rating completed
- [ ] Test account provided (if needed)
- [ ] Version number incremented
- [ ] Build number incremented

### Google Play Store

**Review Time**: 1-7 days typically

**Tracks:**
1. **Internal Testing**: Fast review, up to 100 testers
2. **Closed Testing**: Alpha/Beta tracks
3. **Open Testing**: Public beta
4. **Production**: Public release

**Rollout Options:**
- Staged rollout (10%, 25%, 50%, 100%)
- Immediate full rollout

### Apple App Store

**Review Time**: 24-48 hours typically

**Release Options:**
1. **TestFlight**: Beta testing (up to 10,000 testers)
2. **Manual Release**: Approved but you control release
3. **Automatic Release**: Released immediately after approval

**Common Rejection Reasons:**
- Incomplete app information
- Crashes or bugs
- Misleading screenshots
- Privacy policy issues
- Inappropriate content
- Duplicate app
- Incomplete functionality

### Post-Submission

1. **Monitor Reviews**
   - Respond to user reviews
   - Track ratings
   - Monitor crash reports

2. **Analytics**
   - Track downloads
   - Monitor user engagement
   - Analyze retention

3. **Updates**
   - Regular bug fixes
   - New features
   - Performance improvements

## Version Management

### Version Numbering

Follow semantic versioning: `MAJOR.MINOR.PATCH+BUILD`

Example: `1.0.0+1`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes
- **BUILD**: Build number (auto-incremented)

### Updating Version

In `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

### Git Tags

Tag releases for tracking:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Troubleshooting

### Android Issues

**Issue**: "Unable to find bundletool.jar"
```bash
flutter pub cache repair
```

**Issue**: "Execution failed for task ':app:lintVitalRelease'"
```gradle
// In android/app/build.gradle
lintOptions {
    checkReleaseBuilds false
}
```

**Issue**: Keystore not found
- Check path in `key.properties`
- Ensure keystore file exists
- Check file permissions

### iOS Issues

**Issue**: "No signing certificate"
1. Open Xcode
2. Preferences → Accounts
3. Download Manual Profiles

**Issue**: "Archive not valid for submission"
- Check bundle identifier
- Verify provisioning profile
- Ensure all architectures included

**Issue**: CocoaPods issues
```bash
cd ios
pod deintegrate
pod install
```

### Build Issues

**Issue**: OutOfMemory during build
```bash
# Increase memory in gradle.properties
org.gradle.jvmargs=-Xmx4096m
```

**Issue**: "Gradle daemon disappeared"
```bash
./gradlew --stop
./gradlew clean
flutter clean
flutter pub get
```

## Support

For deployment issues:
- Check [Flutter documentation](https://docs.flutter.dev/deployment)
- Review [Codemagic docs](https://docs.codemagic.io)
- Contact: dev@grategenyen.com

## Security Notes

**Never commit:**
- Keystore files
- key.properties
- Service account JSON
- API keys
- Passwords

Use environment variables and secure credential storage.
