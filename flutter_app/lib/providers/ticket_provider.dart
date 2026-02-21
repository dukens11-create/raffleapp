import 'package:flutter/material.dart';
import '../models/scratch/scratch_ticket.dart';
import '../models/scratch/prize.dart';
import '../models/ticket_data.dart';
import '../utils/ticket_constants.dart';

class TicketProvider with ChangeNotifier {
  // Scratch ticket list (loaded from local constants)
  List<ScratchTicket> _scratchTickets = [];

  // Generic buyer ticket list (implements TicketData)
  List<TicketData> _tickets = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  Map<String, Prize> _scratchedTickets = {};

  /// The scratch ticket gallery list (used by [TicketGalleryScreen]).
  List<ScratchTicket> get scratchTickets => _scratchTickets;

  /// Generic buyer ticket list (set via [setTickets]).
  List<TicketData> get tickets => _tickets;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMorePages => _currentPage < _totalPages;
  Map<String, Prize> get scratchedTickets => _scratchedTickets;

  TicketProvider() {
    loadTickets();
  }

  void loadTickets() {
    _isLoading = true;
    notifyListeners();

    // Load scratch tickets from constants
    _scratchTickets = TicketConstants.allTickets;

    _isLoading = false;
    notifyListeners();
  }

  // ── Testable state setters ───────────────────────────────────────────────

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void setTickets(List<TicketData> tickets) {
    _tickets = tickets;
    _error = null;
    notifyListeners();
  }

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void setTotalPages(int total) {
    _totalPages = total;
    notifyListeners();
  }

  // ── Query helpers ────────────────────────────────────────────────────────

  List<TicketData> getTicketsByCategory(String category) {
    return _tickets.where((t) => t.category == category).toList();
  }

  List<TicketData> getAvailableTickets() {
    return _tickets.where((t) => t.status == 'available').toList();
  }

  TicketData? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TicketData> searchTickets(String term) {
    final q = term.toLowerCase();
    return _tickets.where((t) => t.ticketNumber.toLowerCase().contains(q)).toList();
  }

  List<TicketData> filterByPriceRange(double minPrice, double maxPrice) {
    return _tickets
        .where((t) => t.price >= minPrice && t.price <= maxPrice)
        .toList();
  }

  // ── Scratch ticket operations ────────────────────────────────────────────

  Prize scratchTicket(String ticketId) {
    final ticket = _scratchTickets.firstWhere((t) => t.id == ticketId);
    final prize = ticket.selectPrize();

    _scratchedTickets[ticketId] = prize;
    notifyListeners();

    return prize;
  }

  Prize? getScratchedPrize(String ticketId) {
    return _scratchedTickets[ticketId];
  }

  void clearScratchedTickets() {
    _scratchedTickets.clear();
    notifyListeners();
  }
}
