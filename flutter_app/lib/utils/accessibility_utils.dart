import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for improved app accessibility
class AccessibilityUtils {
  /// Minimum touch target size (44x44 dp for iOS, 48x48 dp for Android)
  static const double minTouchTargetSize = 48.0;

  /// Check if screen reader is enabled
  static bool get isScreenReaderEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Check if high contrast is enabled
  static bool get isHighContrastEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.highContrast;
  }

  /// Check if bold text is enabled
  static bool get isBoldTextEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.boldText;
  }

  /// Check if reduce motion is enabled
  static bool get isReduceMotionEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.disableAnimations;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Announce to screen reader
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Create semantic label for currency
  static String currencyLabel(double amount, {String currency = 'HTG'}) {
    return '$amount $currency';
  }

  /// Create semantic label for date
  static String dateLabel(DateTime date) {
    return '${date.year} ${_monthName(date.month)} ${date.day}';
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Create semantic label for time
  static String timeLabel(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Check if color has sufficient contrast ratio (WCAG AA)
  static bool hasSufficientContrast(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= 4.5; // WCAG AA for normal text
  }

  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color color1, Color color2) {
    final l1 = _calculateRelativeLuminance(color1);
    final l2 = _calculateRelativeLuminance(color2);
    
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _calculateRelativeLuminance(Color color) {
    final r = _linearize(color.red / 255);
    final g = _linearize(color.green / 255);
    final b = _linearize(color.blue / 255);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Get accessible text style based on user preferences
  static TextStyle getAccessibleTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    var style = baseStyle;
    
    // Apply bold text if enabled
    if (isBoldTextEnabled) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    
    // Ensure minimum font size
    final scaledSize = (style.fontSize ?? 14) * getTextScaleFactor(context);
    if (scaledSize < 12) {
      style = style.copyWith(fontSize: 12 / getTextScaleFactor(context));
    }
    
    return style;
  }

  /// Wrap widget with minimum touch target size
  static Widget ensureMinTouchTarget(Widget child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: minTouchTargetSize,
        minHeight: minTouchTargetSize,
      ),
      child: child,
    );
  }

  /// Add focus order to a list of focusable widgets
  static List<FocusNode> createFocusNodes(int count) {
    return List.generate(count, (_) => FocusNode());
  }

  /// Dispose focus nodes
  static void disposeFocusNodes(List<FocusNode> nodes) {
    for (var node in nodes) {
      node.dispose();
    }
  }

  /// Create semantic label for button
  static String buttonLabel(String text, {String? hint}) {
    return hint != null ? '$text. $hint' : text;
  }

  /// Create semantic label for progress indicator
  static String progressLabel(double progress) {
    final percentage = (progress * 100).round();
    return 'Loading $percentage percent complete';
  }

  /// Create semantic label for rating
  static String ratingLabel(double rating, {double maxRating = 5.0}) {
    return '$rating out of $maxRating stars';
  }

  /// Create semantic label for count
  static String countLabel(int count, String singular, String plural) {
    return count == 1 ? '$count $singular' : '$count $plural';
  }
}

extension AccessibilityExtensions on num {
  double get pow => this * this;
}
