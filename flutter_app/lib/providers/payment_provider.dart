import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  bool _isProcessing = false;
  String? _error;
  String? _paymentUrl;
  String? _paymentReference;
  List<String>? _ticketNumbers;
  Transaction? _currentTransaction;
  String _paymentMethod = 'moncash'; // Default to MonCash

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get paymentUrl => _paymentUrl;
  String? get paymentReference => _paymentReference;
  List<String>? get ticketNumbers => _ticketNumbers;
  Transaction? get currentTransaction => _currentTransaction;
  String get paymentMethod => _paymentMethod;

  /// Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Initiate MonCash purchase
  Future<bool> initiateMonCashPurchase({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _error = null;
    _paymentUrl = null;
    _paymentReference = null;
    _ticketNumbers = null;
    notifyListeners();

    try {
      final response = await _paymentService.initiateMonCashPurchase(
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerEmail: buyerEmail,
        department: department,
        category: category,
        quantity: quantity,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );

      if (response.success) {
        _paymentUrl = response.paymentUrl;
        _paymentReference = response.paymentReference;
        _ticketNumbers = response.ticketNumbers;
        _currentTransaction = response.transaction;
        return true;
      } else {
        _error = response.error ?? 'Purchase failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initiating MonCash purchase: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Initiate NatCash purchase
  Future<bool> initiateNatCashPurchase({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _error = null;
    _paymentReference = null;
    _ticketNumbers = null;
    notifyListeners();

    try {
      final response = await _paymentService.initiateNatCashPurchase(
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerEmail: buyerEmail,
        department: department,
        category: category,
        quantity: quantity,
      );

      if (response.success) {
        _paymentReference = response.paymentReference;
        _ticketNumbers = response.ticketNumbers;
        _currentTransaction = response.transaction;
        return true;
      } else {
        _error = response.error ?? 'Purchase failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initiating NatCash purchase: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Submit manual payment
  Future<bool> submitManualPayment({
    required String buyerName,
    required String buyerPhone,
    String? buyerEmail,
    String? department,
    required String category,
    required int quantity,
    required String paymentMethod,
    required String transactionId,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _error = null;
    _paymentReference = null;
    _ticketNumbers = null;
    notifyListeners();

    try {
      final response = await _paymentService.submitManualPayment(
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerEmail: buyerEmail,
        department: department,
        category: category,
        quantity: quantity,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      if (response.success) {
        _paymentReference = response.paymentReference;
        _ticketNumbers = response.ticketNumbers;
        _currentTransaction = response.transaction;
        return true;
      } else {
        _error = response.error ?? 'Payment submission failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting manual payment: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Verify payment
  Future<bool> verifyPayment(String paymentReference) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final verification = await _paymentService.verifyPayment(paymentReference);
      
      if (verification.verified) {
        _currentTransaction = verification.transaction;
        return true;
      } else {
        _error = verification.message ?? 'Payment verification failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error verifying payment: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Validate transaction ID
  bool validateTransactionId(String transactionId) {
    return _paymentService.validateTransactionId(
      transactionId,
      method: _paymentMethod,
    );
  }

  /// Clear payment data
  void clear() {
    _error = null;
    _paymentUrl = null;
    _paymentReference = null;
    _ticketNumbers = null;
    _currentTransaction = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
