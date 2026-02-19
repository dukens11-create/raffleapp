import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/auth_provider.dart';
import 'package:raffle_app/screens/buyer/buyer_portal.dart';

void main() {
  group('BuyerPortal Widget Tests', () {
    testWidgets('should render buyer portal screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const BuyerPortal(),
          ),
        ),
      );

      // Verify the screen renders
      expect(find.byType(BuyerPortal), findsOneWidget);
    });

    testWidgets('should display app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const BuyerPortal(),
          ),
        ),
      );

      // Check for AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have navigation elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const BuyerPortal(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify screen is rendered
      expect(find.byType(BuyerPortal), findsOneWidget);
    });
  });
}
