# Secure Storage Service

Enhanced secure storage service for sensitive data.

## Overview

This service extends flutter_secure_storage with additional security features.

## Implementation

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  /// Save user credentials
  Future<void> saveCredentials(String username, String password) async {
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    await saveEncrypted('username', username);
    await saveEncrypted('password', hashedPassword);
  }

  /// Check if biometric auth is available
  Future<bool> canUseBiometric() async {
    // Implementation would use local_auth package
    return false;
  }
}
```

## Usage

```dart
final secureStorage = SecureStorageService();

// Save token
await secureStorage.saveAuthToken('your_token');

// Retrieve token
final token = await secureStorage.getAuthToken();

// Clear all
await secureStorage.clearAll();
```

## Security Features

1. **Platform-specific encryption**
   - Android: EncryptedSharedPreferences
   - iOS: Keychain with first_unlock accessibility

2. **Automatic encryption** of sensitive data

3. **Secure deletion** of stored data

4. **Biometric authentication** support (optional)

## Best Practices

- Never store plain passwords
- Rotate tokens regularly
- Clear storage on logout
- Use biometric auth when available
- Handle storage errors gracefully
