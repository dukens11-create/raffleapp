import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/models/sync_task.dart';

class TicketSync {
  static final TicketSync _instance = TicketSync._internal();
  factory TicketSync() => _instance;
  TicketSync._internal();

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Sync tickets from server to local cache
  Future<void> syncFromServer({DateTime? since}) async {
    try {
      debugPrint('Syncing tickets from server...');
      
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      // Fetch tickets from server
      final response = await _apiService.get(
        '/api/tickets',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final tickets = response.data['tickets'] as List<dynamic>? ?? [];
        
        // Cache each ticket
        for (var ticketData in tickets) {
          await _cacheService.cacheTicket(ticketData as Map<String, dynamic>);
        }
        
        debugPrint('Synced ${tickets.length} tickets from server');
      }
    } catch (e) {
      debugPrint('Error syncing tickets from server: $e');
      rethrow;
    }
  }

  // Sync pending ticket actions to server
  Future<void> syncToServer(List<SyncTask> tasks) async {
    for (var task in tasks) {
      try {
        await _syncTask(task);
      } catch (e) {
        debugPrint('Error syncing ticket task ${task.id}: $e');
        rethrow;
      }
    }
  }

  Future<void> _syncTask(SyncTask task) async {
    switch (task.action) {
      case SyncAction.create:
        await _createTicket(task.data);
        break;
      case SyncAction.update:
        await _updateTicket(task.entityId, task.data);
        break;
      case SyncAction.delete:
        await _deleteTicket(task.entityId);
        break;
    }
  }

  Future<void> _createTicket(Map<String, dynamic> ticketData) async {
    debugPrint('Creating ticket on server: ${ticketData['barcode']}');
    
    final response = await _apiService.post('/api/tickets', ticketData);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      // Update local cache with server response
      if (response.data != null) {
        await _cacheService.cacheTicket(response.data);
      }
      debugPrint('Ticket created successfully');
    }
  }

  Future<void> _updateTicket(int ticketId, Map<String, dynamic> ticketData) async {
    debugPrint('Updating ticket on server: $ticketId');
    
    final response = await _apiService.put('/api/tickets/$ticketId', ticketData);
    
    if (response.statusCode == 200) {
      // Update local cache
      if (response.data != null) {
        await _cacheService.cacheTicket(response.data);
      }
      debugPrint('Ticket updated successfully');
    }
  }

  Future<void> _deleteTicket(int ticketId) async {
    debugPrint('Deleting ticket on server: $ticketId');
    
    final response = await _apiService.delete('/api/tickets/$ticketId');
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      debugPrint('Ticket deleted successfully');
    }
  }

  // Bulk sync tickets
  Future<void> bulkSync(List<Map<String, dynamic>> tickets) async {
    try {
      debugPrint('Bulk syncing ${tickets.length} tickets...');
      
      final response = await _apiService.post('/api/sync/tickets', {
        'tickets': tickets,
      });

      if (response.statusCode == 200) {
        debugPrint('Bulk sync completed successfully');
        
        // Update local cache with synced data
        if (response.data != null && response.data['tickets'] != null) {
          final syncedTickets = response.data['tickets'] as List<dynamic>;
          for (var ticket in syncedTickets) {
            await _cacheService.cacheTicket(ticket as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in bulk ticket sync: $e');
      rethrow;
    }
  }

  // Get delta updates from server
  Future<void> getDeltaUpdates({required DateTime since}) async {
    try {
      debugPrint('Getting ticket delta updates since: $since');
      
      final response = await _apiService.get(
        '/api/sync/updates',
        queryParameters: {
          'entity': 'tickets',
          'since': since.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final updates = response.data['tickets'] as List<dynamic>? ?? [];
        
        for (var update in updates) {
          await _cacheService.cacheTicket(update as Map<String, dynamic>);
        }
        
        debugPrint('Applied ${updates.length} ticket delta updates');
      }
    } catch (e) {
      debugPrint('Error getting ticket delta updates: $e');
      rethrow;
    }
  }
}
