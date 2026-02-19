import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/scratch_ticket.dart';
import '../services/scratch_service.dart';
import '../config/api_config.dart';

class ScratchProvider with ChangeNotifier {
  late final ScratchService _service;

  List<ScratchTicket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  ScratchProvider() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _service = ScratchService(dio);
  }

  List<ScratchTicket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _service.getMyScratchTickets(phone);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ScratchTicket?> getTicket(String paymentReference) async {
    try {
      return await _service.getScratchTicket(paymentReference);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ScratchTicket?> markScratched(
      String paymentReference, String phone) async {
    try {
      final updated = await _service.markScratched(paymentReference, phone);
      // Update in local list if present
      final idx = _tickets.indexWhere(
          (t) => t.paymentReference == paymentReference);
      if (idx >= 0) {
        _tickets[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> claimPrize(String paymentReference, String phone) async {
    try {
      await _service.claimPrize(paymentReference, phone);
      // Reload the ticket to reflect claimed status
      final updated = await _service.getScratchTicket(paymentReference);
      final idx = _tickets.indexWhere(
          (t) => t.paymentReference == paymentReference);
      if (idx >= 0) {
        _tickets[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
