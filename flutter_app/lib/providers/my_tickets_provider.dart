import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

class MyTicketsProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Ticket> _myTickets = [];
  bool _isLoading = false;
  String? _error;
  String? _currentPhone;

  List<Ticket> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentPhone => _currentPhone;
  
  bool get hasTickets => _myTickets.isNotEmpty;
  int get ticketCount => _myTickets.length;

  /// Load tickets by phone number
  Future<void> loadTicketsByPhone(String phone) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPhone = phone;
    notifyListeners();

    try {
      _myTickets = await _ticketService.getTicketsByPhone(phone);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _myTickets = [];
      debugPrint('Error loading tickets by phone: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh tickets
  Future<void> refresh() async {
    if (_currentPhone != null) {
      await loadTicketsByPhone(_currentPhone!);
    }
  }

  /// Verify a ticket
  Future<TicketVerificationResult?> verifyTicket(String ticketNumber) async {
    try {
      return await _ticketService.verifyTicket(ticketNumber);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error verifying ticket: $e');
      notifyListeners();
      return null;
    }
  }

  /// Get tickets by category
  List<Ticket> getTicketsByCategory(String category) {
    return _myTickets.where((ticket) => ticket.category == category).toList();
  }

  /// Get sold tickets only
  List<Ticket> get soldTickets {
    return _myTickets.where((ticket) => ticket.isSold).toList();
  }

  /// Clear all data
  void clear() {
    _myTickets = [];
    _error = null;
    _currentPhone = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
