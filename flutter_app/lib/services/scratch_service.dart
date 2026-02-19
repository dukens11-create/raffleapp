import 'package:dio/dio.dart';
import '../models/scratch_ticket.dart';

class ScratchService {
  final Dio _dio;

  ScratchService(this._dio);

  /// Fetch all scratch tickets for a buyer identified by phone number.
  Future<List<ScratchTicket>> getMyScratchTickets(String phone) async {
    final response = await _dio.get(
      '/api/buyer/scratch-tickets',
      queryParameters: {'phone': phone},
    );
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final list = data['tickets'] as List? ?? [];
      return list
          .map((json) => ScratchTicket.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch a single scratch ticket by its payment reference.
  Future<ScratchTicket> getScratchTicket(String paymentReference) async {
    final response = await _dio.get(
      '/api/buyer/scratch-ticket/${Uri.encodeComponent(paymentReference)}',
    );
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return ScratchTicket.fromJson(data['ticket'] as Map<String, dynamic>);
    }
    throw Exception('Ticket not found');
  }

  /// Mark a scratch ticket as scratched (reveals the prize).
  Future<ScratchTicket> markScratched(String paymentReference, String phone) async {
    final response = await _dio.post(
      '/api/buyer/scratch-ticket/${Uri.encodeComponent(paymentReference)}/scratch',
      data: {'phone': phone},
    );
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return ScratchTicket.fromJson(data['ticket'] as Map<String, dynamic>);
    }
    throw Exception('Failed to mark ticket as scratched');
  }

  /// Claim the prize for a winning scratch ticket.
  Future<Map<String, dynamic>> claimPrize(
      String paymentReference, String phone) async {
    final response = await _dio.post(
      '/api/buyer/scratch-ticket/${Uri.encodeComponent(paymentReference)}/claim',
      data: {'phone': phone},
    );
    final data = response.data;
    if (data is Map && data['success'] == true) {
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception(
        (data is Map ? data['error'] : null) ?? 'Failed to claim prize');
  }
}
