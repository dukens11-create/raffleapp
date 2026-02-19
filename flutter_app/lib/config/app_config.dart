# App Configuration

## Overview

Central configuration file for app-wide settings and constants.

## Usage

```dart
import 'package:raffle_app/config/app_config.dart';

// Access configuration values
final appName = AppConfig.appName;
final version = AppConfig.version;
```

## Configuration Values

### App Information
```dart
class AppConfig {
  // App identity
  static const String appName = 'Grate Genyen';
  static const String appNameCreole = 'Grate Genyen';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // Package identifiers
  static const String androidPackageName = 'com.grategenyen.raffleapp';
  static const String iOSBundleId = 'com.grategenyen.raffleapp';
  
  // App Store URLs
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.grategenyen.raffleapp';
  static const String appStoreUrl = 'https://apps.apple.com/app/grate-genyen/id[APP_ID]';
  
  // Support and contact
  static const String supportEmail = 'support@grategenyen.com';
  static const String privacyPolicyUrl = 'https://grategenyen.com/privacy';
  static const String termsOfServiceUrl = 'https://grategenyen.com/terms';
}
```

This file should import EnvConfig and OptimizationConfig for complete app configuration.
