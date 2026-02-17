import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiDebug {
  static Future<void> testConnection() async {
    print('🔍 Testing API Connection...');
    print('📍 Base URL: ${ApiConfig.baseUrl}');
    
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ Backend is reachable!');
        print('Response: ${response.body}');
      } else {
        print('⚠️ Backend responded with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Cannot reach backend: $e');
      print('💡 Tips:');
      print('  1. Ensure backend is running on port 10000');
      print('  2. For physical device, use computer IP not localhost');
      print('  3. Check firewall settings');
      print('  4. Verify network connectivity');
    }
  }
}
