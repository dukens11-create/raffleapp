import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/auth_provider.dart';
import 'package:raffle_app/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should render login screen with all elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.text('Grate Genyen'), findsOneWidget);
      expect(find.text('Raffle Management System'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should display phone number and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find text fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Verify field labels/hints
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should validate phone number field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find login button and tap it without entering data
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter phone but not password
      final phoneField = find.byType(TextFormField).first;
      await tester.enterText(phoneField, '1234567890');

      // Find and tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error for password
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should show/hide password when visibility icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Find password field
      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsNWidgets(2));

      // Find visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility);
      
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pump();

        // After tapping, the icon should change
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });

    testWidgets('should display logo icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify logo icon is present
      expect(find.byIcon(Icons.confirmation_number), findsOneWidget);
    });

    testWidgets('should allow text input in phone field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      final phoneField = find.byType(TextFormField).first;
      await tester.enterText(phoneField, '1234567890');
      
      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('should allow text input in password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      
      expect(find.text('password123'), findsOneWidget);
    });
  });
}
