import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/models/sync_task.dart';

class PaymentSync {
  static final PaymentSync _instance = PaymentSync._internal();
  factory PaymentSync() => _instance;
  PaymentSync._internal();

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Sync payments from server to local cache
  Future<void> syncFromServer({DateTime? since}) async {
    try {
      debugPrint('Syncing payments from server...');
      
      final queryParams = <String, dynamic>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await _apiService.get(
        '/api/payments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final payments = response.data['payments'] as List<dynamic>? ?? [];
        
        for (var paymentData in payments) {
          await _cacheService.cachePayments([paymentData as Map<String, dynamic>]);
        }
        
        debugPrint('Synced ${payments.length} payments from server');
      }
    } catch (e) {
      debugPrint('Error syncing payments from server: $e');
      rethrow;
    }
  }

  // Sync pending payment actions to server
  Future<void> syncToServer(List<SyncTask> tasks) async {
    for (var task in tasks) {
      try {
        await _syncTask(task);
      } catch (e) {
        debugPrint('Error syncing payment task ${task.id}: $e');
        rethrow;
      }
    }
  }

  Future<void> _syncTask(SyncTask task) async {
    switch (task.action) {
      case SyncAction.create:
        await _createPayment(task.data);
        break;
      case SyncAction.update:
        await _updatePayment(task.entityId, task.data);
        break;
      case SyncAction.delete:
        // Payments are typically not deleted
        debugPrint('Delete payment not supported');
        break;
    }
  }

  Future<void> _createPayment(Map<String, dynamic> paymentData) async {
    debugPrint('Creating payment on server');
    
    final response = await _apiService.post('/api/payments', paymentData);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      if (response.data != null) {
        await _cacheService.cachePayments([response.data]);
      }
      debugPrint('Payment created successfully');
    }
  }

  Future<void> _updatePayment(int paymentId, Map<String, dynamic> paymentData) async {
    debugPrint('Updating payment on server: $paymentId');
    
    final response = await _apiService.put('/api/payments/$paymentId', paymentData);
    
    if (response.statusCode == 200) {
      if (response.data != null) {
        await _cacheService.cachePayments([response.data]);
      }
      debugPrint('Payment updated successfully');
    }
  }

  // Bulk sync payments
  Future<void> bulkSync(List<Map<String, dynamic>> payments) async {
    try {
      debugPrint('Bulk syncing ${payments.length} payments...');
      
      final response = await _apiService.post('/api/sync/payments', {
        'payments': payments,
      });

      if (response.statusCode == 200) {
        debugPrint('Bulk payment sync completed successfully');
        
        if (response.data != null && response.data['payments'] != null) {
          final syncedPayments = response.data['payments'] as List<dynamic>;
          await _cacheService.cachePayments(
            syncedPayments.cast<Map<String, dynamic>>(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in bulk payment sync: $e');
      rethrow;
    }
  }

  // Get delta updates from server
  Future<void> getDeltaUpdates({required DateTime since}) async {
    try {
      debugPrint('Getting payment delta updates since: $since');
      
      final response = await _apiService.get(
        '/api/sync/updates',
        queryParameters: {
          'entity': 'payments',
          'since': since.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final updates = response.data['payments'] as List<dynamic>? ?? [];
        
        await _cacheService.cachePayments(
          updates.cast<Map<String, dynamic>>(),
        );
        
        debugPrint('Applied ${updates.length} payment delta updates');
      }
    } catch (e) {
      debugPrint('Error getting payment delta updates: $e');
      rethrow;
    }
  }
}
