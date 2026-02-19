import 'package:flutter/material.dart';
import '../../models/app_error.dart';
import '../../services/error_logging_service.dart';

/// Full-screen error display widget
/// 
/// Shows a user-friendly error message with recovery actions
class ErrorScreen extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final VoidCallback? onContactSupport;

  const ErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
    this.onGoBack,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erè'),
        leading: onGoBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error icon
              Icon(
                _getErrorIcon(),
                size: 80,
                color: _getErrorColor(context),
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                _getErrorTitle(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error message
              Text(
                error.displayMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Recovery actions
              ..._buildRecoveryActions(context),
            ],
          ),
        ),
      ),
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

  Color _getErrorColor(BuildContext context) {
    if (error.isRetryable) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.error;
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
        return 'Yon erè fèt';
    }
  }

  List<Widget> _buildRecoveryActions(BuildContext context) {
    final actions = <Widget>[];
    final recoveryActions = error.recoveryActions;

    for (final action in recoveryActions) {
      final button = _buildActionButton(context, action);
      if (button != null) {
        actions.add(button);
        actions.add(const SizedBox(height: 12));
      }
    }

    return actions;
  }

  Widget? _buildActionButton(BuildContext context, ErrorRecoveryAction action) {
    VoidCallback? callback;
    String label;
    bool isPrimary = false;

    switch (action) {
      case ErrorRecoveryAction.retry:
        callback = onRetry;
        label = 'Eseye ankò';
        isPrimary = true;
        break;
      case ErrorRecoveryAction.goBack:
        callback = onGoBack ?? () => Navigator.of(context).pop();
        label = 'Retounen';
        break;
      case ErrorRecoveryAction.login:
        callback = () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        };
        label = 'Konekte';
        isPrimary = true;
        break;
      case ErrorRecoveryAction.contactSupport:
        callback = onContactSupport;
        label = 'Kontakte sipò';
        break;
      case ErrorRecoveryAction.checkConnection:
        callback = onRetry;
        label = 'Verifye koneksyon';
        break;
      case ErrorRecoveryAction.clearCache:
      case ErrorRecoveryAction.refresh:
        return null; // Not implemented for full screen errors
    }

    if (callback == null) return null;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: () {
          ErrorLoggingService().logErrorAction(action, error);
          callback();
        },
        icon: const Icon(Icons.refresh),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: () {
          ErrorLoggingService().logErrorAction(action, error);
          callback();
        },
        child: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }
  }
}
