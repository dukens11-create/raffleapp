import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/buyer/raffle_info.dart';
import '../models/buyer/available_ticket.dart';
import '../models/buyer/payment_method.dart';
import '../models/buyer/purchase_data.dart';
import '../models/buyer/my_ticket.dart';
import '../models/buyer/verify_ticket.dart';

class BuyerApiService {
  final String baseUrl = ApiConfig.baseUrl;
  final Duration timeout = const Duration(seconds: 10);

  // Raffle Info
  Future<RaffleInfo> getRaffleInfo() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConfig.publicRaffleInfoEndpoint}'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RaffleInfo.fromJson(data);
      } else {
        throw Exception('Failed to load raffle info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching raffle info: $e');
    }
  }

  // Available Tickets
  Future<AvailableTicketsResponse> getAvailableTickets({String? category}) async {
    try {
      var url = '$baseUrl/api/buyer/available-tickets';
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AvailableTicketsResponse.fromJson(data);
      } else {
        print('❌ Available Tickets HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load available tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Available Tickets Error: $e');
      if (e is! Exception) {
        print('Error type: ${e.runtimeType}');
      }
      throw Exception('Error fetching available tickets: $e');
    }
  }

  // Departments
  Future<List<String>> getDepartments() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/public/departments'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['departments'] as List).cast<String>();
      } else {
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching departments: $e');
    }
  }

  // Ticket Availability
  Future<Map<String, dynamic>> getTicketAvailability() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/public/ticket-availability'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load ticket availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ticket availability: $e');
    }
  }

  // Payment Methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/payments/methods'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['payment_methods'] as List)
            .map((m) => PaymentMethod.fromJson(m))
            .toList();
      } else {
        throw Exception('Failed to load payment methods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment methods: $e');
    }
  }

  // Manual Instructions
  Future<ManualInstructions> getManualInstructions(String method) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/payments/manual-instructions/$method'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ManualInstructions.fromJson(data);
      } else {
        throw Exception('Failed to load manual instructions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching manual instructions: $e');
    }
  }

  // Purchase
  Future<PurchaseResponse> initiatePurchase(PurchaseRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.publicPurchaseEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return PurchaseResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to initiate purchase');
      }
    } catch (e) {
      throw Exception('Error initiating purchase: $e');
    }
  }

  // Submit Manual Payment
  Future<ManualPaymentResponse> submitManualPayment(ManualPaymentRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.manualPaymentEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ManualPaymentResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit manual payment');
      }
    } catch (e) {
      throw Exception('Error submitting manual payment: $e');
    }
  }

  // My Tickets
  Future<MyTicketsResponse> lookupMyTickets({
    String? email,
    String? phone,
    String? buyerCode,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (buyerCode != null && buyerCode.isNotEmpty) body['buyer_code'] = buyerCode;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/public/my-tickets'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MyTicketsResponse.fromJson(data);
      } else {
        throw Exception('Failed to lookup tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error looking up tickets: $e');
    }
  }

  // Verify Ticket
  Future<VerifyTicketResponse> verifyTicket(String ticketNumber) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/public/verify-ticket/$ticketNumber'),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerifyTicketResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        return VerifyTicketResponse(
          valid: false,
          message: 'Ticket not found',
        );
      } else {
        throw Exception('Failed to verify ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying ticket: $e');
    }
  }
}
