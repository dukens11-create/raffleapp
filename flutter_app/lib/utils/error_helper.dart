import '../config/api_config.dart';

class ErrorHelper {
  /// Formats an error message with troubleshooting information
  static String formatErrorMessage(String error) {
    return '''
$error

Connected to: ${ApiConfig.baseUrl}

Troubleshooting:
• Check your internet connection
• Verify the server is accessible
• Review backend logs for errors
• Contact support if issue persists''';
  }
}
