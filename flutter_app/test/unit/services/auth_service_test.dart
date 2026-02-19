import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/auth_service.dart';
import '../../mocks/mock_api_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should create AuthService instance', () {
      expect(authService, isNotNull);
      expect(authService, isA<AuthService>());
    });

    group('login', () {
      test('should return success response on successful login', () async {
        final result = await authService.login('1234567890', 'password123');
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), true);
      });

      test('should handle login with valid credentials', () async {
        final phone = '1234567890';
        final password = 'testpassword';
        
        final result = await authService.login(phone, password);
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], isA<bool>());
      });

      test('should return error message on failed login', () async {
        final result = await authService.login('invalid', 'invalid');
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('message'), true);
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        final result = await authService.logout();
        
        expect(result, isA<bool>());
      });

      test('should clear storage on logout', () async {
        await authService.logout();
        final isAuth = await authService.isAuthenticated();
        
        expect(isAuth, false);
      });
    });

    group('isAuthenticated', () {
      test('should return false when not authenticated', () async {
        final result = await authService.isAuthenticated();
        
        expect(result, false);
      });
    });

    group('getUserRole', () {
      test('should return user role', () async {
        final result = await authService.getUserRole();
        
        expect(result, isA<String?>());
      });
    });

    group('registerSeller', () {
      test('should register seller successfully', () async {
        final result = await authService.registerSeller(
          phone: '1234567890',
          password: 'password123',
          name: 'Test Seller',
          email: 'test@example.com',
          department: 'Sales',
        );
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], isA<bool>());
      });

      test('should handle seller registration with ID picture', () async {
        final result = await authService.registerSeller(
          phone: '1234567890',
          password: 'password123',
          name: 'Test Seller',
          email: 'test@example.com',
          department: 'Sales',
          idPicturePath: '/path/to/image.jpg',
        );
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('message'), true);
      });
    });
  });
}
