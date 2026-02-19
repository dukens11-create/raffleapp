import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/models/ticket_admin.dart';

class AdminTicketService {
  final ApiService _apiService = ApiService();

  /// Get all tickets with optional filters
  Future<List<TicketAdmin>> getAllTickets({
    String? category,
    String? status,
    String? seller,
    String? buyer,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (seller != null) queryParams['seller'] = seller;
      if (buyer != null) queryParams['buyer'] = buyer;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get(
        '/api/admin/tickets',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((e) => TicketAdmin.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }

  /// Get ticket by ID
  Future<TicketAdmin> getTicket(int ticketId) async {
    try {
      final response = await _apiService.get('/api/admin/tickets/$ticketId');
      return TicketAdmin.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load ticket: $e');
    }
  }

  /// Create a new ticket
  Future<TicketAdmin> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final response = await _apiService.post('/api/admin/tickets', data: ticketData);
      return TicketAdmin.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// Update ticket
  Future<TicketAdmin> updateTicket(int ticketId, Map<String, dynamic> ticketData) async {
    try {
      final response = await _apiService.put('/api/admin/tickets/$ticketId', data: ticketData);
      return TicketAdmin.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  /// Delete ticket
  Future<void> deleteTicket(int ticketId) async {
    try {
      await _apiService.delete('/api/admin/tickets/$ticketId');
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  /// Bulk ticket operations
  Future<Map<String, dynamic>> bulkOperation(BulkTicketOperation operation) async {
    try {
      final response = await _apiService.post(
        '/api/admin/tickets/bulk',
        data: operation.toJson(),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to perform bulk operation: $e');
    }
  }

  /// Verify ticket
  Future<void> verifyTicket(String ticketNumber) async {
    try {
      await _apiService.post(
        '/api/admin/verify-ticket',
        data: {'ticket_number': ticketNumber},
      );
    } catch (e) {
      throw Exception('Failed to verify ticket: $e');
    }
  }

  /// Invalidate ticket
  Future<void> invalidateTicket(int ticketId) async {
    try {
      await _apiService.put(
        '/api/admin/tickets/$ticketId',
        data: {'status': 'invalid'},
      );
    } catch (e) {
      throw Exception('Failed to invalidate ticket: $e');
    }
  }

  /// Get ticket count
  Future<Map<String, dynamic>> getTicketCount() async {
    try {
      final response = await _apiService.get('/api/admin/tickets/count');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get ticket count: $e');
    }
  }

  /// Export tickets
  Future<void> exportTickets() async {
    try {
      await _apiService.get('/api/admin/tickets/export');
    } catch (e) {
      throw Exception('Failed to export tickets: $e');
    }
  }
}
