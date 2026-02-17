import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

class BuyerTicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Ticket> _tickets = [];
  Map<String, List<Ticket>> _ticketsByCategory = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalTickets = 0;
  String? _selectedCategory;

  List<Ticket> get tickets => _tickets;
  Map<String, List<Ticket>> get ticketsByCategory => _ticketsByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalTickets => _totalTickets;
  String? get selectedCategory => _selectedCategory;
  
  bool get hasTickets => _tickets.isNotEmpty;
  bool get hasMorePages => _currentPage < _totalPages;

  /// Load available tickets with pagination
  Future<void> loadTickets({
    int? page,
    String? category,
    bool append = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    if (!append) {
      _error = null;
    }
    notifyListeners();

    try {
      final pageNum = page ?? _currentPage;
      final response = await _ticketService.getAvailableTickets(
        page: pageNum,
        limit: 50,
        category: category ?? _selectedCategory,
      );

      if (append) {
        _tickets.addAll(response.tickets);
      } else {
        _tickets = response.tickets;
      }

      _currentPage = response.page;
      _totalPages = response.totalPages;
      _totalTickets = response.total;
      _selectedCategory = category ?? _selectedCategory;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading tickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (hasMorePages && !_isLoading) {
      await loadTickets(
        page: _currentPage + 1,
        append: true,
      );
    }
  }

  /// Refresh tickets
  Future<void> refresh() async {
    _currentPage = 1;
    await loadTickets(page: 1);
  }

  /// Filter by category
  Future<void> filterByCategory(String? category) async {
    _selectedCategory = category;
    _currentPage = 1;
    await loadTickets(page: 1, category: category);
  }

  /// Load buyer's available tickets (last 100K per category)
  Future<void> loadBuyerAvailableTickets() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ticketsByCategory = await _ticketService.getBuyerAvailableTickets();
      
      // Flatten all tickets for the main list
      _tickets = [];
      _ticketsByCategory.forEach((category, tickets) {
        _tickets.addAll(tickets);
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading buyer tickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get tickets for a specific category
  List<Ticket> getTicketsForCategory(String category) {
    return _ticketsByCategory[category] ?? [];
  }

  /// Clear all data
  void clear() {
    _tickets = [];
    _ticketsByCategory = {};
    _error = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalTickets = 0;
    _selectedCategory = null;
    notifyListeners();
  }
}
