import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/api_scratch_ticket.dart';
import '../services/scratch_service.dart';

/// State management for API-connected scratch tickets.
class ScratchProvider with ChangeNotifier {
  late final ScratchService _service;

  List<ApiScratchTicket> _tickets = [];
  ApiScratchTicket? _currentTicket;
  bool _isLoading = false;
  String? _error;

  List<ApiScratchTicket> get tickets => _tickets;
  ApiScratchTicket? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ScratchProvider() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));
    _service = ScratchService(dio);
  }

  /// Look up scratch tickets for the buyer by [ref], [email], or [phone].
  Future<void> loadTickets({String? ref, String? email, String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _service.getMyScratchTickets(
        ref: ref,
        email: email,
        phone: phone,
      );
    } catch (e) {
      _error = _extractError(e);
      _tickets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a single scratch ticket by payment reference.
  Future<void> loadTicket(String paymentRef) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentTicket = await _service.getScratchTicket(paymentRef);
    } catch (e) {
      _error = _extractError(e);
      _currentTicket = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record that the ticket was scratched and update prize data.
  Future<bool> markScratched(String paymentRef) async {
    try {
      final result = await _service.markScratched(paymentRef);
      if (_currentTicket != null && _currentTicket!.paymentReference == paymentRef) {
        _currentTicket = _currentTicket!.copyWith(
          hasPrize: result['has_prize'] == true || result['has_prize'] == 1,
          prizeAmount: (result['prize_amount'] ?? 0.0) is int
              ? (result['prize_amount'] as int).toDouble()
              : (result['prize_amount'] ?? 0.0) as double,
          prizeMessage: result['prize_message'] as String? ?? '',
          isScratched: true,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Claim the prize for the current ticket.
  Future<bool> claimPrize(String paymentRef) async {
    try {
      await _service.claimPrize(paymentRef);
      if (_currentTicket != null && _currentTicket!.paymentReference == paymentRef) {
        _currentTicket = _currentTicket!.copyWith(claimed: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data;
      if (msg is Map && msg['error'] != null) return msg['error'].toString();
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}
