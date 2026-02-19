import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import '../../lib/services/api_service.dart';

/// Mock API Service for testing
/// 
/// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  ApiService,
  http.Client,
])
class MockApiService extends Mock implements ApiService {
  // Mock responses will be implemented by Mockito code generation
}

/// Manual mock for quick testing without code generation
class SimpleApiService implements ApiService {
  Map<String, dynamic>? _nextResponse;
  Exception? _nextError;
  int _nextStatusCode = 200;

  /// Set the next response to return
  void setNextResponse(Map<String, dynamic> response, {int statusCode = 200}) {
    _nextResponse = response;
    _nextStatusCode = statusCode;
    _nextError = null;
  }

  /// Set the next error to throw
  void setNextError(Exception error) {
    _nextError = error;
    _nextResponse = null;
  }

  /// Reset mock state
  void reset() {
    _nextResponse = null;
    _nextError = null;
    _nextStatusCode = 200;
  }

  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    if (_nextError != null) {
      throw _nextError!;
    }
    
    if (_nextResponse != null) {
      return _nextResponse!;
    }

    return {'status': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    if (_nextError != null) {
      throw _nextError!;
    }
    
    if (_nextResponse != null) {
      return _nextResponse!;
    }

    return {'status': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    if (_nextError != null) {
      throw _nextError!;
    }
    
    if (_nextResponse != null) {
      return _nextResponse!;
    }

    return {'status': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    if (_nextError != null) {
      throw _nextError!;
    }
    
    if (_nextResponse != null) {
      return _nextResponse!;
    }

    return {'status': 'ok'};
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
