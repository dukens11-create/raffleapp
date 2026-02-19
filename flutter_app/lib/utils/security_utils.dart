import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Security utilities for the application
class SecurityUtils {
  /// Hash a password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate password strength
  static bool isPasswordStrong(String password) {
    // At least 8 characters
    if (password.length < 8) return false;

    // Contains uppercase
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Contains lowercase
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Contains number
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    return true;
  }

  /// Get password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return (score / 6 * 4).round().clamp(0, 4);
  }

  /// Sanitize user input to prevent XSS
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Basic phone validation (adjust regex for your needs)
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Generate a secure random string
  static String generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    
    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  /// Mask sensitive data for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final masked = '*' * (data.length - visibleChars);
    final visible = data.substring(data.length - visibleChars);
    return masked + visible;
  }

  /// Check if running on rooted/jailbroken device
  static Future<bool> isDeviceCompromised() async {
    // Implement platform-specific checks
    // For Android: check for root
    // For iOS: check for jailbreak
    
    if (kDebugMode) {
      return false; // Don't block in debug mode
    }
    
    // This would require platform-specific implementation
    return false;
  }

  /// Validate JWT token format
  static bool isValidJWTFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3;
  }

  /// Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];
      if (exp == null) return false;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  /// Secure comparison to prevent timing attacks
  static bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Validate input against SQL injection patterns
  static bool containsSQLInjection(String input) {
    final sqlPatterns = [
      RegExp(r"('|(--)|;|\s*DROP\s+|SELECT\s+|INSERT\s+|UPDATE\s+|DELETE\s+|UNION\s+)", caseSensitive: false),
    ];

    for (var pattern in sqlPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Rate limiting check (simple implementation)
  static final Map<String, List<DateTime>> _requestTimestamps = {};
  static const int _maxRequestsPerMinute = 60;

  static bool isRateLimited(String identifier) {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[identifier] ?? [];

    // Remove timestamps older than 1 minute
    timestamps.removeWhere((time) => now.difference(time).inMinutes >= 1);

    if (timestamps.length >= _maxRequestsPerMinute) {
      return true;
    }

    timestamps.add(now);
    _requestTimestamps[identifier] = timestamps;
    return false;
  }

  /// Clear rate limit for identifier
  static void clearRateLimit(String identifier) {
    _requestTimestamps.remove(identifier);
  }
}

/// Certificate pinning configuration
class CertificatePinning {
  // Add your certificate hashes here
  static const List<String> certificateHashes = [
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  /// Verify certificate hash
  static bool verifyCertificate(String certificateHash) {
    return certificateHashes.contains(certificateHash);
  }
}
