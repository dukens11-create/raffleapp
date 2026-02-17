import '../models/raffle.dart';
import '../models/raffle_info.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class RaffleService {
  final ApiService _api = ApiService();

  /// Get current active raffle information
  /// Returns raffle data, categories, and statistics
  Future<RaffleInfo> getRaffleInfo() async {
    try {
      final response = await _api.get(ApiConfig.publicRaffleInfoEndpoint);
      
      if (response.statusCode == 200) {
        return RaffleInfo.fromJson(response.data);
      } else {
        throw Exception('Failed to load raffle info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch raffle info: $e');
    }
  }

  /// Get raffle by ID
  Future<Raffle> getRaffleById(int id) async {
    try {
      final response = await _api.get('${ApiConfig.apiVersion}/raffles/$id');
      
      if (response.statusCode == 200) {
        return Raffle.fromJson(response.data);
      } else {
        throw Exception('Failed to load raffle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch raffle: $e');
    }
  }

  /// Get all active raffles
  Future<List<Raffle>> getActiveRaffles() async {
    try {
      final response = await _api.get('${ApiConfig.apiVersion}/raffles?status=active');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Raffle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load active raffles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch active raffles: $e');
    }
  }
}
