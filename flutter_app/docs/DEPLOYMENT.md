# Deployment Guide

## Overview

This guide covers deploying the Grate Genyen app to production environments.

## Prerequisites

### Android
- Google Play Console account ($25 one-time)
- Android signing keystore
- Google Play Service Account JSON key

### iOS
- Apple Developer account ($99/year)
- App Store Connect access
- Xcode installed (macOS only)
- Valid provisioning profiles

## Environment Setup

### 1. Install Flutter
```bash
# Install Flutter SDK
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### 2. Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### 3. Configure Environment Variables
Create `.env` file:
```
API_BASE_URL=https://api.grategenyen.com
MONCASH_CLIENT_ID=your_client_id
NATCASH_API_KEY=your_api_key
```

## Android Deployment

### Step 1: Generate Signing Key
```bash
keytool -genkey -v -keystore ~/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Configure Build
Create `android/key.properties`:
```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

### Step 3: Build Release
```bash
flutter build appbundle --release
```

### Step 4: Upload to Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Navigate to Release → Production
4. Upload AAB file: `build/app/outputs/bundle/release/app-release.aab`
5. Fill in release notes
6. Submit for review

### Using Fastlane
```bash
cd fastlane
bundle exec fastlane deploy_production
```

## iOS Deployment

### Step 1: Configure Xcode
```bash
cd ios
pod install
open Runner.xcworkspace
```

### Step 2: Set Bundle Identifier
In Xcode:
- Select Runner target
- Set Bundle Identifier: `com.grategenyen.raffleapp`

### Step 3: Configure Signing
- Select your Team
- Enable "Automatically manage signing"

### Step 4: Build Archive
```bash
flutter build ios --release
```

### Step 5: Upload to App Store Connect
```bash
cd fastlane
bundle exec fastlane beta  # For TestFlight
bundle exec fastlane release  # For App Store
```

## CI/CD Deployment

### GitHub Actions
Automatic deployment on tag push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers:
- Android build and upload to Play Store
- iOS build and upload to TestFlight

### Manual Deployment
```bash
# Trigger manual deployment
gh workflow run android_release.yml -f track=production
gh workflow run ios_release.yml -f environment=appstore
```

## Version Management

### Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # version+build_number
```

### Generate Changelog
```bash
git log --oneline v1.0.0..HEAD > CHANGELOG.txt
```

## Environment-Specific Builds

### Development
```bash
flutter build apk --debug --flavor dev
```

### Staging
```bash
flutter build apk --release --flavor staging
```

### Production
```bash
flutter build apk --release --flavor production
```

## Post-Deployment

### 1. Monitor Crashes
- Check Firebase Crashlytics
- Monitor Google Play Console vitals
- Review App Store Connect crash reports

### 2. Monitor Analytics
- Review Firebase Analytics
- Check user engagement metrics
- Monitor conversion rates

### 3. Gradual Rollout
- Start with 10% of users
- Monitor for issues
- Increase to 50%, then 100%

## Rollback Procedure

### Android
1. Go to Play Console
2. Navigate to Release → Production
3. Click "Create new release"
4. Upload previous AAB version
5. Submit

### iOS
1. Go to App Store Connect
2. Select previous version
3. Submit for review

## Common Issues

### Issue: Build fails with signing errors
**Solution**: Verify keystore path and passwords

### Issue: App rejected by store
**Solution**: Review rejection reason and update accordingly

### Issue: Gradle build fails
**Solution**: Clean build and update dependencies
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk
```

## Security Checklist

- [ ] Remove debug logs
- [ ] Enable code obfuscation
- [ ] Validate SSL certificates
- [ ] Secure API keys
- [ ] Enable ProGuard (Android)
- [ ] Test security vulnerabilities

## Performance Checklist

- [ ] Enable R8 optimization (Android)
- [ ] Optimize images
- [ ] Minimize bundle size
- [ ] Test on low-end devices
- [ ] Profile app performance

## Store Listing Checklist

- [ ] App title and description
- [ ] Screenshots (all sizes)
- [ ] Feature graphic
- [ ] Privacy policy URL
- [ ] Content rating
- [ ] App category
- [ ] Contact information
