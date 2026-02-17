import 'dart:convert';
import 'dart:io';
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

  /// Helper method to provide user-friendly error messages
  String _handleError(dynamic error, String endpoint) {
    // Network connectivity issues
    if (error is SocketException) {
      return 'Cannot connect to server at $baseUrl. Please check your internet connection and verify the server is accessible.';
    }
    
    final errorString = error.toString();
    
    // Check for network errors in wrapped exceptions
    if (errorString.contains('SocketException') || errorString.contains('Failed host lookup')) {
      return 'Cannot connect to server at $baseUrl. Please check your internet connection and verify the server is accessible.';
    }
    
    // Timeout issues
    if (errorString.contains('TimeoutException') || errorString.contains('timed out')) {
      return 'Connection timeout. The server at $baseUrl is taking too long to respond. Please try again.';
    }
    
    // HTTP errors
    if (errorString.contains('Failed to load')) {
      return '$errorString (Endpoint: $endpoint, URL: $baseUrl)';
    }
    
    // Generic error with context
    return 'Error connecting to $baseUrl$endpoint: $errorString';
  }

  // Raffle Info
  Future<RaffleInfo> getRaffleInfo() async {
    try {
      final url = '$baseUrl${ApiConfig.publicRaffleInfoEndpoint}';
      print('🔍 Fetching raffle info from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Raffle info loaded successfully');
        return RaffleInfo.fromJson(data);
      } else {
        print('❌ Failed to load raffle info: ${response.statusCode}');
        throw Exception('Failed to load raffle info: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching raffle info: $e');
      throw Exception(_handleError(e, ApiConfig.publicRaffleInfoEndpoint));
    }
  }

  // Available Tickets
  Future<AvailableTicketsResponse> getAvailableTickets({String? category}) async {
    try {
      var url = '$baseUrl/api/buyer/available-tickets';
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }

      print('🔍 Fetching available tickets from: $url');

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Available tickets loaded successfully');
        return AvailableTicketsResponse.fromJson(data);
      } else {
        print('❌ Available Tickets HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load available tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Available Tickets Error: $e');
      throw Exception(_handleError(e, '/api/buyer/available-tickets'));
    }
  }

  // Departments
  Future<List<String>> getDepartments() async {
    try {
      final url = '$baseUrl/api/public/departments';
      print('🔍 Fetching departments from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Departments loaded successfully');
        return (data['departments'] as List).cast<String>();
      } else {
        print('❌ Failed to load departments: ${response.statusCode}');
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching departments: $e');
      throw Exception(_handleError(e, '/api/public/departments'));
    }
  }

  // Ticket Availability
  Future<Map<String, dynamic>> getTicketAvailability() async {
    try {
      final url = '$baseUrl/api/public/ticket-availability';
      print('🔍 Fetching ticket availability from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        print('✅ Ticket availability loaded successfully');
        return json.decode(response.body);
      } else {
        print('❌ Failed to load ticket availability: ${response.statusCode}');
        throw Exception('Failed to load ticket availability: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching ticket availability: $e');
      throw Exception(_handleError(e, '/api/public/ticket-availability'));
    }
  }

  // Payment Methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final url = '$baseUrl/api/payments/methods';
      print('🔍 Fetching payment methods from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment methods loaded successfully');
        return (data['payment_methods'] as List)
            .map((m) => PaymentMethod.fromJson(m))
            .toList();
      } else {
        print('❌ Failed to load payment methods: ${response.statusCode}');
        throw Exception('Failed to load payment methods: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching payment methods: $e');
      throw Exception(_handleError(e, '/api/payments/methods'));
    }
  }

  // Manual Instructions
  Future<ManualInstructions> getManualInstructions(String method) async {
    try {
      final url = '$baseUrl/api/payments/manual-instructions/$method';
      print('🔍 Fetching manual instructions from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Manual instructions loaded successfully');
        return ManualInstructions.fromJson(data);
      } else {
        print('❌ Failed to load manual instructions: ${response.statusCode}');
        throw Exception('Failed to load manual instructions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching manual instructions: $e');
      throw Exception(_handleError(e, '/api/payments/manual-instructions/$method'));
    }
  }

  // Purchase
  Future<PurchaseResponse> initiatePurchase(PurchaseRequest request) async {
    try {
      final url = '$baseUrl${ApiConfig.publicPurchaseEndpoint}';
      print('🔍 Initiating purchase at: $url');
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Purchase initiated successfully');
        return PurchaseResponse.fromJson(data);
      } else {
        print('❌ Failed to initiate purchase: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to initiate purchase');
      }
    } catch (e) {
      print('❌ Error initiating purchase: $e');
      throw Exception(_handleError(e, ApiConfig.publicPurchaseEndpoint));
    }
  }

  // Submit Manual Payment
  Future<ManualPaymentResponse> submitManualPayment(ManualPaymentRequest request) async {
    try {
      final url = '$baseUrl${ApiConfig.manualPaymentEndpoint}';
      print('🔍 Submitting manual payment at: $url');
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Manual payment submitted successfully');
        return ManualPaymentResponse.fromJson(data);
      } else {
        print('❌ Failed to submit manual payment: ${response.statusCode}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit manual payment');
      }
    } catch (e) {
      print('❌ Error submitting manual payment: $e');
      throw Exception(_handleError(e, ApiConfig.manualPaymentEndpoint));
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

      final url = '$baseUrl/api/public/my-tickets';
      print('🔍 Looking up tickets at: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Tickets lookup successful');
        return MyTicketsResponse.fromJson(data);
      } else {
        print('❌ Failed to lookup tickets: ${response.statusCode}');
        throw Exception('Failed to lookup tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error looking up tickets: $e');
      throw Exception(_handleError(e, '/api/public/my-tickets'));
    }
  }

  // Verify Ticket
  Future<VerifyTicketResponse> verifyTicket(String ticketNumber) async {
    try {
      final url = '$baseUrl/api/public/verify-ticket/$ticketNumber';
      print('🔍 Verifying ticket at: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Ticket verified successfully');
        return VerifyTicketResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        print('⚠️ Ticket not found');
        return VerifyTicketResponse(
          valid: false,
          message: 'Ticket not found',
        );
      } else {
        print('❌ Failed to verify ticket: ${response.statusCode}');
        throw Exception('Failed to verify ticket: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error verifying ticket: $e');
      throw Exception(_handleError(e, '/api/public/verify-ticket/$ticketNumber'));
    }
  }
}
