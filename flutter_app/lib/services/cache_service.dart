import 'dart:convert';
import 'package:raffle_app/services/database_service.dart';
import 'package:raffle_app/services/storage_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  // Cache expiration times (in minutes)
  static const int _ticketsCacheExpiry = 30;
  static const int _userCacheExpiry = 60;
  static const int _raffleCacheExpiry = 15;

  // Check if cache is valid
  Future<bool> _isCacheValid(String key, int expiryMinutes) async {
    final lastUpdate = await _db.getCacheMetadata('last_update_$key');
    if (lastUpdate == null) return false;

    final lastUpdateTime = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime).inMinutes;

    return difference < expiryMinutes;
  }

  // Mark cache as updated
  Future<void> _markCacheUpdated(String key) async {
    await _db.setCacheMetadata(
      'last_update_$key',
      DateTime.now().toIso8601String(),
    );
  }

  // Cache tickets
  Future<void> cacheTickets(List<Map<String, dynamic>> tickets) async {
    for (var ticket in tickets) {
      await _db.insertTicket({
        ...ticket,
        'synced': 1, // From server, so it's synced
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    await _markCacheUpdated('tickets');
  }

  // Get cached tickets
  Future<List<Map<String, dynamic>>> getCachedTickets({
    int? buyerId,
    String? status,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && await _isCacheValid('tickets', _ticketsCacheExpiry)) {
      return await _db.getTickets(buyerId: buyerId, status: status);
    }
    return [];
  }

  // Cache single ticket
  Future<void> cacheTicket(Map<String, dynamic> ticket) async {
    await _db.insertTicket({
      ...ticket,
      'synced': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Cache user data
  Future<void> cacheUser(Map<String, dynamic> user) async {
    await _db.insertUser({
      ...user,
      'synced': 1,
    });
    await _markCacheUpdated('user_${user['id']}');
  }

  // Get cached user
  Future<Map<String, dynamic>?> getCachedUser(int userId) async {
    return await _db.getUser(userId);
  }

  // Cache current user profile
  Future<void> cacheCurrentUser(Map<String, dynamic> user) async {
    await cacheUser(user);
    await _storage.saveUserData(jsonEncode(user));
  }

  // Get current user from cache
  Future<Map<String, dynamic>?> getCachedCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Cache payments
  Future<void> cachePayments(List<Map<String, dynamic>> payments) async {
    for (var payment in payments) {
      await _db.insertPayment({
        ...payment,
        'synced': 1,
      });
    }
    await _markCacheUpdated('payments');
  }

  // Get cached payments
  Future<List<Map<String, dynamic>>> getCachedPayments({int? ticketId}) async {
    return await _db.getPayments(ticketId: ticketId);
  }

  // Cache raffles
  Future<void> cacheRaffles(List<Map<String, dynamic>> raffles) async {
    for (var raffle in raffles) {
      await _db.insertRaffle({
        ...raffle,
        'synced': 1,
      });
    }
    await _markCacheUpdated('raffles');
  }

  // Get cached raffles
  Future<List<Map<String, dynamic>>> getCachedRaffles({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && await _isCacheValid('raffles', _raffleCacheExpiry)) {
      return await _db.getRaffles();
    }
    return [];
  }

  // Store offline action for later sync
  Future<void> queueOfflineAction({
    required String action,
    required String entityType,
    required int entityId,
    required Map<String, dynamic> data,
  }) async {
    await _db.addToSyncQueue({
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  // Get pending sync actions
  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    return await _db.getSyncQueue();
  }

  // Remove synced action
  Future<void> removeSyncedAction(int queueId) async {
    await _db.deleteSyncQueueItem(queueId);
  }

  // Increment retry count
  Future<void> incrementRetryCount(int queueId, int currentRetryCount) async {
    await _db.updateSyncQueueRetryCount(queueId, currentRetryCount + 1);
  }

  // Cache notification
  Future<void> cacheNotification(Map<String, dynamic> notification) async {
    await _db.insertNotification({
      ...notification,
      'created_at': notification['created_at'] ?? DateTime.now().toIso8601String(),
    });
  }

  // Get cached notifications
  Future<List<Map<String, dynamic>>> getCachedNotifications({
    bool unreadOnly = false,
  }) async {
    return await _db.getNotifications(unreadOnly: unreadOnly);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    await _db.markNotificationAsRead(notificationId);
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final unreadNotifications = await _db.getNotifications(unreadOnly: true);
    return unreadNotifications.length;
  }

  // Get last sync time for a key
  Future<DateTime?> getLastSyncTime(String key) async {
    final lastSync = await _db.getCacheMetadata('last_sync_$key');
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  // Update last sync time
  Future<void> updateLastSyncTime(String key) async {
    await _db.setCacheMetadata(
      'last_sync_$key',
      DateTime.now().toIso8601String(),
    );
  }

  // Check if data needs sync
  Future<bool> needsSync(String key, int minutesSinceLastSync) async {
    final lastSync = await getLastSyncTime(key);
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync).inMinutes;
    return difference >= minutesSinceLastSync;
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await _db.clearCache();
  }

  // Clear specific cache
  Future<void> clearCache(String key) async {
    await _db.setCacheMetadata('last_update_$key', '');
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final tickets = await _db.getTickets();
    final payments = await _db.getPayments();
    final raffles = await _db.getRaffles();
    final syncQueue = await _db.getSyncQueue();
    final notifications = await _db.getNotifications();

    return {
      'tickets_count': tickets.length,
      'payments_count': payments.length,
      'raffles_count': raffles.length,
      'pending_sync_count': syncQueue.length,
      'notifications_count': notifications.length,
      'unread_notifications': await getUnreadNotificationCount(),
    };
  }
}
