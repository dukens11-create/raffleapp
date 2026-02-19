import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and behaviors
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isInitialized = false;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize Firebase Analytics or other analytics service
    // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('✅ Analytics service initialized');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      debugPrint('📊 Screen view: $screenName');
    }
    
    // await FirebaseAnalytics.instance.logScreenView(
    //   screenName: screenName,
    //   screenClass: screenClass ?? screenName,
    // );
  }

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      debugPrint('📊 Event: $name ${parameters != null ? '- $parameters' : ''}');
    }
    
    // await FirebaseAnalytics.instance.logEvent(
    //   name: name,
    //   parameters: parameters,
    // );
  }

  /// Log button click
  Future<void> logButtonClick(String buttonName, {String? screen}) async {
    await logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        if (screen != null) 'screen': screen,
      },
    );
  }

  /// Log ticket purchase
  Future<void> logTicketPurchase({
    required String ticketId,
    required String category,
    required double amount,
    required String paymentMethod,
  }) async {
    await logEvent(
      name: 'purchase_ticket',
      parameters: {
        'ticket_id': ticketId,
        'category': category,
        'amount': amount,
        'payment_method': paymentMethod,
        'currency': 'HTG',
      },
    );
  }

  /// Log payment initiation
  Future<void> logPaymentInitiated({
    required double amount,
    required String method,
  }) async {
    await logEvent(
      name: 'payment_initiated',
      parameters: {
        'amount': amount,
        'method': method,
        'currency': 'HTG',
      },
    );
  }

  /// Log payment completion
  Future<void> logPaymentCompleted({
    required String transactionId,
    required double amount,
    required String method,
  }) async {
    await logEvent(
      name: 'payment_completed',
      parameters: {
        'transaction_id': transactionId,
        'amount': amount,
        'method': method,
        'currency': 'HTG',
      },
    );
  }

  /// Log QR code scan
  Future<void> logQRScan({
    required String ticketId,
    required bool success,
  }) async {
    await logEvent(
      name: 'qr_scan',
      parameters: {
        'ticket_id': ticketId,
        'success': success,
      },
    );
  }

  /// Log search
  Future<void> logSearch(String query, {int? resultsCount}) async {
    await logEvent(
      name: 'search',
      parameters: {
        'query': query,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  /// Log error
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? userRole,
    String? department,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (kDebugMode) {
      debugPrint('📊 Setting user properties: userId=$userId, role=$userRole');
    }
    
    // await FirebaseAnalytics.instance.setUserId(id: userId);
    // await FirebaseAnalytics.instance.setUserProperty(name: 'role', value: userRole);
  }

  /// Log app open
  Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  /// Log login
  Future<void> logLogin(String method) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  /// Log logout
  Future<void> logLogout() async {
    await logEvent(name: 'logout');
  }

  /// Log signup
  Future<void> logSignup(String method, String role) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        'method': method,
        'role': role,
      },
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {'feature': featureName},
    );
  }

  /// Track user engagement
  Future<void> trackEngagement({
    required String action,
    required Duration duration,
  }) async {
    await logEvent(
      name: 'user_engagement',
      parameters: {
        'action': action,
        'duration_seconds': duration.inSeconds,
      },
    );
  }
}
