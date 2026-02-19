/// Environment configuration for different deployment environments
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  static Environment _currentEnvironment = Environment.development;

  /// Set the current environment
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Get the current environment
  static Environment get currentEnvironment => _currentEnvironment;

  /// Check if running in development
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  /// Check if running in staging
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Check if running in production
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Get API base URL based on environment
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://localhost:3000';
      case Environment.staging:
        return 'https://staging-api.grategenyen.com';
      case Environment.production:
        return 'https://api.grategenyen.com';
    }
  }

  /// Get MonCash credentials based on environment
  static Map<String, String> get monCashConfig {
    switch (_currentEnvironment) {
      case Environment.development:
        return {
          'clientId': 'DEV_CLIENT_ID',
          'clientSecret': 'DEV_CLIENT_SECRET',
          'endpoint': 'https://sandbox.moncashbutton.digicelgroup.com',
        };
      case Environment.staging:
        return {
          'clientId': 'STAGING_CLIENT_ID',
          'clientSecret': 'STAGING_CLIENT_SECRET',
          'endpoint': 'https://sandbox.moncashbutton.digicelgroup.com',
        };
      case Environment.production:
        return {
          'clientId': 'PROD_CLIENT_ID',
          'clientSecret': 'PROD_CLIENT_SECRET',
          'endpoint': 'https://moncashbutton.digicelgroup.com',
        };
    }
  }

  /// Get NatCash credentials based on environment
  static Map<String, String> get natCashConfig {
    switch (_currentEnvironment) {
      case Environment.development:
        return {
          'apiKey': 'DEV_API_KEY',
          'endpoint': 'https://sandbox-api.natcash.ht',
        };
      case Environment.staging:
        return {
          'apiKey': 'STAGING_API_KEY',
          'endpoint': 'https://sandbox-api.natcash.ht',
        };
      case Environment.production:
        return {
          'apiKey': 'PROD_API_KEY',
          'endpoint': 'https://api.natcash.ht',
        };
    }
  }

  /// Enable/disable analytics based on environment
  static bool get enableAnalytics {
    return _currentEnvironment == Environment.production;
  }

  /// Enable/disable crashlytics based on environment
  static bool get enableCrashlytics {
    return _currentEnvironment != Environment.development;
  }

  /// Enable/disable debug logging
  static bool get enableDebugLogging {
    return _currentEnvironment == Environment.development;
  }

  /// Logging level
  static String get loggingLevel {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'DEBUG';
      case Environment.staging:
        return 'INFO';
      case Environment.production:
        return 'ERROR';
    }
  }

  /// Get Firebase configuration
  static Map<String, String> get firebaseConfig {
    switch (_currentEnvironment) {
      case Environment.development:
        return {
          'projectId': 'grate-genyen-dev',
          'appId': 'DEV_APP_ID',
        };
      case Environment.staging:
        return {
          'projectId': 'grate-genyen-staging',
          'appId': 'STAGING_APP_ID',
        };
      case Environment.production:
        return {
          'projectId': 'grate-genyen-prod',
          'appId': 'PROD_APP_ID',
        };
    }
  }

  /// Get timeout durations
  static Duration get connectionTimeout {
    return _currentEnvironment == Environment.development
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
  }

  /// Get cache expiry duration
  static Duration get cacheExpiry {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(hours: 1);
      case Environment.production:
        return const Duration(hours: 24);
    }
  }

  /// Feature flags
  static bool get enableBetaFeatures {
    return _currentEnvironment != Environment.production;
  }

  static bool get enablePerformanceMonitoring {
    return _currentEnvironment != Environment.development;
  }

  static bool get enableOfflineMode => true;

  static bool get enablePushNotifications => true;
}
