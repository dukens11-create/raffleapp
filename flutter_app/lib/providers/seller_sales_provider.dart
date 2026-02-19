import 'package:flutter/foundation.dart';
import 'package:raffle_app/models/seller.dart';
import 'package:raffle_app/services/seller_service.dart';

class SellerSalesProvider with ChangeNotifier {
  final SellerService _sellerService = SellerService();

  SellerStatistics? _statistics;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _commission;
  bool _isLoading = false;
  String? _error;

  SellerStatistics? get statistics => _statistics;
  List<Map<String, dynamic>> get sales => _sales;
  List<Map<String, dynamic>> get tickets => _tickets;
  Map<String, dynamic>? get commission => _commission;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load seller's own statistics
  Future<void> loadMyStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await _sellerService.getMyStatistics();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load seller's sales history
  Future<void> loadMySales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _sellerService.getMySales();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load seller's tickets
  Future<void> loadMyTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _sellerService.getMyTickets();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load commission details
  Future<void> loadMyCommission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _commission = await _sellerService.getMyCommission();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a sale
  Future<bool> recordSale(String ticketNumber, Map<String, dynamic> saleData) async {
    try {
      await _sellerService.recordSale(ticketNumber, saleData);
      await loadMyStatistics();
      await loadMySales();
      await loadMyTickets();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadMyStatistics(),
      loadMySales(),
      loadMyTickets(),
      loadMyCommission(),
    ]);
  }
}
