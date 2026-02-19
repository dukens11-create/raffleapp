import 'package:flutter/foundation.dart';
import 'package:raffle_app/models/ticket_admin.dart';
import 'package:raffle_app/services/admin_ticket_service.dart';

class AdminTicketProvider with ChangeNotifier {
  final AdminTicketService _ticketService = AdminTicketService();

  List<TicketAdmin> _tickets = [];
  TicketAdmin? _selectedTicket;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<TicketAdmin> get tickets => _tickets;
  TicketAdmin? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Load tickets with filters
  Future<void> loadTickets({
    String? category,
    String? status,
    String? seller,
    String? buyer,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _ticketService.getAllTickets(
        category: category,
        status: status,
        seller: seller,
        buyer: buyer,
        startDate: startDate,
        endDate: endDate,
        page: page ?? _currentPage,
      );
      _currentPage = page ?? _currentPage;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ticket details
  Future<void> loadTicketDetails(int ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTicket = await _ticketService.getTicket(ticketId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create ticket
  Future<bool> createTicket(Map<String, dynamic> ticketData) async {
    try {
      await _ticketService.createTicket(ticketData);
      await loadTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update ticket
  Future<bool> updateTicket(int ticketId, Map<String, dynamic> ticketData) async {
    try {
      _selectedTicket = await _ticketService.updateTicket(ticketId, ticketData);
      await loadTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete ticket
  Future<bool> deleteTicket(int ticketId) async {
    try {
      await _ticketService.deleteTicket(ticketId);
      await loadTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Bulk operation
  Future<bool> performBulkOperation(BulkTicketOperation operation) async {
    try {
      await _ticketService.bulkOperation(operation);
      await loadTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Verify ticket
  Future<bool> verifyTicket(String ticketNumber) async {
    try {
      await _ticketService.verifyTicket(ticketNumber);
      await loadTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Next page
  void nextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      loadTickets(page: _currentPage);
    }
  }

  /// Previous page
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadTickets(page: _currentPage);
    }
  }
}
