import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ErrorHelper {
  /// Formats an error message with troubleshooting information
  static String formatErrorMessage(String error) {
    final buffer = StringBuffer();
    buffer.writeln(error);
    
    // Only show API URL in debug mode to avoid exposing infrastructure details in production
    if (kDebugMode) {
      buffer.writeln();
      buffer.writeln('Connected to: ${ApiConfig.baseUrl}');
    }
    
    buffer.writeln();
    buffer.writeln('Troubleshooting:');
    buffer.writeln('• Check your internet connection');
    buffer.writeln('• Verify the server is accessible');
    if (kDebugMode) {
      buffer.writeln('• Review backend logs for errors');
    }
    buffer.writeln('• Contact support if issue persists');
    
    return buffer.toString();
  }
}
