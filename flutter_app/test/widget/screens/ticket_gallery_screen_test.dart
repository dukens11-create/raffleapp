import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/screens/scratch/ticket_gallery_screen.dart';
import 'package:raffle_app/providers/ticket_provider.dart';
import 'package:raffle_app/widgets/ticket_card.dart';

void main() {
  group('TicketGalleryScreen Widget Tests', () {
    Widget buildSubject() {
      return MaterialApp(
        home: ChangeNotifierProvider<TicketProvider>(
          create: (_) => TicketProvider(),
          child: const TicketGalleryScreen(),
        ),
      );
    }

    testWidgets('displays 3 columns on standard phone width (390px)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));
    });

    testWidgets('falls back to 2 columns on very narrow screen (250px)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(250, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));
    });

    testWidgets('renders 6 ticket cards', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // All 6 scratch tickets from TicketConstants should be rendered
      expect(find.byType(TicketCard), findsNWidgets(6));
    });

    testWidgets('displays bilingual header text', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.text('Chwazi yon tikè epi grate pou wè si ou genyen!'),
        findsOneWidget,
      );
      expect(
        find.text('Choose a ticket and scratch to win!'),
        findsOneWidget,
      );
    });
  });
}
