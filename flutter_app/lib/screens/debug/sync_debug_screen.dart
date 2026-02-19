import 'package:flutter/material.dart';
import 'package:raffle_app/utils/sync_manager.dart';
import 'package:raffle_app/utils/sync_logger.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/services/connectivity_service.dart';
import 'package:raffle_app/services/background_sync_service.dart';
import 'package:intl/intl.dart';

class SyncDebugScreen extends StatefulWidget {
  const SyncDebugScreen({super.key});

  @override
  State<SyncDebugScreen> createState() => _SyncDebugScreenState();
}

class _SyncDebugScreenState extends State<SyncDebugScreen> {
  final SyncManager _syncManager = SyncManager();
  final SyncLogger _syncLogger = SyncLogger();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final BackgroundSyncService _backgroundSyncService = BackgroundSyncService();

  bool _isSyncing = false;
  Map<String, dynamic>? _cacheStats;
  Map<String, int>? _logStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _cacheService.getCacheStats();
    final logStats = _syncLogger.getStatistics();
    
    setState(() {
      _cacheStats = stats;
      _logStats = logStats;
    });
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _backgroundSyncService.triggerManualSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
      await _loadStats();
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all cached data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cacheService.clearAllCache();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    }
  }

  Future<void> _viewLogs() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SyncLogsScreen(logger: _syncLogger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Status
          _buildSectionHeader('Connection Status'),
          Card(
            child: ListTile(
              leading: Icon(
                _connectivityService.isOnline
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: _connectivityService.isOnline
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(
                _connectivityService.isOnline ? 'Online' : 'Offline',
              ),
              subtitle: Text(
                'Connection: ${_connectivityService.currentType.name}',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sync Status
          _buildSectionHeader('Sync Status'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Last Sync'),
                  subtitle: Text(
                    _syncManager.lastSyncTime != null
                        ? DateFormat('MMM d, yyyy HH:mm:ss')
                            .format(_syncManager.lastSyncTime!)
                        : 'Never synced',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Synced Count'),
                  subtitle: Text('${_syncManager.syncedCount} items'),
                ),
                ListTile(
                  leading: const Icon(Icons.error),
                  title: const Text('Failed Count'),
                  subtitle: Text('${_syncManager.failedCount} items'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cache Statistics
          _buildSectionHeader('Cache Statistics'),
          Card(
            child: Column(
              children: [
                _buildStatTile('Tickets', _cacheStats?['tickets_count'] ?? 0),
                _buildStatTile('Payments', _cacheStats?['payments_count'] ?? 0),
                _buildStatTile('Raffles', _cacheStats?['raffles_count'] ?? 0),
                _buildStatTile(
                    'Notifications', _cacheStats?['notifications_count'] ?? 0),
                _buildStatTile(
                    'Pending Sync', _cacheStats?['pending_sync_count'] ?? 0),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Log Statistics
          _buildSectionHeader('Log Statistics'),
          Card(
            child: Column(
              children: [
                _buildStatTile('Total Logs', _logStats?['total'] ?? 0),
                _buildStatTile('Errors', _logStats?['error'] ?? 0,
                    textColor: Colors.red),
                _buildStatTile('Warnings', _logStats?['warning'] ?? 0,
                    textColor: Colors.orange),
                _buildStatTile('Info', _logStats?['info'] ?? 0),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _triggerManualSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Syncing...' : 'Trigger Manual Sync'),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _viewLogs,
            icon: const Icon(Icons.list),
            label: const Text('View Sync Logs'),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _clearCache,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear Cache'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, int value, {Color? textColor}) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _SyncLogsScreen extends StatelessWidget {
  final SyncLogger logger;

  const _SyncLogsScreen({required this.logger});

  @override
  Widget build(BuildContext context) {
    final logs = logger.getLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              logger.clearLogs();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No logs available'))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[logs.length - 1 - index]; // Reverse order
                return ListTile(
                  leading: _getLogIcon(log.level),
                  title: Text(log.message),
                  subtitle: Text(
                    '${DateFormat('HH:mm:ss').format(log.timestamp)} ${log.operation ?? ""}',
                  ),
                );
              },
            ),
    );
  }

  Icon _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Icon(Icons.error, color: Colors.red);
      case LogLevel.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case LogLevel.info:
        return const Icon(Icons.info, color: Colors.blue);
      case LogLevel.debug:
        return const Icon(Icons.bug_report, color: Colors.grey);
    }
  }
}
