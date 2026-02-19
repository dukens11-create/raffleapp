import 'package:flutter/foundation.dart';
import '../models/app_error.dart';
import '../services/error_logging_service.dart';

/// Global error handler for the application
/// 
/// Provides centralized error handling, logging, and user-friendly error messages
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final _errorLoggingService = ErrorLoggingService();

  /// Handle and convert any error to AppError
  AppError handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userId,
    String? screen,
  }) {
    AppError appError;

    if (error is AppError) {
      appError = error;
    } else {
      appError = _convertToAppError(error, stackTrace);
    }

    // Log the error
    _errorLoggingService.logError(
      appError,
      userId: userId,
      screen: screen,
    );

    return appError;
  }

  /// Convert various error types to AppError
  AppError _convertToAppError(dynamic error, StackTrace? stackTrace) {
    final errorString = error.toString();

    // Network errors
    if (errorString.contains('SocketException') ||
        errorString.contains('NetworkException') ||
        errorString.contains('Failed host lookup')) {
      return AppError.network(
        'Network connection failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Timeout errors
    if (errorString.contains('TimeoutException') ||
        errorString.contains('timed out')) {
      return AppError.timeout('Request timed out');
    }

    // HTTP errors (if error message contains status code)
    final statusCodeMatch = RegExp(r'status code (\d{3})').firstMatch(errorString);
    if (statusCodeMatch != null) {
      final statusCode = int.parse(statusCodeMatch.group(1)!);
      return AppError.fromHttpStatus(statusCode, errorString, error: error);
    }

    // Format errors (parsing JSON, etc.)
    if (errorString.contains('FormatException') ||
        errorString.contains('JSON')) {
      return AppError.system(
        'Data format error',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Default to unknown error
    return AppError.unknown(
      errorString,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Handle errors from async operations
  Future<T?> handleAsyncError<T>(
    Future<T> Function() operation, {
    String? userId,
    String? screen,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        userId: userId,
        screen: screen,
      );
      return defaultValue;
    }
  }

  /// Setup global error handlers
  static void setupGlobalErrorHandling() {
    // Catch all uncaught Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      
      final handler = ErrorHandler();
      handler.handleError(
        details.exception,
        stackTrace: details.stack,
      );
    };

    // Catch all uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final handler = ErrorHandler();
      handler.handleError(error, stackTrace: stack);
      return true;
    };
  }
}
