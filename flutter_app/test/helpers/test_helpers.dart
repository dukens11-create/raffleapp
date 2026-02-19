import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Test helper utilities for Flutter tests
class TestHelpers {
  /// Wraps a widget with MaterialApp for testing
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  /// Wraps a widget with MaterialApp and providers for testing
  static Widget wrapWithProvidersAndMaterialApp({
    required Widget child,
    required List<ChangeNotifierProvider> providers,
  }) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Pumps and settles a widget for testing
  static Future<void> pumpWidget(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Finds a widget by type
  static Finder findByType<T>() {
    return find.byType(T);
  }

  /// Finds a widget by key
  static Finder findByKey(Key key) {
    return find.byKey(key);
  }

  /// Finds a widget by text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Taps a widget and settles
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text into a widget
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scrolls until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder item,
    double delta, {
    Finder? scrollable,
  }) async {
    await tester.scrollUntilVisible(
      item,
      delta,
      scrollable: scrollable ?? find.byType(Scrollable).first,
    );
  }

  /// Waits for a duration
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }
}
