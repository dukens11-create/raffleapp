import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Enhanced secure storage service for sensitive data
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  // Android-specific options
  final _androidOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // iOS-specific options
  final _iosOptions = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  /// Save encrypted data
  Future<void> saveEncrypted(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  /// Read encrypted data
  Future<String?> readEncrypted(String key) async {
    return await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  /// Delete encrypted data
  Future<void> deleteEncrypted(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all encrypted data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    await saveEncrypted('auth_token', token);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await readEncrypted('auth_token');
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await saveEncrypted('refresh_token', token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await readEncrypted('refresh_token');
  }

  /// Save user credentials (password is hashed)
  Future<void> saveCredentials(String username, String password) async {
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    await saveEncrypted('username', username);
    await saveEncrypted('password', hashedPassword);
  }

  /// Get saved username
  Future<String?> getUsername() async {
    return await readEncrypted('username');
  }

  /// Verify password against stored hash
  Future<bool> verifyPassword(String password) async {
    final storedHash = await readEncrypted('password');
    if (storedHash == null) return false;
    
    final inputHash = sha256.convert(utf8.encode(password)).toString();
    return inputHash == storedHash;
  }
}
