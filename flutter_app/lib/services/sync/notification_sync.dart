import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/services/cache_service.dart';

class NotificationSync {
  static final NotificationSync _instance = NotificationSync._internal();
  factory NotificationSync() => _instance;
  NotificationSync._internal();

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Sync notifications from server
  Future<void> syncFromServer({DateTime? since}) async {
    try {
      debugPrint('Syncing notifications from server...');
      
      final queryParams = <String, dynamic>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await _apiService.get(
        '/api/notifications',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final notifications = response.data['notifications'] as List<dynamic>? ?? [];
        
        for (var notificationData in notifications) {
          await _cacheService.cacheNotification(notificationData as Map<String, dynamic>);
        }
        
        debugPrint('Synced ${notifications.length} notifications from server');
      }
    } catch (e) {
      debugPrint('Error syncing notifications from server: $e');
      rethrow;
    }
  }

  // Mark notification as read on server
  Future<void> markAsReadOnServer(int notificationId) async {
    try {
      await _apiService.put('/api/notifications/$notificationId/read', {});
      debugPrint('Notification marked as read on server');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Sync read status to server
  Future<void> syncReadStatus(List<int> readNotificationIds) async {
    try {
      if (readNotificationIds.isEmpty) return;
      
      await _apiService.post('/api/notifications/mark-read', {
        'notification_ids': readNotificationIds,
      });
      
      debugPrint('Synced read status for ${readNotificationIds.length} notifications');
    } catch (e) {
      debugPrint('Error syncing read status: $e');
    }
  }
}
