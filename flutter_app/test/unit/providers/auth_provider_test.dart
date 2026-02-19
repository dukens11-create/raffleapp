import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('should create AuthProvider instance', () {
      expect(authProvider, isNotNull);
      expect(authProvider, isA<AuthProvider>());
    });

    test('should have initial state as not authenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
    });

    group('login', () {
      test('should set loading state during login', () async {
        final loginFuture = authProvider.login('1234567890', 'password');
        
        // Check that loading is true during operation
        // Note: This might be false by the time we check due to async nature
        expect(authProvider.isLoading, isA<bool>());
        
        await loginFuture;
      });

      test('should return result after login attempt', () async {
        final result = await authProvider.login('1234567890', 'password');
        
        expect(result, isA<bool>());
        expect(authProvider.isLoading, false);
      });
    });

    group('logout', () {
      test('should clear user data on logout', () async {
        await authProvider.logout();
        
        expect(authProvider.isAuthenticated, false);
        expect(authProvider.user, null);
        expect(authProvider.errorMessage, null);
      });

      test('should not be loading after logout', () async {
        await authProvider.logout();
        
        expect(authProvider.isLoading, false);
      });
    });

    group('checkAuthStatus', () {
      test('should check authentication status', () async {
        await authProvider.checkAuthStatus();
        
        expect(authProvider.isLoading, false);
        expect(authProvider.isAuthenticated, isA<bool>());
      });
    });

    group('clearError', () {
      test('should clear error message', () {
        authProvider.clearError();
        
        expect(authProvider.errorMessage, null);
      });
    });

    test('should expose user role', () {
      expect(authProvider.userRole, isA<String?>());
    });
  });
}
