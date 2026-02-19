import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

/// Service for logging errors with context
/// 
/// In production, this would integrate with services like Sentry or Firebase Crashlytics
/// For now, it provides structured logging that can be easily extended
class ErrorLoggingService {
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  /// Log an error with full context
  void logError(
    AppError error, {
    String? userId,
    String? screen,
    Map<String, dynamic>? additionalContext,
  }) {
    final context = {
      'type': error.type.toString(),
      'message': error.message,
      'code': error.code,
      'timestamp': DateTime.now().toIso8601String(),
      if (userId != null) 'userId': userId,
      if (screen != null) 'screen': screen,
      if (error.context != null) 'errorContext': error.context,
      if (additionalContext != null) 'additionalContext': additionalContext,
    };

    // In debug mode, print detailed error info
    if (kDebugMode) {
      debugPrint('=== ERROR LOGGED ===');
      debugPrint('Type: ${error.type}');
      debugPrint('Message: ${error.message}');
      debugPrint('User Message: ${error.displayMessage}');
      if (error.code != null) debugPrint('Code: ${error.code}');
      if (userId != null) debugPrint('User ID: $userId');
      if (screen != null) debugPrint('Screen: $screen');
      if (error.originalError != null) {
        debugPrint('Original Error: ${error.originalError}');
      }
      if (error.stackTrace != null) {
        debugPrint('Stack Trace:');
        debugPrint(error.stackTrace.toString());
      }
      debugPrint('Context: $context');
      debugPrint('==================');
    }

    // TODO: In production, send to error tracking service
    // Example integrations:
    // - Sentry: Sentry.captureException(error.originalError, stackTrace: error.stackTrace)
    // - Firebase Crashlytics: FirebaseCrashlytics.instance.recordError(error.originalError, error.stackTrace)
    
    _logToAnalytics(error, context);
  }

  /// Log a warning (non-fatal error)
  void logWarning(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      debugPrint('=== WARNING ===');
      debugPrint(message);
      if (context != null) debugPrint('Context: $context');
      debugPrint('===============');
    }

    // TODO: Send to analytics service
  }

  /// Log analytics event for error patterns
  void _logToAnalytics(AppError error, Map<String, dynamic> context) {
    // TODO: Integrate with Firebase Analytics or similar
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'app_error',
    //   parameters: {
    //     'error_type': error.type.toString(),
    //     'error_code': error.code ?? 'unknown',
    //     'is_retryable': error.isRetryable,
    //   },
    // );
  }

  /// Log user action on error
  void logErrorAction(ErrorRecoveryAction action, AppError error) {
    if (kDebugMode) {
      debugPrint('User action on error: $action for ${error.type}');
    }

    // TODO: Track user recovery actions in analytics
  }
}
