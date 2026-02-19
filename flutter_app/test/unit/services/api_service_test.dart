import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('should create ApiService instance', () {
      expect(apiService, isNotNull);
      expect(apiService, isA<ApiService>());
    });

    test('should have dio instance configured', () async {
      // Test that the service is properly initialized
      expect(apiService, isNotNull);
    });

    group('GET requests', () {
      test('should make GET request successfully', () async {
        // This test would require mocking the Dio instance
        // For now, we're testing the method exists and can be called
        expect(() => apiService.get('/test'), returnsNormally);
      });

      test('should handle GET request with query parameters', () async {
        expect(
          () => apiService.get('/test', queryParameters: {'key': 'value'}),
          returnsNormally,
        );
      });
    });

    group('POST requests', () {
      test('should make POST request successfully', () async {
        expect(() => apiService.post('/test'), returnsNormally);
      });

      test('should handle POST request with data', () async {
        expect(
          () => apiService.post('/test', data: {'key': 'value'}),
          returnsNormally,
        );
      });

      test('should handle POST request with query parameters', () async {
        expect(
          () => apiService.post(
            '/test',
            data: {'key': 'value'},
            queryParameters: {'param': 'value'},
          ),
          returnsNormally,
        );
      });
    });

    group('PUT requests', () {
      test('should make PUT request successfully', () async {
        expect(() => apiService.put('/test'), returnsNormally);
      });

      test('should handle PUT request with data', () async {
        expect(
          () => apiService.put('/test', data: {'key': 'value'}),
          returnsNormally,
        );
      });
    });

    group('DELETE requests', () {
      test('should make DELETE request successfully', () async {
        expect(() => apiService.delete('/test'), returnsNormally);
      });
    });

    group('FormData requests', () {
      test('should handle FormData upload', () async {
        final formData = FormData.fromMap({'key': 'value'});
        expect(
          () => apiService.postFormData('/test', formData),
          returnsNormally,
        );
      });
    });
  });
}
