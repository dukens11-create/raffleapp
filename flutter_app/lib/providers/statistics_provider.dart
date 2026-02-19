import 'package:flutter/foundation.dart';
import 'package:raffle_app/models/statistics.dart';
import 'package:raffle_app/services/analytics_service.dart';

class StatisticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Statistics? _statistics;
  bool _isLoading = false;
  String? _error;

  Statistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load admin statistics
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await _analyticsService.getAdminStatistics();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _statistics = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load statistics for date range
  Future<void> loadStatisticsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _statistics = await _analyticsService.getStatisticsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _statistics = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await loadStatistics();
  }
}
