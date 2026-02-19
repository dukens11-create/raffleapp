import 'package:flutter/foundation.dart';
import 'package:raffle_app/models/seller.dart';
import 'package:raffle_app/services/seller_service.dart';

class SellerProvider with ChangeNotifier {
  final SellerService _sellerService = SellerService();

  List<Seller> _sellers = [];
  List<Seller> _pendingRequests = [];
  Seller? _selectedSeller;
  SellerStatistics? _sellerStatistics;
  bool _isLoading = false;
  String? _error;

  List<Seller> get sellers => _sellers;
  List<Seller> get pendingRequests => _pendingRequests;
  Seller? get selectedSeller => _selectedSeller;
  SellerStatistics? get sellerStatistics => _sellerStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all sellers
  Future<void> loadSellers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sellers = await _sellerService.getAllSellers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending seller requests
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingRequests = await _sellerService.getPendingSellerRequests();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load seller details
  Future<void> loadSellerDetails(int sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedSeller = await _sellerService.getSellerDetails(sellerId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load seller statistics
  Future<void> loadSellerStatistics(int sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sellerStatistics = await _sellerService.getSellerStatistics(sellerId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve seller
  Future<bool> approveSeller(int sellerId) async {
    try {
      await _sellerService.approveSeller(sellerId);
      await loadPendingRequests();
      await loadSellers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject seller
  Future<bool> rejectSeller(int sellerId, String reason) async {
    try {
      await _sellerService.rejectSeller(sellerId, reason);
      await loadPendingRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update seller
  Future<bool> updateSeller(int sellerId, Map<String, dynamic> data) async {
    try {
      final updatedSeller = await _sellerService.updateSeller(sellerId, data);
      _selectedSeller = updatedSeller;
      await loadSellers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete seller
  Future<bool> deleteSeller(int sellerId) async {
    try {
      await _sellerService.deleteSeller(sellerId);
      await loadSellers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
