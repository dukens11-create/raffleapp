import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/connectivity_service.dart';
import 'package:raffle_app/services/cache_service.dart';

class OfflineProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();

  bool _isOffline = false;
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  DateTime? _lastSyncTime;
  String? _syncError;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _pendingSyncCount > 0;
  int get pendingSyncCount => _pendingSyncCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;

  Future<void> initialize() async {
    await _connectivityService.initialize();
    _updateConnectionStatus();

    // Listen to connectivity changes
    _connectivityService.statusStream.listen((status) {
      _updateConnectionStatus();
    });

    // Update pending sync count
    await updatePendingSyncCount();
  }

  void _updateConnectionStatus() {
    final wasOffline = _isOffline;
    _isOffline = _connectivityService.isOffline;

    if (wasOffline && !_isOffline) {
      // Connection restored, trigger sync
      _onConnectionRestored();
    }

    notifyListeners();
  }

  void _onConnectionRestored() {
    // This will be called when connection is restored
    // Trigger sync in the background
    if (_pendingSyncCount > 0 && !_isSyncing) {
      // Don't await, let it run in background
      triggerSync().catchError((error) {
        debugPrint('Background sync failed: $error');
      });
    }
  }

  Future<void> updatePendingSyncCount() async {
    try {
      final pendingActions = await _cacheService.getPendingSyncActions();
      _pendingSyncCount = pendingActions.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending sync count: $e');
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncing || _isOffline) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      // Get pending sync actions
      final pendingActions = await _cacheService.getPendingSyncActions();
      
      if (pendingActions.isEmpty) {
        _lastSyncTime = DateTime.now();
        return;
      }

      // Process each action
      // Note: Actual sync logic will be implemented in sync services
      for (var action in pendingActions) {
        // TODO: Process sync action based on entity_type
        // For now, we'll just mark them as processed
        await _cacheService.removeSyncedAction(action['id'] as int);
      }

      _lastSyncTime = DateTime.now();
      await _cacheService.updateLastSyncTime('global');
      await updatePendingSyncCount();
    } catch (e) {
      _syncError = e.toString();
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> queueOfflineAction({
    required String action,
    required String entityType,
    required int entityId,
    required Map<String, dynamic> data,
  }) async {
    await _cacheService.queueOfflineAction(
      action: action,
      entityType: entityType,
      entityId: entityId,
      data: data,
    );
    await updatePendingSyncCount();
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
    await updatePendingSyncCount();
  }

  void setLastSyncTime(DateTime time) {
    _lastSyncTime = time;
    notifyListeners();
  }

  void setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
