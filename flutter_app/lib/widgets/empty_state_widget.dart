import 'package:flutter/material.dart';

/// Empty state widget for when there's no data to display
/// 
/// Shows an icon, message, and optional action button
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Empty tickets state
  static Widget noTickets({VoidCallback? onBrowseTickets}) {
    return EmptyStateWidget(
      icon: Icons.confirmation_number_outlined,
      title: 'Pa gen tikè',
      message: 'Ou poko achte tikè. Kòmanse eksplore tikè ki disponib yo!',
      actionLabel: 'Wè Tikè yo',
      onAction: onBrowseTickets,
    );
  }

  /// Empty search results
  static Widget noResults({String? searchQuery}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Pa gen rezilta',
      message: searchQuery != null
          ? 'Nou pa jwenn rezilta pou "$searchQuery"'
          : 'Nou pa jwenn rezilta pou rechèch ou a',
    );
  }

  /// No transactions
  static Widget noTransactions() {
    return const EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'Pa gen tranzaksyon',
      message: 'Ou poko fè okenn tranzaksyon',
    );
  }

  /// No notifications
  static Widget noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'Pa gen notifikasyon',
      message: 'Ou pa gen okenn notifikasyon nouvo',
    );
  }

  /// Network error state
  static Widget networkError({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'Pa gen koneksyon',
      message: 'Verifye koneksyon entènèt ou epi eseye ankò',
      actionLabel: 'Eseye Ankò',
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }

  /// Generic error state
  static Widget error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Yon erè fèt',
      message: message,
      actionLabel: onRetry != null ? 'Eseye Ankò' : null,
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}
