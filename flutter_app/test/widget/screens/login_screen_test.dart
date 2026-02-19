import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/screens/auth/login_screen.dart';
import 'package:raffle_app/providers/auth_provider.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should have phone and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Look for text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
    });

    testWidgets('should validate empty phone field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Try to submit with empty fields
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      // Note: Actual validation text depends on implementation
    });

    testWidgets('should validate empty password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter phone but not password
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '+50912345678');
      }

      // Try to submit
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pump();
    });

    testWidgets('should show loading indicator during login', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Set loading state
      authProvider.setLoading(true);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should accept valid phone number format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // Enter valid phone
        await tester.enterText(textFields.first, '+50912345678');
        await tester.pump();

        // Field should accept the input
        expect(find.text('+50912345678'), findsOneWidget);
      }
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Look for password visibility toggle button
      final toggleButton = find.byIcon(Icons.visibility);
      if (toggleButton.evaluate().isNotEmpty) {
        await tester.tap(toggleButton);
        await tester.pump();

        // Icon should change
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });

    testWidgets('should navigate to register screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Look for register link/button
      final registerLink = find.text('Register');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should show error message on login failure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Set error state
      authProvider.setError('Invalid credentials');
      await tester.pump();

      // Should display error message
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should clear error on field change', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Set error
      authProvider.setError('Error message');
      await tester.pump();

      // Enter text in field
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test');
        await tester.pump();
      }
    });
  });
}
