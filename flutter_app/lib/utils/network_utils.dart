import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class NetworkUtils {
  // Exponential backoff configuration
  static const int _maxRetries = 3;
  static const int _initialDelayMs = 1000;
  static const int _maxDelayMs = 10000;

  // Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.error is SocketException;
    }
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException;
  }

  // Check if error is a server error (5xx)
  static bool isServerError(dynamic error) {
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      return statusCode >= 500 && statusCode < 600;
    }
    return false;
  }

  // Check if error is a client error (4xx)
  static bool isClientError(dynamic error) {
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      return statusCode >= 400 && statusCode < 500;
    }
    return false;
  }

  // Check if error should trigger a retry
  static bool shouldRetry(dynamic error, int attemptNumber) {
    if (attemptNumber >= _maxRetries) return false;

    // Retry on network errors and server errors (5xx)
    return isNetworkError(error) || isServerError(error);
  }

  // Calculate delay for exponential backoff
  static Duration calculateBackoffDelay(int attemptNumber) {
    final delayMs = _initialDelayMs * (1 << attemptNumber); // 2^attemptNumber
    final cappedDelayMs = delayMs > _maxDelayMs ? _maxDelayMs : delayMs;
    return Duration(milliseconds: cappedDelayMs);
  }

  // Execute request with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() request, {
    int maxRetries = _maxRetries,
    bool Function(dynamic error)? shouldRetryCallback,
  }) async {
    int attemptNumber = 0;

    while (true) {
      try {
        return await request();
      } catch (error) {
        attemptNumber++;

        // Check if should retry
        final shouldRetryError = shouldRetryCallback != null
            ? shouldRetryCallback(error)
            : shouldRetry(error, attemptNumber);

        if (!shouldRetryError || attemptNumber >= maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        final delay = calculateBackoffDelay(attemptNumber);
        await Future.delayed(delay);
      }
    }
  }

  // Get user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.sendTimeout:
          return 'Send timeout. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Receive timeout. The server is taking too long to respond.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Unauthorized. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied.';
          } else if (statusCode == 404) {
            return 'Resource not found.';
          } else if (statusCode == 409) {
            return 'Data conflict. Please refresh and try again.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }
          return 'Request failed with status: $statusCode';
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        default:
          return 'Network error. Please try again.';
      }
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is TimeoutException) {
      return 'Request timeout. Please try again.';
    }

    return 'An error occurred. Please try again.';
  }

  // Check internet connectivity by pinging a reliable server
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Format bytes to human-readable size
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // Get connection quality based on type
  static String getConnectionQuality(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return 'Good';
      case 'mobile':
        return 'Fair';
      case 'ethernet':
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
}
