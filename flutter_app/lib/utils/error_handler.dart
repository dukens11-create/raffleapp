import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'crash_reporter.dart';
import 'analytics_service.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final CrashReporter _crashReporter = CrashReporter();
  final AnalyticsService _analytics = AnalyticsService();

  /// Initialize error handler
  Future<void> initialize() async {
    await _crashReporter.initialize();
    if (kDebugMode) {
      debugPrint('✅ Error handler initialized');
    }
  }

  /// Handle a general error
  void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (kDebugMode) {
      debugPrint('🔥 Error in $context: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Log to crash reporter
    _crashReporter.recordError(error, stackTrace, reason: context);

    // Log to analytics
    _analytics.logError(
      errorType: error.runtimeType.toString(),
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Handle a network error
  void handleNetworkError({
    required String endpoint,
    required int statusCode,
    String? errorMessage,
  }) {
    if (kDebugMode) {
      debugPrint('🌐 Network error: $statusCode at $endpoint');
      if (errorMessage != null) {
        debugPrint('Message: $errorMessage');
      }
    }

    _crashReporter.recordNetworkError(
      endpoint: endpoint,
      statusCode: statusCode,
      errorMessage: errorMessage,
    );

    _analytics.logEvent(
      name: 'network_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Handle an authentication error
  void handleAuthError(String errorType, String message) {
    if (kDebugMode) {
      debugPrint('🔐 Auth error: $errorType - $message');
    }

    _crashReporter.recordAuthError(errorType, message);

    _analytics.logEvent(
      name: 'auth_error',
      parameters: {
        'error_type': errorType,
        'message': message,
      },
    );
  }

  /// Handle a payment error
  void handlePaymentError({
    required String paymentMethod,
    required String errorCode,
    String? errorMessage,
  }) {
    if (kDebugMode) {
      debugPrint('💳 Payment error: $errorCode via $paymentMethod');
      if (errorMessage != null) {
        debugPrint('Message: $errorMessage');
      }
    }

    _crashReporter.recordPaymentError(
      paymentMethod: paymentMethod,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );

    _analytics.logEvent(
      name: 'payment_error',
      parameters: {
        'payment_method': paymentMethod,
        'error_code': errorCode,
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Show error dialog to user
  void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar to user
  void showErrorSnackbar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error is AuthenticationException) {
      return 'Authentication failed. Please login again.';
    } else if (error is ValidationException) {
      return error.message ?? 'Invalid input. Please check your data.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Custom exception classes
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException([this.message = 'Authentication failed']);

  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  final String? message;
  final Map<String, String>? errors;

  ValidationException([this.message, this.errors]);

  @override
  String toString() => 'ValidationException: $message';
}

class PaymentException implements Exception {
  final String message;
  final String errorCode;

  PaymentException(this.message, {required this.errorCode});

  @override
  String toString() => 'PaymentException: $message (Code: $errorCode)';
}
