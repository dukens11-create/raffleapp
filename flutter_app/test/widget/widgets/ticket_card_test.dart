import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/widgets/raffle_ticket_card.dart';

void main() {
  group('Ticket Card Widget Tests', () {
    testWidgets('should render ticket card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RaffleTicketCard(
              title: 'Test Ticket',
              price: 100.0,
              category: 'Premium',
            ),
          ),
        ),
      );

      // Verify ticket card renders
      expect(find.byType(RaffleTicketCard), findsOneWidget);
    });

    testWidgets('should display ticket information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RaffleTicketCard(
              title: 'Test Ticket',
              price: 100.0,
              category: 'Premium',
            ),
          ),
        ),
      );

      // Verify ticket information is displayed
      expect(find.text('Test Ticket'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('should be tappable', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapped = true,
              child: const RaffleTicketCard(
                title: 'Test Ticket',
                price: 100.0,
                category: 'Premium',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, true);
    });
  });
}
