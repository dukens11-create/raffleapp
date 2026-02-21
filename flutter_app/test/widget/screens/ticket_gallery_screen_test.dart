import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/screens/scratch/ticket_gallery_screen.dart';
import 'package:raffle_app/providers/ticket_provider.dart';

void main() {
  group('TicketGalleryScreen grid layout', () {
    testWidgets('uses 3 columns at standard phone width (390 px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TicketProvider>(
            create: (_) => TicketProvider(),
            child: const TicketGalleryScreen(),
          ),
        ),
      );

      await tester.pump();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('falls back to 2 columns on narrow screens (< 360 px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TicketProvider>(
            create: (_) => TicketProvider(),
            child: const TicketGalleryScreen(),
          ),
        ),
      );

      await tester.pump();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });
  });
}
