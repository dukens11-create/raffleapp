import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/connectivity_service.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/utils/sync_queue.dart';
import 'package:raffle_app/models/sync_task.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final SyncQueue _syncQueue = SyncQueue();

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  int _syncedCount = 0;
  int _failedCount = 0;

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncedCount => _syncedCount;
  int get failedCount => _failedCount;

  // Check if sync is needed
  Future<bool> needsSync() async {
    return await _cacheService.needsSync('global', 15); // 15 minutes
  }

  // Perform full sync
  Future<bool> performSync() async {
    if (_status == SyncStatus.syncing) {
      debugPrint('Sync already in progress');
      return false;
    }

    if (!_connectivityService.isOnline) {
      debugPrint('Cannot sync: offline');
      return false;
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    _syncedCount = 0;
    _failedCount = 0;

    try {
      // Get pending tasks
      final tasks = await _syncQueue.getTasksByPriority();
      
      if (tasks.isEmpty) {
        debugPrint('No pending tasks to sync');
        _status = SyncStatus.completed;
        _lastSyncTime = DateTime.now();
        await _cacheService.updateLastSyncTime('global');
        return true;
      }

      debugPrint('Starting sync of ${tasks.length} tasks');

      // Process each task
      for (var task in tasks) {
        try {
          await _processSyncTask(task);
          _syncedCount++;
          
          // Remove from queue on success
          if (task.id != null) {
            await _syncQueue.removeTask(task.id!);
          }
        } catch (e) {
          debugPrint('Failed to sync task ${task.id}: $e');
          _failedCount++;
          
          // Increment retry count
          if (_syncQueue.shouldRetry(task)) {
            await _syncQueue.incrementRetryCount(task);
          } else {
            // Remove task if max retries exceeded
            if (task.id != null) {
              await _syncQueue.removeTask(task.id!);
            }
          }
        }
      }

      _status = SyncStatus.completed;
      _lastSyncTime = DateTime.now();
      await _cacheService.updateLastSyncTime('global');
      
      debugPrint('Sync completed: $_syncedCount synced, $_failedCount failed');
      return true;
    } catch (e) {
      _status = SyncStatus.failed;
      _lastError = e.toString();
      debugPrint('Sync failed: $e');
      return false;
    }
  }

  // Process individual sync task
  Future<void> _processSyncTask(SyncTask task) async {
    debugPrint('Processing sync task: ${task.entityType.name} ${task.action.name}');
    
    // TODO: Implement actual sync logic based on entity type and action
    // This will be implemented in specific sync services (ticket_sync, payment_sync, etc.)
    
    switch (task.entityType) {
      case SyncEntityType.ticket:
        await _syncTicket(task);
        break;
      case SyncEntityType.payment:
        await _syncPayment(task);
        break;
      case SyncEntityType.user:
        await _syncUser(task);
        break;
      case SyncEntityType.notification:
        await _syncNotification(task);
        break;
    }
  }

  Future<void> _syncTicket(SyncTask task) async {
    // Placeholder for ticket sync
    // Will be implemented in ticket_sync.dart
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _syncPayment(SyncTask task) async {
    // Placeholder for payment sync
    // Will be implemented in payment_sync.dart
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _syncUser(SyncTask task) async {
    // Placeholder for user sync
    // Will be implemented in user_sync.dart
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _syncNotification(SyncTask task) async {
    // Placeholder for notification sync
    // Will be implemented in notification_sync.dart
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Trigger sync if needed
  Future<void> syncIfNeeded() async {
    if (await needsSync()) {
      await performSync();
    }
  }

  // Force sync
  Future<void> forceSync() async {
    await performSync();
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'status': _status.name,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'synced_count': _syncedCount,
      'failed_count': _failedCount,
      'last_error': _lastError,
    };
  }

  // Reset sync statistics
  void resetStats() {
    _syncedCount = 0;
    _failedCount = 0;
    _lastError = null;
  }
}
