import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/notification_service.dart';
import 'package:raffle_app/models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    await _notificationService.initialize();
    await loadNotifications();
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(
        unreadOnly: unreadOnly,
      );
      _unreadCount = await _notificationService.getUnreadCount();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  Future<void> subscribeToRoleTopics(String role) async {
    await _notificationService.subscribeToRoleTopics(role);
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.read).toList();
  }
}
