import 'package:dio/dio.dart';
import '../models/api_scratch_ticket.dart';

/// Service for interacting with the scratch-ticket API endpoints.
class ScratchService {
  final Dio _dio;

  const ScratchService(this._dio);

  /// Look up scratch tickets by [ref], [email], or [phone].
  /// At least one identifier must be provided.
  Future<List<ApiScratchTicket>> getMyScratchTickets({
    String? ref,
    String? email,
    String? phone,
  }) async {
    final params = <String, String>{};
    if (ref != null && ref.isNotEmpty) params['ref'] = ref;
    if (email != null && email.isNotEmpty) params['email'] = email;
    if (phone != null && phone.isNotEmpty) params['phone'] = phone;

    final response = await _dio.get(
      '/api/scratch-tickets/my-cards',
      queryParameters: params,
    );

    final tickets = (response.data['tickets'] as List? ?? []);
    return tickets
        .map((json) => ApiScratchTicket.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single scratch ticket by payment reference.
  Future<ApiScratchTicket> getScratchTicket(String paymentRef) async {
    final response = await _dio.get(
      '/api/scratch-tickets/card/${Uri.encodeComponent(paymentRef)}',
    );
    return ApiScratchTicket.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mark the scratch ticket as scratched.
  /// Returns the updated prize information.
  Future<Map<String, dynamic>> markScratched(String paymentRef) async {
    final response = await _dio.post(
      '/api/scratch-tickets/card/${Uri.encodeComponent(paymentRef)}/scratch',
    );
    return response.data as Map<String, dynamic>;
  }

  /// Claim the prize for the given scratch ticket.
  /// Returns the claimed amount.
  Future<Map<String, dynamic>> claimPrize(String paymentRef) async {
    final response = await _dio.post(
      '/api/scratch-tickets/card/${Uri.encodeComponent(paymentRef)}/claim',
    );
    return response.data as Map<String, dynamic>;
  }
}
