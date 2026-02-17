import 'package:flutter/material.dart';
import '../models/raffle_info.dart';
import '../models/raffle.dart';
import '../services/raffle_service.dart';

class RaffleProvider with ChangeNotifier {
  final RaffleService _raffleService = RaffleService();

  RaffleInfo? _raffleInfo;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  RaffleInfo? get raffleInfo => _raffleInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Raffle? get currentRaffle => _raffleInfo?.raffle;
  
  bool get hasData => _raffleInfo != null;
  bool get needsRefresh {
    if (_lastFetched == null) return true;
    final difference = DateTime.now().difference(_lastFetched!);
    return difference.inMinutes > 5; // Refresh if data is older than 5 minutes
  }

  /// Load raffle information
  Future<void> loadRaffleInfo({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    if (!forceRefresh && hasData && !needsRefresh) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _raffleInfo = await _raffleService.getRaffleInfo();
      _lastFetched = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading raffle info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh raffle information
  Future<void> refresh() async {
    return loadRaffleInfo(forceRefresh: true);
  }

  /// Get category by code
  getCategoryByCode(String code) {
    return _raffleInfo?.getCategoryByCode(code);
  }

  /// Clear all data
  void clear() {
    _raffleInfo = null;
    _error = null;
    _lastFetched = null;
    notifyListeners();
  }
}
