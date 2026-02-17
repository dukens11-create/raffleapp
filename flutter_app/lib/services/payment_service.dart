import '../models/transaction.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class PaymentService {
  final ApiService _api = ApiService();

  /// Initiate a purchase with MonCash payment
  /// 
  /// Returns the payment URL to redirect the user to MonCash gateway
  Future<PurchaseResponse> initiateMonCashPurchase({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.publicPurchaseEndpoint,
        data: {
          'payment_method': 'moncash',
          'buyer_name': buyerName,
          'buyer_phone': buyerPhone,
          'buyer_email': buyerEmail,
          'department': department,
          'category': category,
          'quantity': quantity,
          'return_url': returnUrl,
          'cancel_url': cancelUrl,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to initiate purchase: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to initiate MonCash purchase: $e');
    }
  }

  /// Initiate a purchase with NatCash payment
  Future<PurchaseResponse> initiateNatCashPurchase({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.publicPurchaseEndpoint,
        data: {
          'payment_method': 'natcash',
          'buyer_name': buyerName,
          'buyer_phone': buyerPhone,
          'buyer_email': buyerEmail,
          'department': department,
          'category': category,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to initiate purchase: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to initiate NatCash purchase: $e');
    }
  }

  /// Submit manual payment (USSD or other)
  Future<PurchaseResponse> submitManualPayment({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.manualPaymentEndpoint,
        data: {
          'buyer_name': buyerName,
          'buyer_phone': buyerPhone,
          'buyer_email': buyerEmail,
          'department': department,
          'category': category,
          'quantity': quantity,
          'payment_method': paymentMethod,
          'transaction_id': transactionId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to submit payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit manual payment: $e');
    }
  }

  /// Verify payment status by reference
  Future<PaymentVerification> verifyPayment(String paymentReference) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/payments/verify/$paymentReference'
      );

      if (response.statusCode == 200) {
        return PaymentVerification.fromJson(response.data);
      } else {
        throw Exception('Failed to verify payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Get transaction by ID
  Future<Transaction> getTransaction(int transactionId) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/transactions/$transactionId'
      );

      if (response.statusCode == 200) {
        return Transaction.fromJson(response.data);
      } else {
        throw Exception('Failed to get transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transaction: $e');
    }
  }

  /// Get buyer's transaction history
  Future<List<Transaction>> getTransactionHistory(String buyerPhone) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/public/transactions?phone=${Uri.encodeComponent(buyerPhone)}'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['transactions'] ?? response.data;
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch transaction history: $e');
    }
  }

  /// Validate transaction ID format (12-15 digits for MonCash)
  bool validateTransactionId(String transactionId, {String method = 'moncash'}) {
    if (method == 'moncash') {
      // MonCash: 12-15 digit numeric string
      final regex = RegExp(r'^\d{12,15}$');
      return regex.hasMatch(transactionId);
    }
    return transactionId.isNotEmpty;
  }
}

class PurchaseResponse {
  final bool success;
  final String? paymentUrl;
  final String? paymentReference;
  final List<String>? ticketNumbers;
  final String? message;
  final String? error;
  final Transaction? transaction;

  PurchaseResponse({
    required this.success,
    this.paymentUrl,
    this.paymentReference,
    this.ticketNumbers,
    this.message,
    this.error,
    this.transaction,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    List<String>? tickets;
    if (json['ticket_numbers'] != null) {
      if (json['ticket_numbers'] is List) {
        tickets = (json['ticket_numbers'] as List).map((t) => t.toString()).toList();
      } else if (json['ticket_numbers'] is String) {
        tickets = (json['ticket_numbers'] as String).split(',').map((t) => t.trim()).toList();
      }
    }

    return PurchaseResponse(
      success: json['success'] as bool,
      paymentUrl: json['payment_url'] as String?,
      paymentReference: json['payment_reference'] as String?,
      ticketNumbers: tickets,
      message: json['message'] as String?,
      error: json['error'] as String?,
      transaction: json['transaction'] != null 
        ? Transaction.fromJson(json['transaction']) 
        : null,
    );
  }
}

class PaymentVerification {
  final bool verified;
  final String status;
  final Transaction? transaction;
  final String? message;

  PaymentVerification({
    required this.verified,
    required this.status,
    this.transaction,
    this.message,
  });

  factory PaymentVerification.fromJson(Map<String, dynamic> json) {
    return PaymentVerification(
      verified: json['verified'] as bool,
      status: json['status'] as String,
      transaction: json['transaction'] != null 
        ? Transaction.fromJson(json['transaction']) 
        : null,
      message: json['message'] as String?,
    );
  }
}
