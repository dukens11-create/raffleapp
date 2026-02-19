import 'package:flutter/foundation.dart';
import 'dart:async';

/// Crash reporter service for logging and reporting app crashes
class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  factory CrashReporter() => _instance;
  CrashReporter._internal();

  bool _isInitialized = false;

  /// Initialize crash reporter
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Firebase Crashlytics
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
    };

    // Catch errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack);
      return true;
    };

    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('✅ Crash reporter initialized');
    }
  }

  /// Record a Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      debugPrint('🔥 Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }

    // Send to Crashlytics
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  /// Record a general error
  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('🔥 Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      if (reason != null) {
        debugPrint('Reason: $reason');
      }
    }

    // Send to Crashlytics
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: reason,
    //   fatal: fatal,
    // );
  }

  /// Log a message
  void log(String message) {
    if (kDebugMode) {
      debugPrint('📝 Log: $message');
    }

    // FirebaseCrashlytics.instance.log(message);
  }

  /// Set user identifier
  Future<void> setUserIdentifier(String userId) async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      debugPrint('👤 Setting user identifier: $userId');
    }

    // await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Set custom key-value pairs
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      debugPrint('🔑 Setting custom key: $key = $value');
    }

    // await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Record an exception with context
  Future<void> recordException({
    required dynamic exception,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      debugPrint('🔥 Exception in $context: $exception');
      if (data != null) {
        debugPrint('Additional data: $data');
      }
    }

    // Set context as custom key
    if (context != null) {
      await setCustomKey('context', context);
    }

    // Set additional data
    if (data != null) {
      for (var entry in data.entries) {
        await setCustomKey(entry.key, entry.value);
      }
    }

    // Record the exception
    // await FirebaseCrashlytics.instance.recordError(
    //   exception,
    //   stackTrace,
    //   reason: context,
    // );
  }

  /// Record a network error
  Future<void> recordNetworkError({
    required String endpoint,
    required int statusCode,
    String? errorMessage,
  }) async {
    await recordException(
      exception: 'Network Error: $statusCode',
      context: 'API Request',
      data: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Record an auth error
  Future<void> recordAuthError(String errorType, String message) async {
    await recordException(
      exception: 'Authentication Error',
      context: 'Auth',
      data: {
        'error_type': errorType,
        'message': message,
      },
    );
  }

  /// Record a payment error
  Future<void> recordPaymentError({
    required String paymentMethod,
    required String errorCode,
    String? errorMessage,
  }) async {
    await recordException(
      exception: 'Payment Error',
      context: 'Payment',
      data: {
        'payment_method': paymentMethod,
        'error_code': errorCode,
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Test crash (for debugging only)
  void forceCrash() {
    if (kDebugMode) {
      debugPrint('💥 Force crash triggered');
    }
    // FirebaseCrashlytics.instance.crash();
  }

  /// Check if crash reporter is enabled
  bool get isEnabled => _isInitialized;
}

/// Zone guard for running app with error handling
Future<void> runAppWithCrashReporting(Future<void> Function() app) async {
  await CrashReporter().initialize();

  await runZonedGuarded(
    () async {
      await app();
    },
    (error, stackTrace) {
      CrashReporter().recordError(error, stackTrace, fatal: true);
    },
  );
}
