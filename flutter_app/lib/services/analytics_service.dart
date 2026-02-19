import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/models/statistics.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();

  /// Get admin statistics
  Future<Statistics> getAdminStatistics() async {
    try {
      final response = await _apiService.get('/api/admin/statistics');
      return Statistics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  /// Get department statistics
  Future<List<DepartmentStat>> getDepartmentStats() async {
    try {
      final response = await _apiService.get('/api/admin/department-stats');
      return (response.data as List)
          .map((e) => DepartmentStat.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load department stats: $e');
    }
  }

  /// Get seller statistics
  Future<List<SellerStat>> getSellerStats() async {
    try {
      final response = await _apiService.get('/api/seller-stats');
      return (response.data as List)
          .map((e) => SellerStat.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load seller stats: $e');
    }
  }

  /// Get statistics for a specific date range
  Future<Statistics> getStatisticsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/admin/statistics',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return Statistics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }
}
