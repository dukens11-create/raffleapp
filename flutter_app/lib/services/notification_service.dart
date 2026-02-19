import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/services/local_notification_service.dart';
import 'package:raffle_app/models/notification.dart' as app_notification;
import 'package:raffle_app/services/api_service.dart';

// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  
  // Save notification to cache
  try {
    final cacheService = CacheService();
    await cacheService.cacheNotification({
      'id': message.messageId.hashCode,
      'title': message.notification?.title ?? 'Notification',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'system_alert',
      'data': message.data,
      'read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    debugPrint('Error caching background notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final CacheService _cacheService = CacheService();
  final ApiService _apiService = ApiService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notification permission granted');
        
        // Initialize local notifications
        await _localNotificationService.initialize();
        
        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('FCM Token: $_fcmToken');
        
        // Send token to backend
        if (_fcmToken != null) {
          await _registerToken(_fcmToken!);
        }
        
        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _registerToken(newToken);
        });
        
        // Setup message handlers
        _setupMessageHandlers();
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<NotificationSettings> _requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      _handleMessage(message, isBackground: false);
    });

    // Handle when user taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message,
      {required bool isBackground}) async {
    try {
      // Save to cache
      final notification = app_notification.NotificationModel(
        id: message.messageId.hashCode,
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        type: _parseNotificationType(message.data['type']),
        data: message.data,
      );

      await _cacheService.cacheNotification(notification.toMap());

      // Show local notification if in foreground
      if (!isBackground) {
        await _localNotificationService.showNotification(
          id: notification.id ?? 0,
          title: notification.title,
          body: notification.body,
          payload: notification.data.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  app_notification.NotificationType _parseNotificationType(dynamic type) {
    if (type == null) return app_notification.NotificationType.systemAlert;
    return app_notification.NotificationModel.fromJson({
      'title': '',
      'body': '',
      'type': type.toString(),
    }).type;
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // TODO: Implement deep linking based on notification type
    // Navigate to appropriate screen based on message.data
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiService.post('/api/fcm/register', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  // Get all notifications from cache
  Future<List<app_notification.NotificationModel>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final notifications = await _cacheService.getCachedNotifications(
      unreadOnly: unreadOnly,
    );
    return notifications
        .map((n) => app_notification.NotificationModel.fromMap(n))
        .toList();
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    await _cacheService.markNotificationAsRead(notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final db = await CacheService().getCachedNotifications();
    for (var notification in db) {
      await _cacheService.markNotificationAsRead(notification['id'] as int);
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    return await _cacheService.getUnreadNotificationCount();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Subscribe to role-based topics
  Future<void> subscribeToRoleTopics(String role) async {
    await subscribeToTopic('all_users');
    await subscribeToTopic(role.toLowerCase());
  }
}
