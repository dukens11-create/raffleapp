import 'package:flutter/material.dart';
import '../../models/app_error.dart';
import '../../services/error_logging_service.dart';

/// Error snackbar widget
/// 
/// Shows a brief error message at the bottom of the screen
class ErrorSnackbar {
  /// Show error snackbar
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    messenger.clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(error),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.displayMessage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(context, error),
      duration: duration ?? _getDefaultDuration(error),
      action: _buildAction(context, error, onRetry),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  static IconData _getErrorIcon(AppError error) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.serverError:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  static Color _getBackgroundColor(BuildContext context, AppError error) {
    if (error.isRetryable) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.error;
  }

  static Duration _getDefaultDuration(AppError error) {
    // Longer duration for retryable errors
    if (error.isRetryable) {
      return const Duration(seconds: 6);
    }
    return const Duration(seconds: 4);
  }

  static SnackBarAction? _buildAction(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    if (error.isRetryable && onRetry != null) {
      return SnackBarAction(
        label: 'ESEYE',
        textColor: Colors.white,
        onPressed: () {
          ErrorLoggingService().logErrorAction(ErrorRecoveryAction.retry, error);
          onRetry();
        },
      );
    }

    if (error.type == ErrorType.authentication) {
      return SnackBarAction(
        label: 'KONEKTE',
        textColor: Colors.white,
        onPressed: () {
          ErrorLoggingService().logErrorAction(ErrorRecoveryAction.login, error);
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      );
    }

    return null;
  }

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green[700],
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    messenger.showSnackBar(snackBar);
  }
}
