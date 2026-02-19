import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/offline_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (!offlineProvider.isOffline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade700,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (offlineProvider.hasPendingSync)
                        Text(
                          '${offlineProvider.pendingSyncCount} items waiting to sync',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (offlineProvider.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SyncStatusIndicator extends StatelessWidget {
  final bool showLabel;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        IconData icon;
        Color color;
        String label;

        if (offlineProvider.isSyncing) {
          icon = Icons.sync;
          color = Colors.blue;
          label = 'Syncing...';
        } else if (offlineProvider.hasPendingSync) {
          icon = Icons.cloud_upload;
          color = Colors.orange;
          label = 'Pending sync';
        } else if (offlineProvider.isOffline) {
          icon = Icons.cloud_off;
          color = Colors.grey;
          label = 'Offline';
        } else {
          icon = Icons.cloud_done;
          color = Colors.green;
          label = 'Synced';
        }

        if (!showLabel) {
          return Icon(icon, color: color, size: 24);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class LastSyncInfo extends StatelessWidget {
  const LastSyncInfo({super.key});

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never synced';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        return Text(
          'Last sync: ${_formatLastSync(offlineProvider.lastSyncTime)}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        );
      },
    );
  }
}
