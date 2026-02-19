import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/models/seller.dart';

class SellerService {
  final ApiService _apiService = ApiService();

  /// Get all sellers
  Future<List<Seller>> getAllSellers() async {
    try {
      final response = await _apiService.get('/api/sellers');
      return (response.data as List)
          .map((e) => Seller.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sellers: $e');
    }
  }

  /// Get pending seller requests
  Future<List<Seller>> getPendingSellerRequests() async {
    try {
      final response = await _apiService.get('/api/seller-requests');
      return (response.data as List)
          .map((e) => Seller.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load seller requests: $e');
    }
  }

  /// Get seller details
  Future<Seller> getSellerDetails(int sellerId) async {
    try {
      final response = await _apiService.get('/api/sellers/$sellerId');
      return Seller.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load seller details: $e');
    }
  }

  /// Get seller statistics
  Future<SellerStatistics> getSellerStatistics(int sellerId) async {
    try {
      final response = await _apiService.get('/api/sellers/$sellerId/statistics');
      return SellerStatistics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load seller statistics: $e');
    }
  }

  /// Approve seller request
  Future<void> approveSeller(int sellerId) async {
    try {
      await _apiService.post('/api/seller-requests/$sellerId/approve');
    } catch (e) {
      throw Exception('Failed to approve seller: $e');
    }
  }

  /// Reject seller request
  Future<void> rejectSeller(int sellerId, String reason) async {
    try {
      await _apiService.post(
        '/api/seller-requests/$sellerId/reject',
        data: {'reason': reason},
      );
    } catch (e) {
      throw Exception('Failed to reject seller: $e');
    }
  }

  /// Update seller
  Future<Seller> updateSeller(int sellerId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/sellers/$sellerId', data: data);
      return Seller.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update seller: $e');
    }
  }

  /// Delete seller
  Future<void> deleteSeller(int sellerId) async {
    try {
      await _apiService.delete('/api/sellers/$sellerId');
    } catch (e) {
      throw Exception('Failed to delete seller: $e');
    }
  }

  /// Get seller's own statistics (for seller dashboard)
  Future<SellerStatistics> getMyStatistics() async {
    try {
      final response = await _apiService.get('/api/seller/statistics');
      return SellerStatistics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  /// Get seller's sales history
  Future<List<Map<String, dynamic>>> getMySales() async {
    try {
      final response = await _apiService.get('/api/seller/sales');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load sales: $e');
    }
  }

  /// Record a sale
  Future<void> recordSale(String ticketNumber, Map<String, dynamic> saleData) async {
    try {
      await _apiService.post(
        '/api/seller/sell',
        data: {'ticket_number': ticketNumber, ...saleData},
      );
    } catch (e) {
      throw Exception('Failed to record sale: $e');
    }
  }

  /// Get seller's commission details
  Future<Map<String, dynamic>> getMyCommission() async {
    try {
      final response = await _apiService.get('/api/seller/commission');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load commission: $e');
    }
  }

  /// Get seller's assigned tickets
  Future<List<Map<String, dynamic>>> getMyTickets() async {
    try {
      final response = await _apiService.get('/api/seller/tickets');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }
}
