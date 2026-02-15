import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Secure token storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // User data
  Future<void> saveUserId(int userId) async {
    await init();
    await _prefs?.setInt('user_id', userId);
  }

  Future<int?> getUserId() async {
    await init();
    return _prefs?.getInt('user_id');
  }

  Future<void> saveUserRole(String role) async {
    await init();
    await _prefs?.setString('user_role', role);
  }

  Future<String?> getUserRole() async {
    await init();
    return _prefs?.getString('user_role');
  }

  Future<void> saveUserPhone(String phone) async {
    await init();
    await _prefs?.setString('user_phone', phone);
  }

  Future<String?> getUserPhone() async {
    await init();
    return _prefs?.getString('user_phone');
  }

  // Clear all data
  Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
    await _secureStorage.deleteAll();
  }
}
