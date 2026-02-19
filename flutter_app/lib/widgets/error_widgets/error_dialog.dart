import 'package:flutter/material.dart';
import '../../models/app_error.dart';
import '../../services/error_logging_service.dart';

/// Error dialog widget
/// 
/// Shows an error message in a dialog with recovery actions
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
  });

  /// Show error dialog
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !error.isRetryable,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        _getErrorIcon(),
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(_getErrorTitle()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error.displayMessage,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: _buildActions(context),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.authorization:
        return Icons.block;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.serverError:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'Pa gen koneksyon';
      case ErrorType.timeout:
        return 'Tan limite depase';
      case ErrorType.serverError:
        return 'Pwoblèm sèvè';
      case ErrorType.authentication:
        return 'Sesyon ekspire';
      case ErrorType.authorization:
        return 'Aksè refize';
      case ErrorType.notFound:
        return 'Pa jwenn';
      case ErrorType.validation:
        return 'Enfòmasyon pa valid';
      case ErrorType.businessLogic:
        return 'Operasyon pa posib';
      default:
        return 'Erè';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    
    // Add retry button if retryable
    if (error.isRetryable && onRetry != null) {
      actions.add(
        TextButton(
          onPressed: () {
            ErrorLoggingService().logErrorAction(ErrorRecoveryAction.retry, error);
            Navigator.of(context).pop();
            onRetry!();
          },
          child: const Text('Eseye ankò'),
        ),
      );
    }

    // Add appropriate action based on error type
    if (error.type == ErrorType.authentication) {
      actions.add(
        FilledButton(
          onPressed: () {
            ErrorLoggingService().logErrorAction(ErrorRecoveryAction.login, error);
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: const Text('Konekte'),
        ),
      );
    } else {
      actions.add(
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      );
    }

    return actions;
  }
}
