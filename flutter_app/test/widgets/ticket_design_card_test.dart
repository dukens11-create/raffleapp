import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/widgets/ticket_design_card.dart';

void main() {
  group('TicketDesignCard Widget Tests', () {
    testWidgets('BASIC ticket displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.basic,
            ),
          ),
        ),
      );

      expect(find.text('GRATE TOUT'), findsOneWidget);
      expect(find.text('50 GOURDES'), findsOneWidget);
      expect(find.text('BASIC'), findsOneWidget);
      expect(find.text('Scratch to Reveal'), findsOneWidget);
    });

    testWidgets('SILVER ticket displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.silver,
            ),
          ),
        ),
      );

      expect(find.text('500 GOURDES'), findsOneWidget);
      expect(find.text('SILVER'), findsOneWidget);
    });

    testWidgets('DIAMOND ticket displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.diamond,
            ),
          ),
        ),
      );

      expect(find.text('5,000 GOURDES'), findsOneWidget);
      expect(find.text('DIAMOND'), findsOneWidget);
    });

    test('TicketTier enum has correct values', () {
      expect(TicketTier.values.length, 6);
      
      expect(TicketTier.basic.price, 50);
      expect(TicketTier.basic.maxPrize, 5000);
      expect(TicketTier.basic.codePrefix, 'XYZ');
      
      expect(TicketTier.premium.price, 100);
      expect(TicketTier.premium.maxPrize, 10000);
      
      expect(TicketTier.bronze.price, 250);
      expect(TicketTier.bronze.maxPrize, 25000);
      
      expect(TicketTier.silver.price, 500);
      expect(TicketTier.silver.maxPrize, 150000);
      
      expect(TicketTier.gold.price, 1000);
      expect(TicketTier.gold.maxPrize, 500000);
      
      expect(TicketTier.diamond.price, 5000);
      expect(TicketTier.diamond.maxPrize, 2000000);
    });

    test('Code formats are correct', () {
      expect(TicketTier.basic.codeFormat, 'XYZ-######');
      expect(TicketTier.premium.codeFormat, 'EFG-######');
      expect(TicketTier.bronze.codeFormat, 'JKL-######');
      expect(TicketTier.silver.codeFormat, 'ABC-######');
      expect(TicketTier.gold.codeFormat, 'GOLD-#####');
      expect(TicketTier.diamond.codeFormat, 'DMD-#####');
    });

    testWidgets('TicketGalleryWidget displays all tiers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TicketGalleryWidget(),
        ),
      );

      expect(find.text('Ticket Design Gallery'), findsOneWidget);
      expect(find.byType(TicketDesignCard), findsNWidgets(6));
    });

    testWidgets('Ticket card responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.gold,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TicketDesignCard));
      expect(tapped, true);
    });

    testWidgets('Custom ticket code displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.gold,
              ticketCode: 'GOLD-12345',
            ),
          ),
        ),
      );

      expect(find.text('GOLD-12345'), findsOneWidget);
    });

    testWidgets('Can hide scratch area', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketDesignCard(
              tier: TicketTier.bronze,
              showScratchArea: false,
            ),
          ),
        ),
      );

      expect(find.text('Scratch to Reveal'), findsNothing);
    });
  });
}
