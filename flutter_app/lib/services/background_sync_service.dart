import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:raffle_app/utils/sync_manager.dart';
import 'package:raffle_app/services/connectivity_service.dart';

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');
    
    try {
      // Check connectivity
      final connectivityService = ConnectivityService();
      await connectivityService.initialize();
      
      if (!connectivityService.isOnline) {
        debugPrint('Device is offline, skipping background sync');
        return Future.value(true);
      }

      // Perform sync
      final syncManager = SyncManager();
      final success = await syncManager.performSync();
      
      debugPrint('Background sync completed: $success');
      return Future.value(success);
    } catch (e) {
      debugPrint('Background sync error: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const String _periodicTaskName = 'periodic_sync_task';
  static const String _immediateTaskName = 'immediate_sync_task';

  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('Background sync service initialized');
    } catch (e) {
      debugPrint('Error initializing background sync: $e');
    }
  }

  // Register periodic sync (every 15 minutes)
  Future<void> registerPeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        _periodicTaskName,
        _periodicTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      debugPrint('Periodic sync registered (every 15 minutes)');
    } catch (e) {
      debugPrint('Error registering periodic sync: $e');
    }
  }

  // Schedule immediate sync
  Future<void> scheduleImmediateSync() async {
    try {
      await Workmanager().registerOneOffTask(
        _immediateTaskName,
        _immediateTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      debugPrint('Immediate sync scheduled');
    } catch (e) {
      debugPrint('Error scheduling immediate sync: $e');
    }
  }

  // Cancel periodic sync
  Future<void> cancelPeriodicSync() async {
    try {
      await Workmanager().cancelByUniqueName(_periodicTaskName);
      debugPrint('Periodic sync cancelled');
    } catch (e) {
      debugPrint('Error cancelling periodic sync: $e');
    }
  }

  // Cancel all background tasks
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling all tasks: $e');
    }
  }

  // Trigger manual sync
  Future<bool> triggerManualSync() async {
    try {
      debugPrint('Triggering manual sync...');
      
      // Check connectivity first
      final connectivityService = ConnectivityService();
      await connectivityService.initialize();
      
      if (!connectivityService.isOnline) {
        debugPrint('Device is offline, cannot sync');
        return false;
      }

      // Perform sync
      final syncManager = SyncManager();
      final success = await syncManager.performSync();
      
      return success;
    } catch (e) {
      debugPrint('Manual sync error: $e');
      return false;
    }
  }
}
