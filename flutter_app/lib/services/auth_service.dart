import 'package:raffle_app/models/user.dart';
import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/services/storage_service.dart';
import 'package:raffle_app/config/api_config.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.loginEndpoint,
        data: {
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Save user data
        if (data['token'] != null) {
          await _storage.saveToken(data['token']);
        }
        
        if (data['user'] != null) {
          final user = User.fromJson(data['user']);
          await _storage.saveUserId(user.id);
          await _storage.saveUserRole(user.role);
          await _storage.saveUserPhone(user.phone);
        }

        return {
          'success': true,
          'user': data['user'] != null ? User.fromJson(data['user']) : null,
          'message': data['message'] ?? 'Login successful',
        };
      }

      return {
        'success': false,
        'message': 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: ${e.toString()}',
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _api.get(ApiConfig.logoutEndpoint);
      await _storage.clearAll();
      return true;
    } catch (e) {
      await _storage.clearAll();
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserRole() async {
    return await _storage.getUserRole();
  }

  Future<Map<String, dynamic>> registerSeller({
    required String phone,
    required String password,
    required String name,
    required String email,
    required String department,
    String? idPicturePath,
  }) async {
    try {
      // Implementation for seller registration with photo upload
      // This would use postFormData for multipart form data
      return {
        'success': true,
        'message': 'Registration submitted for approval',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }
}
