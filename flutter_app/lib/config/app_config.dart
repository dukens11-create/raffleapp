/// App Configuration
/// 
/// Central configuration file for app-wide settings and constants.

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
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Cache settings
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
}
