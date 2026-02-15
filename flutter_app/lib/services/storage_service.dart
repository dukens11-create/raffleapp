import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  Completer<SharedPreferences>? _prefsCompleter;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    
    // Ensure only one initialization happens at a time
    if (_prefsCompleter != null) {
      return _prefsCompleter!.future;
    }
    
    _prefsCompleter = Completer<SharedPreferences>();
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsCompleter!.complete(_prefs!);
      return _prefs!;
    } catch (e) {
      _prefsCompleter!.completeError(e);
      _prefsCompleter = null;
      rethrow;
    }
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
    final prefs = await _getPrefs();
    await prefs.setInt('user_id', userId);
  }

  Future<int?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getInt('user_id');
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_role', role);
  }

  Future<String?> getUserRole() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_role');
  }

  Future<void> saveUserPhone(String phone) async {
    final prefs = await _getPrefs();
    await prefs.setString('user_phone', phone);
  }

  Future<String?> getUserPhone() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_phone');
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
